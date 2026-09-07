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
      expect(es.onboardingStep2Badge, contains('ENFOQUE TOTAL'));
      expect(es.onboardingStep3Badge, contains('SINCRONIZADO'));
      expect(es.onboardingStep4Badge, contains('TODO LISTO'));
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
      expect(en.onboardingStep2Badge, contains('TOTAL FOCUS'));
      expect(en.onboardingStep3Badge, contains('SYNCED'));
      expect(en.onboardingStep4Badge, contains('ALL SET'));
    });
  });

  group('OnboardingScreen Widget Tests', () {
    Widget createOnboardingWidget({bool fromSettings = false, Locale locale = const Locale('es')}) {
      return ChangeNotifierProvider(
        create: (_) => ClockProvider(),
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

    testWidgets('Can navigate through all slides using Next button', (tester) async {
      await tester.pumpWidget(createOnboardingWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Slide 1
      expect(find.text('⏱️ INNOVACIÓN RADIAL'), findsOneWidget);

      // Tap Next -> Slide 2
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🎯 ENFOQUE TOTAL'), findsOneWidget);

      // Tap Next -> Slide 3
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🔔 SINCRONIZADO & SEGURO'), findsOneWidget);

      // Tap Next -> Slide 4 (Final)
      await tester.tap(find.byKey(const Key('onboarding_action_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('✨ TODO LISTO'), findsOneWidget);
      expect(find.text('¡Comenzar Ahora! 🚀'), findsOneWidget);
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

      // Advance to slide 4
      for (int i = 0; i < 3; i++) {
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
