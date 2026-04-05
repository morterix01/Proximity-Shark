import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/home_screen.dart'; // We'll refactor this later
import 'screens/ble_terminal_screen.dart';
import 'screens/quick_editor_screen.dart';
import 'screens/script_manager_screen.dart';

class NavHub extends StatelessWidget {
  const NavHub({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    final List<Widget> screens = [
      const HomeScreen(), // Using this as Dashboard for now
      const BleTerminalScreen(),
      const QuickEditorScreen(),
      const ScriptManagerScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: appState.currentNavIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A12),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: appState.currentNavIndex,
          onTap: (index) => appState.currentNavIndex = index,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 1.2),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.bluetooth_searching_rounded), label: 'TERMINAL'),
            BottomNavigationBarItem(icon: Icon(Icons.code_rounded), label: 'EDITOR'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'LIBRARY'),
          ],
        ),
      ),
    );
  }
}
