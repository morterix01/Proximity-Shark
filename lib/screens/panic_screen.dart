import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _killPulseController;
  late PageController _pageController;

  bool _isPressing = false;
  bool _isFiring = false;
  bool _isKillPressing = false;
  bool _isKillingFiring = false;
  bool _isShutdownPressing = false;
  bool _isShutdownFiring = false;
  Timer? _uiRefreshTimer;

  String _statusMessage = "SISTEMA PRONTO";
  Color _statusColor = const Color(0xFFFF3B3B);

  String _killStatusMessage = "PRONTO";
  Color _killStatusColor = Colors.deepOrangeAccent;

  String _shutdownStatusMessage = "PRONTO";
  Color _shutdownStatusColor = Colors.redAccent;

  int _currentPage = 0;

  // ─── HID keycodes ────────────────────────────────────────────────────────
  static const int _modCtrlAlt = 0x05; // LEFT_CTRL (0x01) | LEFT_ALT (0x04)
  static const int _keyB = 0x05;       // USB HID keycode for 'b'

  // ─── Taskkill script moved to AppState ───────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Infinite loop trick: start at a large index that is a multiple of 3
    _pageController = PageController(initialPage: 3000);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _killPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _killPulseController.dispose();
    _pageController.dispose();
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  // ─── Panic trigger ────────────────────────────────────────────────────────
  Future<void> _triggerPanic() async {
    if (_isFiring) return;
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.connectionStatus == 0) {
      _showNoTargetSnack();
      return;
    }

    setState(() {
      _isFiring = true;
      _statusMessage = "INVIO CTRL+ALT+B...";
      _statusColor = Colors.amberAccent;
    });

    try {
      final success = await appState.hidController.sendKey(_modCtrlAlt, _keyB);
      if (success) appState.triggerPanicTimer();
      if (mounted) {
        setState(() {
          _statusMessage = success ? "✓ SEGNALE INVIATO" : "✗ INVIO FALLITO";
          _statusColor = success ? Colors.greenAccent : Colors.redAccent;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = "SISTEMA PRONTO";
              _statusColor = const Color(0xFFFF3B3B);
              _isFiring = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "✗ ERRORE: $e";
          _statusColor = Colors.redAccent;
          _isFiring = false;
        });
      }
    }
  }

  // ─── Taskkill trigger ─────────────────────────────────────────────────────
  Future<void> _triggerTaskkill() async {
    if (_isKillingFiring) return;
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.connectionStatus == 0) {
      _showNoTargetSnack();
      return;
    }

    setState(() {
      _isKillingFiring = true;
      _killStatusMessage = "ESECUZIONE TASKKILL...";
      _killStatusColor = Colors.amberAccent;
    });

    try {
      await appState.runQuickScript(AppState.taskkillScript);
      if (mounted) {
        setState(() {
          _killStatusMessage = "✓ SCRIPT INVIATO";
          _killStatusColor = Colors.greenAccent;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _killStatusMessage = "PRONTO";
              _killStatusColor = Colors.deepOrangeAccent;
              _isKillingFiring = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _killStatusMessage = "✗ ERRORE: $e";
          _killStatusColor = Colors.redAccent;
          _isKillingFiring = false;
        });
      }
    }
  }

  void _showNoTargetSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Nessun target connesso — connetti prima il PC via HID Terminal'),
        backgroundColor: Color(0xFF1A1A2E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isConnected = appState.connectionStatus == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Stack(
        children: [
          // Radar background always visible
          _buildRadarBackground(),
          // PageView fills the body
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (i) => setState(() => _currentPage = i % 3),
            itemBuilder: (context, index) {
              final page = index % 3;
              if (page == 0) return _buildPanicPage(isConnected, appState);
              if (page == 1) return _buildTaskkillPage(isConnected);
              return _buildShutdownPage(isConnected);
            },
          ),
          // Page indicator on the right edge
          _buildPageIndicator(),
        ],
      ),
    );
  }

  // ─── Page 0: Panic ────────────────────────────────────────────────────────
  Widget _buildPanicPage(bool isConnected, AppState appState) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(isConnected,
              title: "PANIC BUTTON",
              subtitle: "CTRL + ALT + B  //  TRASMISSIONE HID DIRETTA",
              subtitleColor: const Color(0xFFFF3B3B),
            ),
            const SizedBox(height: 32),
            _buildPanicButton(),
            _buildPanicTimer(appState),
            const SizedBox(height: 24),
            _buildStatusCard(
              icon: _isFiring ? Icons.bolt_rounded : Icons.shield_rounded,
              label: "STATO SISTEMA",
              message: _statusMessage,
              color: _statusColor,
              loading: _isFiring,
            ),
            const SizedBox(height: 16),
            _buildSwipeHint(down: true, label: "SLIDE GIÙ → TASKKILL"),
          ],
        ),
      ),
    );
  }

  // ─── Page 1: Taskkill ─────────────────────────────────────────────────────
  Widget _buildTaskkillPage(bool isConnected) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSwipeHint(down: false, label: "SLIDE SU → PANIC"),
            const SizedBox(height: 16),
            _buildHeader(isConnected,
              title: "TASKKILL",
              subtitle: "TERMINA TUTTI I PROCESSI UTENTE  //  POWERSHELL STEALTH",
              subtitleColor: Colors.deepOrangeAccent,
            ),
            const SizedBox(height: 28),
            _buildKillButton(),
            const SizedBox(height: 24),
            _buildStatusCard(
              icon: _isKillingFiring ? Icons.timer_rounded : Icons.terminal_rounded,
              label: "STATO TASKKILL",
              message: _killStatusMessage,
              color: _killStatusColor,
              loading: _isKillingFiring,
            ),
            const SizedBox(height: 16),
            _buildSwipeHint(down: true, label: "SLIDE GIÙ → SHUTDOWN"),
          ],
        ),
      ),
    );
  }

  // ─── Page 2: Shutdown ─────────────────────────────────────────────────────
  Widget _buildShutdownPage(bool isConnected) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSwipeHint(down: false, label: "SLIDE SU → TASKKILL"),
            const SizedBox(height: 16),
            _buildHeader(isConnected,
              title: "SHUTDOWN",
              subtitle: "SPEGNIMENTO IMMEDIATO DEL TARGET  //  CMD FORCED",
              subtitleColor: Colors.redAccent,
            ),
            const SizedBox(height: 28),
            _buildShutdownButton(),
            const SizedBox(height: 24),
            _buildStatusCard(
              icon: _isShutdownFiring ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
              label: "STATO SHUTDOWN",
              message: _shutdownStatusMessage,
              color: _shutdownStatusColor,
              loading: _isShutdownFiring,
            ),
            const SizedBox(height: 16),
            _buildSwipeHint(down: true, label: "SLIDE GIÙ → PANIC"),
          ],
        ),
      ),
    );
  }
  // ─── Shared Header ────────────────────────────────────────────────────────
  Widget _buildHeader(bool isConnected, {
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.greenAccent : Colors.redAccent,
                boxShadow: [BoxShadow(
                  color: (isConnected ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.6),
                  blurRadius: 8,
                )],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms),
            const SizedBox(width: 10),
            Text(
              isConnected ? "TARGET CONNESSO" : "TARGET OFFLINE",
              style: TextStyle(
                color: isConnected ? Colors.greenAccent : Colors.redAccent,
                fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white, fontSize: 28,
            fontWeight: FontWeight.w900, letterSpacing: 4.0,
          ),
        ).animate().fadeIn().slideY(begin: -0.3),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtitleColor.withValues(alpha: 0.7),
            fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5,
          ),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  // ─── Swipe Hint Arrow ─────────────────────────────────────────────────────
  Widget _buildSwipeHint({required bool down, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          down ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
          color: Colors.white24,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24, fontSize: 9,
            fontWeight: FontWeight.bold, letterSpacing: 1.5,
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .fadeIn(duration: 800.ms)
     .then()
     .fadeOut(duration: 800.ms);
  }

  // ─── Page Indicator (right edge dots) ────────────────────────────────────
  Widget _buildPageIndicator() {
    return Positioned(
      right: 12,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final isActive = i == _currentPage;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: isActive ? 8 : 5,
                height: isActive ? 24 : 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? (i == 0 ? const Color(0xFFFF3B3B) : (i == 1 ? Colors.deepOrangeAccent : Colors.redAccent))
                      : Colors.white24,
                  boxShadow: isActive ? [BoxShadow(
                    color: (i == 0 ? const Color(0xFFFF3B3B) : (i == 1 ? Colors.deepOrangeAccent : Colors.redAccent))
                        .withValues(alpha: 0.5),
                    blurRadius: 8,
                  )] : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Panic Circle Button ──────────────────────────────────────────────────
  Widget _buildPanicButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressing = true),
        onTapUp: (_) { setState(() => _isPressing = false); _triggerPanic(); },
        onTapCancel: () => setState(() => _isPressing = false),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final pulseScale = _isFiring ? 1.0 : 1.0 + (_pulseController.value * 0.04);
            final glow = _isFiring ? 0.0 : _pulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 200 * pulseScale + 30,
                  height: 200 * pulseScale + 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.04 * glow),
                  ),
                ),
                AnimatedScale(
                  scale: _isPressing ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isFiring
                          ? [Colors.amberAccent.withValues(alpha: 0.3), Colors.transparent]
                          : [const Color(0xFFFF3B3B).withValues(alpha: 0.25), Colors.transparent],
                      ),
                      border: Border.all(
                        color: _isFiring
                          ? Colors.amberAccent.withValues(alpha: 0.7)
                          : const Color(0xFFFF3B3B).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [BoxShadow(
                        color: (_isFiring ? Colors.amberAccent : const Color(0xFFFF3B3B))
                            .withValues(alpha: 0.3 + glow * 0.2),
                        blurRadius: 40, spreadRadius: 5,
                      )],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isFiring ? Icons.send_rounded : Icons.warning_amber_rounded,
                          color: _isFiring ? Colors.amberAccent : const Color(0xFFFF3B3B),
                          size: 46,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isFiring ? "INVIO..." : "PANICO",
                          style: TextStyle(
                            color: _isFiring ? Colors.amberAccent : Colors.white,
                            fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "CTRL+ALT+B",
                          style: TextStyle(
                            color: (_isFiring ? Colors.amberAccent : const Color(0xFFFF3B3B))
                                .withValues(alpha: 0.8),
                            fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  // ─── Taskkill Circle Button ───────────────────────────────────────────────
  Widget _buildKillButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isKillPressing = true),
        onTapUp: (_) { setState(() => _isKillPressing = false); _triggerTaskkill(); },
        onTapCancel: () => setState(() => _isKillPressing = false),
        child: AnimatedBuilder(
          animation: _killPulseController,
          builder: (context, _) {
            final glow = _isKillingFiring ? 0.0 : _killPulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer danger ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 200 + 30,
                  height: 200 + 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.05 * glow),
                  ),
                ),
                AnimatedScale(
                  scale: _isKillPressing ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isKillingFiring
                          ? [Colors.amberAccent.withValues(alpha: 0.25), Colors.transparent]
                          : [Colors.deepOrangeAccent.withValues(alpha: 0.20), Colors.transparent],
                      ),
                      border: Border.all(
                        color: _isKillingFiring
                          ? Colors.amberAccent.withValues(alpha: 0.6)
                          : Colors.deepOrangeAccent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [BoxShadow(
                        color: (_isKillingFiring ? Colors.amberAccent : Colors.deepOrangeAccent)
                            .withValues(alpha: 0.3 + glow * 0.2),
                        blurRadius: 40, spreadRadius: 5,
                      )],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isKillingFiring ? Icons.hourglass_top_rounded : Icons.dangerous_rounded,
                          color: _isKillingFiring ? Colors.amberAccent : Colors.deepOrangeAccent,
                          size: 46,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isKillingFiring ? "ESEGUO..." : "TASKKILL",
                          style: TextStyle(
                            color: _isKillingFiring ? Colors.amberAccent : Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "KILL ALL PROCESSES",
                          style: TextStyle(
                            color: (_isKillingFiring ? Colors.amberAccent : Colors.deepOrangeAccent)
                                .withValues(alpha: 0.8),
                            fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  // ─── Shutdown Circle Button ───────────────────────────────────────────────
  Widget _buildShutdownButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isShutdownPressing = true),
        onTapUp: (_) { setState(() => _isShutdownPressing = false); _triggerShutdown(); },
        onTapCancel: () => setState(() => _isShutdownPressing = false),
        child: AnimatedBuilder(
          animation: _pulseController, // Reuse pulse controller
          builder: (context, _) {
            final glow = _isShutdownFiring ? 0.0 : _pulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 200 + 30,
                  height: 200 + 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.05 * glow),
                  ),
                ),
                AnimatedScale(
                  scale: _isShutdownPressing ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isShutdownFiring
                          ? [Colors.amberAccent.withValues(alpha: 0.25), Colors.transparent]
                          : [Colors.redAccent.withValues(alpha: 0.20), Colors.transparent],
                      ),
                      border: Border.all(
                        color: _isShutdownFiring
                          ? Colors.amberAccent.withValues(alpha: 0.6)
                          : Colors.redAccent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [BoxShadow(
                        color: (_isShutdownFiring ? Colors.amberAccent : Colors.redAccent)
                            .withValues(alpha: 0.3 + glow * 0.2),
                        blurRadius: 40, spreadRadius: 5,
                      )],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isShutdownFiring ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                          color: _isShutdownFiring ? Colors.amberAccent : Colors.redAccent,
                          size: 46,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isShutdownFiring ? "INVIO..." : "SHUTDOWN",
                          style: TextStyle(
                            color: _isShutdownFiring ? Colors.amberAccent : Colors.white,
                            fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "FORCE POWER OFF",
                          style: TextStyle(
                            color: (_isShutdownFiring ? Colors.amberAccent : Colors.redAccent)
                                .withValues(alpha: 0.8),
                            fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  // ─── Shared Status Card ───────────────────────────────────────────────────
  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String message,
    required Color color,
    required bool loading,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(
                      color: Colors.white38, fontSize: 9,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        message, key: ValueKey(message),
                        style: TextStyle(
                          color: color, fontSize: 13,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Kill Info Card ───────────────────────────────────────────────────────
  Widget _buildKillInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.deepOrangeAccent, size: 14),
                  SizedBox(width: 8),
                  Text("SCRIPT ESEGUITO", style: TextStyle(
                    color: Colors.white38, fontSize: 9,
                    fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.15)),
                ),
                child: const Text(
                  "GUI r → POWERSHELL -WindowStyle Hidden\n→ Stop-Process (tutti i processi utente)\n→ Esclude: System, svchost, explorer...",
                  style: TextStyle(
                    color: Colors.white38, fontSize: 9,
                    fontFamily: 'monospace', height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  // ─── Panic Timer Display ──────────────────────────────────────────────────
  Widget _buildPanicTimer(AppState appState) {
    if (appState.panicEndTimeMillis == null) return const SizedBox.shrink();

    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = appState.panicEndTimeMillis! - now;

    if (remaining <= 0) {
      Future.microtask(() => appState.clearPanicTimer());
      return const SizedBox.shrink();
    }

    final minutes = (remaining / 60000).floor();
    final seconds = ((remaining % 60000) / 1000).floor();
    final timeStr =
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white54, size: 14),
          const SizedBox(width: 8),
          Text(
            "RIATTIVAZIONE BLUETOOTH TRA: ",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0),
          ),
          Text(
            timeStr,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ─── Radar Background ─────────────────────────────────────────────────────
  Widget _buildRadarBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _scanController,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              _scanController.value,
              color: _currentPage == 0
                  ? const Color(0xFFFF3B3B)
                  : Colors.deepOrange,
            ),
          );
        },
      ),
    );
  }
}

// ─── Radar Painter ─────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RadarPainter(this.progress, {this.color = const Color(0xFFFF3B3B)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    const maxRadius = 260.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        maxRadius * i / 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = color.withValues(alpha: 0.06),
      );
    }

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.transparent,
          Colors.transparent,
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 0.95, 1.0],
        transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    final angle = progress * math.pi * 2 - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      ),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
