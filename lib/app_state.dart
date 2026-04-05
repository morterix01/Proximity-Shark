import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hid_controller.dart';
import 'ducky_parser_it.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class AppState extends ChangeNotifier {
  final HidController hidController = HidController();
  late final DuckyParserIt parser;
  
  String _script = "GUI r\nDELAY 500\nSTRING notepad.exe\nENTER\nDELAY 1000\nSTRING Ciao mondo da Proximity Shark!\nENTER";
  bool _isExecuting = false;
  int _connectionStatus = 0; // 0: Disconnected, 1: Connected
  String _bleName = "Proximity Shark";
  List<File> _savedScripts = [];
  int _executionCount = 0;

  Future<void> fastDeploy(File file) async {
    _script = await file.readAsString();
    notifyListeners();
    await runScript();
  }
  
  // Navigation
  int _currentNavIndex = 0;

  // Bluetooth
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  AppState() {
    parser = DuckyParserIt(hidController);
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _loadScripts();
    _checkConnection();
  }

  // --- Getters ---
  String get script => _script;
  bool get isExecuting => _isExecuting;
  int get connectionStatus => _connectionStatus;
  String get bleName => _bleName;
  List<File> get savedScripts => _savedScripts;
  int get currentNavIndex => _currentNavIndex;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
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
    await hidController.setDiscoverable(300);
  }

  // --- Bluetooth Operations ---
  Future<void> startScan() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      
      _scanResults.clear();
      _isScanning = true;
      notifyListeners();

      FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      
      // Also notify the native side through HidController
      await hidController.connect(device.remoteId.str);
      
      _connectionStatus = 1;
      notifyListeners();
    } catch (e) {
      debugPrint("Connection error: $e");
    }
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _connectionStatus = 0;
      notifyListeners();
    }
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
      
      // Save to local library
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
}
