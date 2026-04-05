import 'package:flutter/material.dart';
import 'hid_controller.dart';
import 'ducky_parser_it.dart';

class AppState extends ChangeNotifier {
  final HidController hidController = HidController();
  late final DuckyParserIt parser;
  
  String _script = "GUI r\nDELAY 500\nSTRING notepad.exe\nENTER\nDELAY 1000\nSTRING Ciao mondo da Android HID!\nENTER";
  bool _isExecuting = false;
  int _connectionStatus = 0; // 0: Disconnected, 1: Connected

  AppState() {
    parser = DuckyParserIt(hidController);
    _checkConnection();
  }

  String get script => _script;
  bool get isExecuting => _isExecuting;
  int get connectionStatus => _connectionStatus;

  set script(String value) {
    _script = value;
    notifyListeners();
  }

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
      print("Execution error: $e");
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }
}
