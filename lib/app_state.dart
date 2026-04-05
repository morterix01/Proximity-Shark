import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'hid_controller.dart';
import 'ducky_parser_it.dart';

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

  String _script = "GUI r\nDELAY 500\nSTRING notepad.exe\nENTER\nDELAY 1000\nSTRING Ciao da Proximity Shark!\nENTER";
  bool _isExecuting = false;
  int _connectionStatus = 0;
  String _bleName = "Proximity Shark";
  List<File> _savedScripts = [];
  int _executionCount = 0;

  // Navigation
  int _currentNavIndex = 0;

  // Classic BT scan
  List<ClassicDevice> _classicDevices = [];
  List<ClassicDevice> _bondedDevices = []; // List of all paired devices from Android system
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingAddress;
  String? _connectedAddress;

  AppState() {
    parser = DuckyParserIt(hidController);
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _loadScripts();
    await _requestInitialPermissions();
    
    // Applying settings and checking states
    _startDeviceStream();
    _checkConnection();
    await fetchBondedDevices();

    // Give HID Profile some time to bind if it failed initially
    // (Native side tries once on proxy connection, we retry once here)
    Future.delayed(const Duration(seconds: 2), () {
      hidController.initHidProfile(_bleName); // This also triggers a refresh in some cases
    });

    // Try to silently reconnect to the most recent device if available
    if (_bondedDevices.isNotEmpty) {
      Future.delayed(const Duration(seconds: 4), () => _autoReconnect(_bondedDevices.first));
    }
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
          _connectionStatus = 1;
          _connectedAddress = event['address'] as String?;
          _connectingAddress = null;
          _isConnecting = false;
          // Refresh bonded list so the new bond shows up
          fetchBondedDevices();
          notifyListeners();
        } else if (state == 'disconnected') {
          _connectionStatus = 0;
          _connectedAddress = null;
          _connectingAddress = null;
          _isConnecting = false;
          notifyListeners();
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
      if (address.isNotEmpty && !_classicDevices.any((d) => d.address == address)) {
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
  List<File> get savedScripts => _savedScripts;
  int get currentNavIndex => _currentNavIndex;
  List<ClassicDevice> get classicDevices => _classicDevices;
  List<ClassicDevice> get bondedDevices => _bondedDevices;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get connectingAddress => _connectingAddress;
  String? get connectedAddress => _connectedAddress;
  int get executionCount => _executionCount;

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
    notifyListeners();
  }

  Future<void> fetchBondedDevices() async {
    final bonded = await hidController.getBondedDevices();
    _bondedDevices = bonded.map((d) => ClassicDevice(
      name: d['name'] ?? 'Unknown',
      address: d['address'] ?? '',
      rssi: 0,
    )).toList();
    notifyListeners();
  }

  Future<void> _autoReconnect(ClassicDevice device) async {
    if (_connectionStatus == 1) return;
    debugPrint("Auto-reconnecting to ${device.name}...");
    await connectToDevice(device);
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
    if (_isConnecting) return; // Prevent double-tap
    
    // Explicitly disconnect if already connected to something else
    if (_connectionStatus == 1 && _connectedAddress != device.address) {
      await disconnectDevice();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isConnecting = true;
    _connectingAddress = device.address;
    notifyListeners();
    try {
      await hidController.connectHid(device.address);
    } catch (e) {
      _isConnecting = false;
      _connectingAddress = null;
      notifyListeners();
      debugPrint("Connection error: $e");
    }
  }

  Future<void> unpairDevice(ClassicDevice device) async {
    // If currently connected, disconnect first
    if (_connectedAddress == device.address) {
      await disconnectDevice();
    }
    
    final success = await hidController.unpairDevice(device.address);
    if (success) {
      await fetchBondedDevices();
    }
  }

  Future<void> disconnectDevice() async {
    await hidController.disconnectHid();
    _connectedAddress = null;
    _connectionStatus = 0;
    _isConnecting = false;
    _connectingAddress = null;
    notifyListeners();
  }

  // --- Script Library ---
  Future<void> _loadScripts() async {
    final directory = await getApplicationDocumentsDirectory();
    final scriptsDir = Directory('${directory.path}/scripts');
    if (!await scriptsDir.exists()) {
      await scriptsDir.create(recursive: true);
    }
    _savedScripts = scriptsDir.listSync().whereType<File>().toList();
    notifyListeners();
  }

  Future<void> saveCurrentScript(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/scripts/$name.txt');
    await file.writeAsString(_script);
    await _loadScripts();
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
    _script = await file.readAsString();
    notifyListeners();
  }

  Future<void> importScript() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      String name = result.files.single.name.replaceAll('.txt', '');
      _script = content;
      await saveCurrentScript(name);
      notifyListeners();
    }
  }

  // --- HID Control ---
  void _checkConnection() async {
    while (true) {
      // Only poll to detect unexpected disconnects (1→0).
      // Connection (0→1) is driven by EventChannel events from native.
      if (!_isConnecting) {
        final status = await hidController.getConnectionStatus();
        if (status != _connectionStatus) {
          _connectionStatus = status;
          if (status == 0) _connectedAddress = null;
          notifyListeners();
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> runScript() async {
    if (_isExecuting) return;
    _isExecuting = true;
    notifyListeners();

    try {
      await parser.executeScript(_script);
      _executionCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('execution_count', _executionCount);
      notifyListeners();
    } catch (e) {
      debugPrint("Execution error: $e");
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _deviceStreamSub?.cancel();
    super.dispose();
  }
}
