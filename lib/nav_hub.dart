import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/home_screen.dart'; // We'll refactor this later
import 'screens/ble_terminal_screen.dart';
import 'screens/quick_editor_screen.dart';
import 'screens/script_manager_screen.dart';
import 'screens/panic_screen.dart';

class NavHub extends StatefulWidget {
  const NavHub({super.key});

  @override
  State<NavHub> createState() => _NavHubState();
}

class _NavHubState extends State<NavHub> {
  StreamSubscription<String>? _navSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navSub == null) {
      final appState = Provider.of<AppState>(context, listen: false);
      _navSub = appState.navStream.listen((direction) {
        if (!mounted) return;
        int maxIndex = 4; // We have 5 tabs (0 to 4)
        int currentIndex = appState.currentNavIndex;
        
        // Handling typical Wear OS rotary inputs or swipe directions
        if (direction == "next" || direction == "right" || direction == "down") {
          appState.currentNavIndex = (currentIndex + 1) > maxIndex ? 0 : (currentIndex + 1);
        } else if (direction == "prev" || direction == "left" || direction == "up") {
          appState.currentNavIndex = (currentIndex - 1) < 0 ? maxIndex : (currentIndex - 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _navSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    final List<Widget> screens = [
      const HomeScreen(), // Using this as Dashboard for now
      const BleTerminalScreen(),
      const QuickEditorScreen(),
      const ScriptManagerScreen(),
      const PanicScreen(),
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
          // PANIC tab (index 4) uses red when selected, others use cyan
          selectedItemColor: appState.currentNavIndex == 4
              ? const Color(0xFFFF3B3B)
              : Colors.cyanAccent,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.2,
            color: appState.currentNavIndex == 4
                ? const Color(0xFFFF3B3B)
                : Colors.cyanAccent,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 1.2),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.bluetooth_searching_rounded), label: 'TERMINAL'),
            BottomNavigationBarItem(icon: Icon(Icons.code_rounded), label: 'EDITOR'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'LIBRARY'),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded, color: Colors.white24),
              label: 'PANIC',
              activeIcon: Icon(Icons.warning_rounded, color: Color(0xFFFF3B3B)),
            ),
          ],
        ),
      ),
    );
  }
}
