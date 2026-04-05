import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hid_controller.dart';
import 'ducky_parser_it.dart';

class AppState extends ChangeNotifier {
  final HidController hidController = HidController();
  late final DuckyParserIt parser;
  
  String _script = "GUI r\nDELAY 500\nSTRING notepad.exe\nENTER\nDELAY 1000\nSTRING Ciao mondo da Proximity Shark!\nENTER";
  bool _isExecuting = false;
  int _connectionStatus = 0; // 0: Disconnected, 1: Connected
  String _bleName = "Proximity Shark";
  List<File> _savedScripts = [];

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

  // --- Setters ---
  set script(String value) {
    _script = value;
    notifyListeners();
  }

  // --- Bluetooth Settings ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bleName = prefs.getString('ble_name') ?? "Proximity Shark";
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

  void loadScriptFromFile(File file) async {
    _script = await file.readAsString();
    notifyListeners();
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
    } catch (e) {
      debugPrint("Execution error: $e");
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }
}
