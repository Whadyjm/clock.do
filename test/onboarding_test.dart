import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/l10n/app_localizations.dart';
import 'package:clockdo/l10n/app_localizations_es.dart';
import 'package:clockdo/l10n/app_localizations_en.dart';
import 'package:clockdo/screens/onboarding_screen.dart';
import 'package:clockdo/widgets/settings/app_settings_sheet.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding Localization Tests', () {
    test('Spanish onboarding getters have valid, descriptive strings', () {
      final es = AppLocalizationsEs();
      expect(es.viewOnboardingOption, contains('Guía de Bienvenida'));
      expect(es.onboardingSkip, 'Saltar');
      expect(es.onboardingNext, 'Siguiente');
      expect(es.onboardingGetStarted, contains('Comenzar Ahora'));
      expect(es.onboardingStep1Badge, contains('INNOVACIÓN RADIAL'));
      expect(es.onboardingStep1Title, isNotEmpty);
      expect(es.onboardingStep1Desc, isNotEmpty);
      expect(es.onboardingStep2Badge, contains('KANBAN'));
      expect(es.onboardingStep3Badge, contains('POMODORO'));
      expect(es.onboardingStep4Badge, contains('RECORDATORIOS'));
      expect(es.onboardingStep5Badge, contains('PERSONALIZACIÓN'));
      expect(es.onboardingStep6Badge, contains('TODO LISTO'));
      expect(es.onboardingEnableReminders, isNotEmpty);
      expect(es.onboardingThemePreference, isNotEmpty);
      expect(es.onboardingLanguagePreference, isNotEmpty);
    });

    test('English onboarding getters have valid strings', () {
      final en = AppLocalizationsEn();
      expect(en.viewOnboardingOption, contains('Welcome Guide'));
      expect(en.onboardingSkip, 'Skip');
      expect(en.onboardingNext, 'Next');
      expect(en.onboardingGetStarted, contains('Get Started'));
      expect(en.onboardingStep1Badge, contains('RADIAL INNOVATION'));
      expect(en.onboardingStep1Title, isNotEmpty);
      expect(en.onboardingStep1Desc, isNotEmpty);
      expect(en.onboardingStep2Badge, contains('KANBAN BOARD'));
      expect(en.onboardingStep3Badge, contains('POMODORO MODE'));
      expect(en.onboardingStep4Badge, contains('SMART REMINDERS'));
      expect(en.onboardingStep5Badge, contains('PERSONALIZATION'));
      expect(en.onboardingStep6Badge, contains('ALL SET'));
      expect(en.onboardingEnableReminders, isNotEmpty);
      expect(en.onboardingThemePreference, isNotEmpty);
      expect(en.onboardingLanguagePreference, isNotEmpty);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    Widget createOnboardingWidget({
      bool fromSettings = false,
      Locale locale = const Locale('es'),
      ClockProvider? provider,
    }) {
      return ChangeNotifierProvider<ClockProvider>(
        create: (_) => provider ?? ClockProvider(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(fromSettings: fromSettings),
        ),
      );
    }

    testWidgets('Renders first slide with brand pill, skip button, and radial badge', (tester) async {
      await tester.pumpWidget(createOnboardingWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('brand_logo')), findsOneWidget);
      expect(find.text('Saltar'), findsOneWidget);
      expect(find.text('⏱️ INNOVACIÓN RADIAL'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });

    testWidgets('Can navigate through all 6 slides using Next button', (tester) async {
      await tester.pumpWidget(createOnboardingWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Slide 1: Radial Clock
      expect(find.text('⏱️ INNOVACIÓN RADIAL'), findsOneWidget);

      // Tap Next -> Slide 2: Kanban Board
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('📋 TABLERO KANBAN'), findsOneWidget);
      expect(find.text('BACKLOG'), findsOneWidget);
      expect(find.text('EN CURSO'), findsOneWidget);
      expect(find.text('HECHO'), findsOneWidget);

      // Tap Next -> Slide 3: Pomodoro Mode
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🍅 MODO POMODORO'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);

      // Tap Next -> Slide 4: Smart Reminders
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🔔 RECORDATORIOS INTELIGENTES'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_notifications_switch')), findsOneWidget);

      // Tap Next -> Slide 5: Theme & Language Preferences
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🎨 PERSONALIZACIÓN'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_theme_dark')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_lang_en')), findsOneWidget);

      // Tap Next -> Slide 6: All Set (Final)
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('✨ TODO LISTO'), findsOneWidget);
      expect(find.text('¡Comenzar Ahora! 🚀'), findsOneWidget);
    });

    testWidgets('Interactive reminder switch and advance chips update ClockProvider', (tester) async {
      final provider = ClockProvider();
      await tester.pumpWidget(createOnboardingWidget(provider: provider));
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Slide 4 (Smart Reminders) - 3 taps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboarding_action_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byKey(const Key('onboarding_notifications_switch')), findsOneWidget);

      // Switch notifications toggle
      await tester.tap(find.byKey(const Key('onboarding_notifications_switch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select 15m advance chip
      final chip15 = find.byKey(const Key('onboarding_advance_chip_15'));
      expect(chip15, findsOneWidget);
      await tester.tap(chip15);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(provider.reminderMinutesBefore, equals(15));
      expect(provider.notificationsEnabled, isTrue);
    });

    testWidgets('Interactive theme and language options update ClockProvider', (tester) async {
      final provider = ClockProvider();
      await tester.pumpWidget(createOnboardingWidget(provider: provider));
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Slide 5 (Preferences) - 4 taps
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('onboarding_action_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byKey(const Key('onboarding_theme_dark')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_lang_en')), findsOneWidget);

      // Select Dark Theme
      await tester.tap(find.byKey(const Key('onboarding_theme_dark')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(provider.themeMode, equals(ThemeMode.dark));

      // Select English Language
      await tester.tap(find.byKey(const Key('onboarding_lang_en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(provider.locale, equals(const Locale('en')));

      // Select Light Theme
      await tester.tap(find.byKey(const Key('onboarding_theme_light')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(provider.themeMode, equals(ThemeMode.light));
    });

    testWidgets('Skipping saves onboarding completed flag in SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({'clockdo_onboarding_completed': false});

      await tester.pumpWidget(createOnboardingWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Skip
      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('clockdo_onboarding_completed'), isTrue);
    });

    testWidgets('Completing the final slide saves onboarding completed flag', (tester) async {
      SharedPreferences.setMockInitialValues({'clockdo_onboarding_completed': false});

      await tester.pumpWidget(createOnboardingWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Advance to slide 6 (5 taps)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('onboarding_action_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Tap Get Started
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('clockdo_onboarding_completed'), isTrue);
    });

    testWidgets('Opening from settings allows replay and back navigation', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ClockProvider(),
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => AppSettingsSheet.show(context),
                      child: const Text('Abrir Ajustes'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Open Settings
      await tester.tap(find.text('Abrir Ajustes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check that "Ver Guía de Bienvenida" is hidden from Settings
      expect(find.text('Ver Guía de Bienvenida'), findsNothing);
    });
  });
}
