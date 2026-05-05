import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'hid_controller.dart';
import 'ducky_parser_it.dart';
import 'enums.dart';

class ClassicDevice {
  final String name;
  final String address;
  final int rssi;
  ClassicDevice({required this.name, required this.address, required this.rssi});
}

class AppState extends ChangeNotifier {
  final HidController hidController = HidController();
  late final DuckyParserIt parser;
  StreamSubscription? _deviceStreamSub;
  final FlutterWearOsConnectivity _wearOsConnectivity = FlutterWearOsConnectivity();
  
  // Stream per notificare la UI degli eventi di navigazione da Wear OS (es. ghiera)
  final StreamController<String> _navStreamController = StreamController<String>.broadcast();
  Stream<String> get navStream => _navStreamController.stream;

  String _script = "GUI r\nDELAY 500\nSTRING notepad.exe\nENTER\nDELAY 1000\nSTRING Ciao da Proximity Shark!\nENTER";
  bool _isExecuting = false;
  int _connectionStatus = 0;
  String _bleName = "Proximity Shark";
  List<FileSystemEntity> _savedScripts = [];
  int _executionCount = 0;
  Directory? _rootDir;
  Directory? _currentDir;

  // Navigation
  int _currentNavIndex = 0;

  // Classic BT scan
  final List<ClassicDevice> _classicDevices = [];
  List<ClassicDevice> _bondedDevices = []; // List of all paired devices from Android system
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingAddress;
  String? _connectedAddress;
  bool _isImporting = false;

  bool _isNetworkActive = false;
  String? _activeIpAddress;
  DateTime? _connectionStartTime;

  // Win11 connection stability helpers
  Timer? _connectSafetyTimer;       // cancelable safety timer for stuck HID connections
  DateTime? _lastDisconnectTime;    // track when we last disconnected for Win11 grace period
  bool _checkConnectionDebounce = false; // suppress poll interference right after events
  bool _autoReconnectActive = false;// prevent multiple reconnect loops running in parallel
  int _consecutiveFailures = 0;     // track failures to scale grace period dynamically

  KeyboardLayout _activeLayout = KeyboardLayout.pc;
  int? _panicEndTimeMillis;

  static const String taskkillScript = """GUI r
DELAY 600
STRING powershell -WindowStyle Hidden -Command "Get-Process | Where-Object { \$_.SessionId -eq (Get-Process -Id \$PID).SessionId -and \$_.Name -notmatch 'svchost|System|smss|csrss|wininit|winlogon|lsass|services|explorer' } | Stop-Process -Force"
ENTER""";

  static const String shutdownScript = """GUI r
DELAY 600
STRING powershell -WindowStyle Hidden -Command "Stop-Computer -Force"
ENTER""";

  AppState() {
    parser = DuckyParserIt(hidController);
    _init();
    _listenToWearMessages();
  }

  Future<void> _syncAppStateWithWear() async {
    try {
      final stateJson = {
        'connectedAddress': _connectedAddress,
        'connectionStatus': _connectionStatus, 
        'isConnecting': _isConnecting,
        'connectingAddress': _connectingAddress,
        'activeLayout': _activeLayout.name,
        'panicEndTimeMillis': _panicEndTimeMillis,
        'bondedDevices': _bondedDevices.map((d) => {
          'name': d.name,
          'address': d.address
        }).toList()
      };
      
      await _wearOsConnectivity.syncData(
        path: "/shark_state",
        data: {"state_json": jsonEncode(stateJson)},
      );
    } catch (e) {
      debugPrint("Failed to sync app state with Wear OS: $e");
    }
  }

  Future<void> _init() async {
    await _wearOsConnectivity.configureWearableAPI();
    await _loadSettings();
    await _loadScripts();
    await _syncLibraryWithWear();
    await _requestInitialPermissions();
    
    // Applying settings and checking states
    _startDeviceStream();
    _checkConnection();
    _startNetworkMonitor();
    await fetchBondedDevices();

    // Give HID Profile some time to bind if it failed initially
    // (Native side tries once on proxy connection, we retry once here)
    Future.delayed(const Duration(seconds: 2), () {
      hidController.initHidProfile(_bleName);
    });

    // Start the persistent auto-reconnect engine
    _ensureAutoReconnectRunning();
  }

  Future<void> _requestInitialPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
        Permission.notification,
      ].request();
    }
  }

  void _startDeviceStream() {
    _deviceStreamSub = hidController.deviceStream.listen((event) {
      // Handle connection state events from native HID callbacks
      if (event.containsKey('connection_state')) {
        final state = event['connection_state'] as String;
        if (state == 'connected') {
          // Cancel any pending safety timer — connection succeeded
          _connectSafetyTimer?.cancel();
          _connectSafetyTimer = null;
          _connectionStatus = 1;
          _connectedAddress = event['address'] as String?;
          _connectingAddress = null;
          _isConnecting = false;
          _connectionStartTime = DateTime.now();
          // Suppress _checkConnection poll for 2s to avoid event/poll race
          _checkConnectionDebounce = true;
          Future.delayed(const Duration(seconds: 2), () => _checkConnectionDebounce = false);
          // Save the last successfully connected device so auto-reconnect targets the right PC
          if (_connectedAddress != null) {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('last_connected_mac', _connectedAddress!);
            });
          }
          // Refresh bonded list so the new bond shows up
          fetchBondedDevices();
          notifyListeners();
          _syncAppStateWithWear();
        } else if (state == 'disconnected') {
          // Cancel safety timer if we already got a native disconnect
          _connectSafetyTimer?.cancel();
          _connectSafetyTimer = null;
          _connectionStatus = 0;
          _connectedAddress = null;
          _connectingAddress = null;
          _isConnecting = false;
          _connectionStartTime = null;
          _lastDisconnectTime = DateTime.now(); // Record for Win11 grace period
          _consecutiveFailures = 0; // reset on clean disconnect
          // Suppress poll for 3s after disconnect to avoid double-clear
          _checkConnectionDebounce = true;
          Future.delayed(const Duration(seconds: 3), () => _checkConnectionDebounce = false);
          notifyListeners();
          _syncAppStateWithWear();
          // Re-trigger the reconnect loop if it's not already running
          _ensureAutoReconnectRunning();
        }
        return;
      }
      // Handle scan_complete
      if (event.containsKey('scan_complete')) {
        _isScanning = false;
        notifyListeners();
        return;
      }
      // Handle discovered device
      final name = event['name'] as String? ?? 'Unknown';
      final address = event['address'] as String? ?? '';
      final rssi = int.tryParse(event['rssi']?.toString() ?? '0') ?? 0;
      if (address.isNotEmpty && 
          !_classicDevices.any((d) => d.address == address) &&
          name != 'Unknown' && 
          name.isNotEmpty && 
          name.toLowerCase() != 'unknown device') {
        _classicDevices.add(ClassicDevice(name: name, address: address, rssi: rssi));
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Device stream error: $e");
      _isScanning = false;
      _isConnecting = false;
      notifyListeners();
    });
  }

  // --- Getters ---
  String get script => _script;
  bool get isExecuting => _isExecuting;
  int get connectionStatus => _connectionStatus;
  String get bleName => _bleName;
  List<FileSystemEntity> get savedScripts => _savedScripts;
  Directory? get currentDirectory => _currentDir;
  bool get isRootDirectory => _currentDir?.path == _rootDir?.path;
  int get currentNavIndex => _currentNavIndex;
  List<ClassicDevice> get classicDevices => _classicDevices;
  List<ClassicDevice> get bondedDevices => _bondedDevices;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get connectingAddress => _connectingAddress;
  String? get connectedAddress => _connectedAddress;
  int get executionCount => _executionCount;
  bool get isImporting => _isImporting;
  bool get isNetworkActive => _isNetworkActive;
  String? get activeIpAddress => _activeIpAddress;
  DateTime? get connectionStartTime => _connectionStartTime;
  KeyboardLayout get activeLayout => _activeLayout;
  int? get panicEndTimeMillis => _panicEndTimeMillis;

  // --- Setters ---
  set script(String value) {
    _script = value;
    notifyListeners();
  }

  set currentNavIndex(int val) {
    _currentNavIndex = val;
    notifyListeners();
  }

  // --- Bluetooth Settings ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bleName = prefs.getString('ble_name') ?? "Proximity Shark";
    _executionCount = prefs.getInt('execution_count') ?? 0;
    
    final layoutIndex = prefs.getInt('keyboard_layout') ?? 0;
    _activeLayout = KeyboardLayout.values[layoutIndex];
    
    _panicEndTimeMillis = prefs.getInt('panic_end_time');
    if (_panicEndTimeMillis != null) {
      if (DateTime.now().millisecondsSinceEpoch > _panicEndTimeMillis!) {
        _panicEndTimeMillis = null;
      }
    }
    
    notifyListeners();
  }

  void triggerPanicTimer() {
    _panicEndTimeMillis = DateTime.now().millisecondsSinceEpoch + 600000;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('panic_end_time', _panicEndTimeMillis!);
    });
    notifyListeners();
    _syncAppStateWithWear();
  }

  void clearPanicTimer() {
    _panicEndTimeMillis = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('panic_end_time');
    });
    notifyListeners();
    _syncAppStateWithWear();
  }

  Future<void> updateKeyboardLayout(KeyboardLayout layout) async {
    _activeLayout = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keyboard_layout', layout.index);
    notifyListeners();
    _syncAppStateWithWear();
  }

  Future<void> fetchBondedDevices() async {
    final bonded = await hidController.getBondedDevices();
    _bondedDevices = bonded
      .where((d) => d['name'] != null && d['name'].toString().isNotEmpty && d['name'].toString().toLowerCase() != 'unknown device' && d['name'].toString().toLowerCase() != 'unknown')
      .map((d) => ClassicDevice(
        name: d['name'] ?? 'Unknown',
        address: d['address'] ?? '',
        rssi: 0,
      )).toList();
    notifyListeners();
    _syncAppStateWithWear();
  }

  // ─── Auto-Reconnect Engine ───────────────────────────────────────────────
  // Ensures only one reconnect loop is ever running at a time.
  void _ensureAutoReconnectRunning() {
    if (_autoReconnectActive) return;
    _autoReconnectActive = true;
    _startAutoReconnectLoop();
  }

  Future<void> _startAutoReconnectLoop() async {
    // Brief initial pause to let the HID proxy and Android BT stack settle.
    await Future.delayed(const Duration(seconds: 4));

    final prefs = await SharedPreferences.getInstance();
    final lastMac = prefs.getString('last_connected_mac');

    if (lastMac == null) {
      _autoReconnectActive = false;
      return; // No connection history — nothing to reconnect to
    }

    // Win11 base grace period between attempts.
    // Never go below 12s or Win11 silently rejects the HID profile.
    int retrySeconds = 12;
    int attempt = 0;

    while (_connectionStatus == 0) {
      if (_bondedDevices.isEmpty) break;

      // Don't try while a manual scan is in progress
      if (_isScanning) {
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      // Don't double-start if something else is already connecting
      if (_isConnecting) {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      ClassicDevice? target;
      try {
        target = _bondedDevices.firstWhere((d) => d.address == lastMac);
      } catch (_) {
        // Target no longer in bonded list — abort
        break;
      }

      attempt++;
      debugPrint("[Win11] Reconnect attempt #$attempt to $lastMac (wait: ${retrySeconds}s)");

      // Re-initialize the HID profile before every attempt.
      // Win11 often requires a fresh profile registration after a drop.
      await hidController.initHidProfile(_bleName);
      await Future.delayed(const Duration(milliseconds: 800));

      await connectToDevice(target);

      // Wait for the connection to settle
      await Future.delayed(Duration(seconds: retrySeconds));

      if (_connectionStatus == 1) {
        debugPrint("[Win11] Reconnect successful on attempt #$attempt!");
        _consecutiveFailures = 0;
        // Don't exit the loop — keep it ready to re-trigger on next disconnect.
        // The while condition (_connectionStatus == 0) will block here until next drop.
        // We wait in a tight loop until we drop again.
        while (_connectionStatus == 1) {
          await Future.delayed(const Duration(seconds: 5));
        }
        // We just dropped — reset backoff and immediately loop again
        retrySeconds = 12;
        attempt = 0;
        continue;
      }

      // Connection failed — increase failure counter and backoff with jitter
      _consecutiveFailures++;

      // After 3+ consecutive failures, re-register HID identity completely
      if (_consecutiveFailures >= 3) {
        debugPrint("[Win11] $_consecutiveFailures failures — forcing HID identity reset");
        await resetHidIdentity();
        await Future.delayed(const Duration(seconds: 3));
      }

      // Exponential backoff: 12 → 20 → 35 → 60 → MAX 90s
      // Add random jitter (0-5s) to avoid thundering-herd on rapid app restarts
      final jitter = (DateTime.now().millisecond % 5000);
      retrySeconds = ((retrySeconds * 1.7).round() + (jitter ~/ 1000)).clamp(12, 90);
    }

    _autoReconnectActive = false;
  }

  Future<void> updateBleName(String newName) async {
    final success = await hidController.initHidProfile(newName);
    if (success) {
      _bleName = newName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ble_name', newName);
      notifyListeners();
    }
  }

  Future<void> toggleDiscoverability() async {
    // Stop any active scan first — startDiscovery cancels discoverability on Android
    if (_isScanning) await stopScan();
    if (await Permission.bluetoothAdvertise.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      await hidController.setDiscoverable(300);
    }
  }

  // --- Classic BT Scan ---
  Future<void> startScan() async {
    if (_isScanning) return;
    _classicDevices.clear();
    _isScanning = true;
    notifyListeners();
    await hidController.startClassicScan();
  }

  Future<void> stopScan() async {
    await hidController.stopClassicScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(ClassicDevice device) async {
    if (_isConnecting && _connectingAddress == device.address) return; // Prevent double-tap

    // Cancel any pending safety timer before starting a new attempt
    _connectSafetyTimer?.cancel();
    _connectSafetyTimer = null;

    // Explicitly disconnect if already connected to something else
    if (_connectionStatus == 1 && _connectedAddress != device.address) {
      await disconnectDevice();
      await Future.delayed(const Duration(milliseconds: 2000));
    }

    // Always ensure HID profile is fresh before a manual connection attempt
    // to solve the "half-second linking" bug (Win11 profile sync issue)
    await hidController.initHidProfile(_bleName);
    await Future.delayed(const Duration(milliseconds: 800));

    // Windows 11 grace period: the HID stack needs time after a disconnect
    // before it will accept a new connection on the same profile slot.
    // Base: 1500ms. Scaled up by consecutive failures (max 4s).
    if (_lastDisconnectTime != null) {
      final graceMs = (1500 + (_consecutiveFailures * 500)).clamp(1500, 4000);
      final msSinceDisconnect = DateTime.now().difference(_lastDisconnectTime!).inMilliseconds;
      if (msSinceDisconnect < graceMs) {
        await Future.delayed(Duration(milliseconds: graceMs - msSinceDisconnect));
      }
    }

    _isConnecting = true;
    _connectingAddress = device.address;
    notifyListeners();
    _syncAppStateWithWear();
    try {
      final success = await hidController.connectHid(device.address);

      if (!success) {
        _consecutiveFailures++;
        _isConnecting = false;
        _connectingAddress = null;
        _connectionStatus = 0;
        notifyListeners();
        _syncAppStateWithWear();
        return;
      }

      // Cancelable safety timeout: if Android BT gets stuck, clean up UI
      // Win11 connections can take up to 15s legitimately; 25s is safe upper bound
      _connectSafetyTimer = Timer(const Duration(seconds: 25), () {
        if (_isConnecting) {
          _isConnecting = false;
          _connectingAddress = null;
          _connectionStatus = 0;
          _consecutiveFailures++;
          notifyListeners();
          _syncAppStateWithWear();
          debugPrint("[Win11] Safety timer fired — HID connection timed out after 25s");
        }
      });
    } catch (e) {
      _connectSafetyTimer?.cancel();
      _connectSafetyTimer = null;
      _consecutiveFailures++;
      _isConnecting = false;
      _connectingAddress = null;
      _connectionStatus = 0;
      notifyListeners();
      _syncAppStateWithWear();
    }
  }

  Future<void> unpairDevice(ClassicDevice device) async {
    // If currently connected, disconnect first
    if (_connectedAddress == device.address || _connectingAddress == device.address) {
      await disconnectDevice();
    }
    
    // Eagerly remove from UI to prevent lag perception
    _bondedDevices.removeWhere((d) => d.address == device.address);
    notifyListeners();

    final success = await hidController.unpairDevice(device.address);
    if (success) {
      // Delay fetch to let Android process the removeBond async task natively
      await Future.delayed(const Duration(milliseconds: 1500));
      await fetchBondedDevices();
    } else {
      await fetchBondedDevices();
    }
  }

  Future<void> disconnectDevice() async {
    _connectSafetyTimer?.cancel();
    _connectSafetyTimer = null;
    await hidController.disconnectHid();
    _connectedAddress = null;
    _connectionStatus = 0;
    _isConnecting = false;
    _connectingAddress = null;
    _connectionStartTime = null;
    _lastDisconnectTime = DateTime.now();
    notifyListeners();
    _syncAppStateWithWear();
  }

  Future<void> resetHidIdentity() async {
    // Unregister and re-register HID Profile to force a clean state
    await hidController.initHidProfile(_bleName);
    // Short delay to let Android reset
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  // --- Script Library ---
  Future<void> _loadScripts() async {
    if (_rootDir == null) {
      final directory = await getApplicationDocumentsDirectory();
      _rootDir = Directory('${directory.path}/scripts');
      if (!await _rootDir!.exists()) {
        await _rootDir!.create(recursive: true);
      }
      _currentDir = _rootDir;
    }
    _savedScripts = _currentDir!.listSync().toList();
    // Sort so folders appear first
    _savedScripts.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });
    notifyListeners();
    _syncLibraryWithWear(); // Sync on every load/change
  }

  Future<void> _syncLibraryWithWear() async {
    if (_rootDir == null) return;
    try {
      final structure = _getFolderStructure(_rootDir!);
      final jsonStr = jsonEncode(structure);
      
      // Compress to avoid Wear OS DataLayer 100KB limits on large structures
      final compressedBytes = gzip.encode(utf8.encode(jsonStr));
      final jsonBase64 = base64Encode(compressedBytes);
      
      await _wearOsConnectivity.syncData(
        path: "/library",
        data: {
          "library_json_b64": jsonBase64,
        },
      );
      debugPrint("Library synced with Wear OS");
    } catch (e) {
      debugPrint("Failed to sync library with Wear OS: $e");
    }
  }

  Map<String, dynamic> _getFolderStructure(Directory dir) {
    final Map<String, dynamic> structure = {
      'name': dir.path.split(Platform.pathSeparator).last,
      'isDir': true,
      'path': dir.path,
      'children': [],
    };
    if (structure['name'] == 'scripts') structure['name'] = 'Libreria';

    try {
      final List<FileSystemEntity> entities = dir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          structure['children'].add(_getFolderStructure(entity));
        } else if (entity is File && (entity.path.endsWith('.txt') || entity.path.endsWith('.ducky'))) {
          structure['children'].add({
            'name': entity.path.split(Platform.pathSeparator).last,
            'isDir': false,
            'path': entity.path,
          });
        }
      }
    } catch (e) {
      debugPrint("Error walking directory: $e");
    }
    
    // Sort so folders appear first
    (structure['children'] as List).sort((a, b) {
       if (a['isDir'] && !b['isDir']) return -1;
       if (!a['isDir'] && b['isDir']) return 1;
       return (a['name'] as String).compareTo(b['name'] as String);
    });

    return structure;
  }

  Future<void> navigateIntoFolder(Directory dir) async {
    if (await dir.exists()) {
      _currentDir = dir;
      await _loadScripts();
    }
  }

  Future<void> navigateUp() async {
    if (_currentDir != null && _currentDir!.path != _rootDir!.path) {
      _currentDir = _currentDir!.parent;
      await _loadScripts();
    }
  }

  Future<void> createFolder(String name) async {
    if (_currentDir != null && name.isNotEmpty) {
      final dir = Directory('${_currentDir!.path}/$name');
      if (!await dir.exists()) {
        await dir.create();
        await _loadScripts();
      }
    }
  }

  Future<void> saveCurrentScript(String name) async {
    if (_currentDir == null) return;
    final file = File('${_currentDir!.path}/$name.txt');
    await file.writeAsString(_script);
    await _loadScripts();
  }

  /// Salva lo script corrente in una [targetDir] specifica con il [name] dato.
  Future<void> saveScriptTo(String name, Directory targetDir) async {
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final file = File('${targetDir.path}/$name.txt');
    await file.writeAsString(_script);
    await _loadScripts();
  }

  /// Restituisce tutte le cartelle disponibili nella libreria (root + sottocartelle dirette).
  Future<List<Directory>> getLibraryFolders() async {
    if (_rootDir == null) return [];
    final entities = _rootDir!.listSync();
    final folders = <Directory>[_rootDir!];
    for (final e in entities) {
      if (e is Directory) folders.add(e);
    }
    return folders;
  }

  Future<void> deleteScript(File file) async {
    if (await file.exists()) {
      await file.delete();
      await _loadScripts();
    }
  }

  Future<void> deployScript(File file) async {
    _script = await file.readAsString();
    notifyListeners();
    await runScript();
  }

  void loadScriptFromFile(File file) async {
    if (await file.exists()) {
      _script = await file.readAsString();
      notifyListeners();
    }
  }

  Future<void> importScript() async {
    if (_isImporting) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      allowMultiple: true,
    );

    if (result != null && _currentDir != null) {
      _isImporting = true;
      notifyListeners();
      
      try {
        for (var pFile in result.files) {
          if (pFile.path == null) continue;
          final sourceFile = File(pFile.path!);
          final destFile = File('${_currentDir!.path}/${pFile.name}');
          
          // Skip if already exists or copy
          if (!await destFile.exists()) {
            await sourceFile.copy(destFile.path);
          }
        }
        await _loadScripts();
      } finally {
        _isImporting = false;
        notifyListeners();
      }
    }
  }

  Future<void> importFolder() async {
    if (_isImporting || _currentDir == null) return;
    
    // Request permissions first
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isDenied &&
          await Permission.storage.request().isDenied) {
        debugPrint("Storage permissions denied");
        return;
      }
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    _isImporting = true;
    notifyListeners();

    try {
      final sourceDir = Directory(selectedDirectory);
      
      // Better folder name extraction (handle trailing slashes)
      String path = sourceDir.path;
      if (path.endsWith(Platform.pathSeparator)) {
        path = path.substring(0, path.length - 1);
      }
      final folderName = path.split(Platform.pathSeparator).last;
      
      if (folderName.isEmpty) throw Exception("Could not determine folder name");

      final destDir = Directory('${_currentDir!.path}/$folderName');

      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await _copyDirectory(sourceDir, destDir);
      await _loadScripts();
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    try {
      if (!await source.exists()) return;
      
      await for (var entity in source.list(recursive: false)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        
        if (entity is Directory) {
          final newDirectory = Directory('${destination.path}/$name');
          if (!await newDirectory.exists()) {
            await newDirectory.create();
          }
          await _copyDirectory(entity, newDirectory);
        } else if (entity is File && (entity.path.endsWith('.txt') || entity.path.endsWith('.ducky'))) {
          // Support both .txt and .ducky if relevant
          final newFile = File('${destination.path}/$name');
          if (!await newFile.exists()) {
            await entity.copy(newFile.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Error copying directory ${source.path}: $e");
      // Continue with other files if one fails
    }
  }

  // --- HID Connection Poll ---
  void _checkConnection() async {
    while (true) {
      // Only poll to detect unexpected disconnects (1→0).
      // Connection (0→1) is driven by EventChannel events from native.
      // Debounce suppresses interference right after a native event.
      if (!_isConnecting && !_checkConnectionDebounce) {
        final status = await hidController.getConnectionStatus();
        if (status != _connectionStatus) {
          _connectionStatus = status;
          if (status == 0) {
            _connectedAddress = null;
            _connectionStartTime = null;
            _lastDisconnectTime = DateTime.now();
            notifyListeners();
            _syncAppStateWithWear();
            // Poll detected a drop — ensure the reconnect engine is running
            _ensureAutoReconnectRunning();
          } else {
            notifyListeners();
          }
        }
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  void _listenToWearMessages() {
    _wearOsConnectivity.messageReceived().listen((message) async {
      if (message.path == "/run_script") {
        final String filePath = utf8.decode(message.data);
        final file = File(filePath);
        if (await file.exists()) {
          _script = await file.readAsString();
          notifyListeners();
          runScript();
        }
      } else if (message.path == "/connect_device") {
        final String address = utf8.decode(message.data);
        try {
          final target = _bondedDevices.firstWhere((d) => d.address == address);
          connectToDevice(target);
        } catch (e) {
          debugPrint("Failed to connect from watch: device $address not found.");
        }
      } else if (message.path == "/set_layout") {
        final String layoutName = utf8.decode(message.data);
        try {
          final layout = KeyboardLayout.values.firstWhere((e) => e.name == layoutName);
          updateKeyboardLayout(layout);
        } catch (e) {
          debugPrint("Failed to update layout from watch: $layoutName not found.");
        }
      } else if (message.path == "/panic") {
        // Wear OS panic button: send Ctrl+Alt+B (modifier 0x05 = LEFT_CTRL|LEFT_ALT, keycode 0x05 = 'b')
        if (_connectionStatus == 1) {
          await hidController.sendKey(0x05, 0x05);
          triggerPanicTimer();
        }
      } else if (message.path == "/taskkill") {
        // Wear OS taskkill button
        if (_connectionStatus == 1) {
          await runQuickScript(taskkillScript);
        }
      } else if (message.path == "/shutdown") {
        // Wear OS shutdown button
        if (_connectionStatus == 1) {
          await runQuickScript(shutdownScript);
        }
      } else if (message.path == "/nav") {
        // Messaggi di navigazione (es. dalla ghiera)
        final String direction = utf8.decode(message.data);
        _navStreamController.add(direction);
      }
    });
  }

  // --- Stealth & Privacy Monitor ---
  void _startNetworkMonitor() async {
    while (true) {
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.any,
        );

        bool foundActive = false;
        String? firstIp;

        for (var interface in interfaces) {
          if (interface.addresses.isNotEmpty) {
            foundActive = true;
            firstIp = interface.addresses.first.address;
            break;
          }
        }

        if (_isNetworkActive != foundActive || _activeIpAddress != firstIp) {
          _isNetworkActive = foundActive;
          _activeIpAddress = firstIp;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Network monitor error: $e");
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _sendWearProgress(String progressStr) async {
    try {
      final devices = await _wearOsConnectivity.getConnectedDevices();
      final pb = utf8.encode(progressStr);
      for (final dev in devices) {
        await _wearOsConnectivity.sendMessage(pb, deviceId: dev.id, path: "/progress");
      }
    } catch (e) {
      debugPrint("Wear Progress Error: $e");
    }
  }

  Future<void> runScript() async {
    if (_isExecuting) return;
    _isExecuting = true;
    notifyListeners();

    try {
      await parser.executeScript(
        _script,
        layout: _activeLayout,
        onProgress: (progress) {
          _sendWearProgress(progress.toString());
        },
      );
      _executionCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('execution_count', _executionCount);
      
      // Notify finished
      _sendWearProgress("1.0");

      notifyListeners();
    } catch (e) {
      debugPrint("Execution error: $e");
      _sendWearProgress("-1.0");
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  Future<void> runQuickScript(String customScript) async {
    // Esegue uno script senza modificare _script e senza inviare progressi a Wear OS
    try {
      await parser.executeScript(
        customScript,
        layout: _activeLayout,
      );
    } catch (e) {
      debugPrint("Quick Execution error: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _connectSafetyTimer?.cancel();
    _deviceStreamSub?.cancel();
    _navStreamController.close();
    super.dispose();
  }
}
