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
  bool _isScanning = false;
  String? _connectedAddress;

  AppState() {
    parser = DuckyParserIt(hidController);
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _loadScripts();
    await _requestInitialPermissions();
    _startDeviceStream();
    _checkConnection();
  }

  Future<void> _requestInitialPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
    }
  }

  void _startDeviceStream() {
    _deviceStreamSub = hidController.deviceStream.listen((event) {
      if (event.containsKey('scan_complete')) {
        _isScanning = false;
        notifyListeners();
        return;
      }
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
  bool get isScanning => _isScanning;
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

  Future<void> updateBleName(String newName) async {
    final success = await hidController.setDeviceName(newName);
    if (success) {
      _bleName = newName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ble_name', newName);
      notifyListeners();
    }
  }

  Future<void> toggleDiscoverability() async {
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
    try {
      await hidController.connectHid(device.address);
      _connectedAddress = device.address;
      _connectionStatus = 1;
      notifyListeners();
    } catch (e) {
      debugPrint("Connection error: $e");
    }
  }

  Future<void> disconnectDevice() async {
    _connectedAddress = null;
    _connectionStatus = 0;
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
      int status = await hidController.getConnectionStatus();
      if (status != _connectionStatus) {
        _connectionStatus = status;
        notifyListeners();
      }
      await Future.delayed(const Duration(seconds: 2));
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
