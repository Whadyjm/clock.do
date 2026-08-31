import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/clock_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  // Orientación vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ClockDoApp());
}

class ClockDoApp extends StatelessWidget {
  const ClockDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClockProvider(),
      child: Consumer<ClockProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'ClockDo',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF0EEFF),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C5CE7),
        secondary: Color(0xFF00CEC9),
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFF7F6FD),
        outlineVariant: Color(0xFFE8E4FF),
        error: Color(0xFFFF7675),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1E1B4B),
        displayColor: const Color(0xFF1E1B4B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F6FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteColor: const Color(0xFFF0EEFF),
        dialBackgroundColor: const Color(0xFFF7F6FD),
        hourMinuteTextColor: const Color(0xFF6C5CE7),
        dialHandColor: const Color(0xFF6C5CE7),
        dialTextColor: const Color(0xFF1E1B4B),
        entryModeIconColor: const Color(0xFF6C5CE7),
        dayPeriodColor: const Color(0xFFF0EEFF),
        dayPeriodTextColor: const Color(0xFF6C5CE7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0F1A),
      cardColor: const Color(0xFF13162B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C5CE7),
        secondary: Color(0xFF00CEC9),
        surface: Color(0xFF13162B),
        surfaceContainerHighest: Color(0xFF1A1D2E),
        outlineVariant: Color(0xFF2A2D42),
        error: Color(0xFFFF7675),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1D2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF13162B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: const Color(0xFF13162B),
        hourMinuteColor: const Color(0xFF1A1D2E),
        dialBackgroundColor: const Color(0xFF0D0F1A),
        hourMinuteTextColor: Colors.white,
        dialHandColor: const Color(0xFF6C5CE7),
        dialTextColor: Colors.white,
        entryModeIconColor: Colors.white,
        dayPeriodColor: const Color(0xFF1A1D2E),
        dayPeriodTextColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
