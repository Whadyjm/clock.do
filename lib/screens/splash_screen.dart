import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Controlador para fade + scale del logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Controlador para el pulso del glow (loop)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Quitar splash nativo, iniciar animación e inicialización en paralelo
    FlutterNativeSplash.remove();
    _logoController.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    // Mínimo 1.8s de splash + inicialización en paralelo
    await Future.wait([
      _runInit(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    _navigateNext();
  }

  Future<void> _runInit() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
    await NotificationService().init();
    await SupabaseService().initialize();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding =
        !(prefs.getBool('clockdo_onboarding_completed') ?? false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            showOnboarding ? const OnboardingScreen() : const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradiente de fondo diagonal oscuro con acento violeta
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0F1A),
              Color(0xFF13162B),
              Color(0xFF1A1040),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Glow radial pulsante detrás del logo ──────────────────
            Center(
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: screenWidth * 0.85,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7)
                            .withValues(alpha: _glowAnim.value),
                        blurRadius: 120,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B7CF6)
                            .withValues(alpha: _glowAnim.value * 0.5),
                        blurRadius: 60,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Logo Clock.Do — fade + scale ──────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Image.asset(
                    'assets/clickdologo.png',
                    width: screenWidth * 0.62,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

