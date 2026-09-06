import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/l10n/app_localizations.dart';
import 'package:clockdo/l10n/app_localizations_es.dart';
import 'package:clockdo/l10n/app_localizations_en.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/providers/clock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLocalizations & Strings Tests', () {
    test('Spanish translations contain correct texts', () {
      final es = AppLocalizationsEs();
      expect(es.appTitle, 'Clock.Do');
      expect(es.today, 'Hoy');
      expect(es.cancel, 'Cancelar');
      expect(es.save, 'Guardar');
      expect(es.delete, 'Eliminar');
      expect(es.categoryWork, 'Trabajo');
      expect(es.categoryPersonal, 'Personal');
      expect(es.languageSpanish, 'Español');
      expect(es.languageEnglish, 'English');
      expect(es.languageSystem, 'Seguir Sistema');
      expect(es.statusPending, 'Pendiente');
      expect(es.statusInProgress, 'En progreso');
      expect(es.statusCompleted, 'Completada');
    });

    test('English translations contain correct texts', () {
      final en = AppLocalizationsEn();
      expect(en.appTitle, 'Clock.Do');
      expect(en.today, 'Today');
      expect(en.cancel, 'Cancel');
      expect(en.save, 'Save');
      expect(en.delete, 'Delete');
      expect(en.categoryWork, 'Work');
      expect(en.categoryPersonal, 'Personal');
      expect(en.languageSpanish, 'Español');
      expect(en.languageEnglish, 'English');
      expect(en.languageSystem, 'Follow System');
      expect(en.statusPending, 'Pending');
      expect(en.statusInProgress, 'In progress');
      expect(en.statusCompleted, 'Completed');
    });

    test('AppLocalizationsDelegate supports es and en', () async {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('es')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);

      final locEs = await delegate.load(const Locale('es'));
      expect(locEs, isA<AppLocalizationsEs>());
      expect(locEs.today, 'Hoy');

      final locEn = await delegate.load(const Locale('en'));
      expect(locEn, isA<AppLocalizationsEn>());
      expect(locEn.today, 'Today');
    });
  });

  group('ClockProvider Locale Management & Persistence', () {
    test('ClockProvider defaults to null locale (follow system)', () {
      final provider = ClockProvider();
      expect(provider.locale, isNull);
      expect(provider.currentLanguageCode, 'system');
    });

    test('ClockProvider setLocale updates state and currentLanguageCode', () async {
      final provider = ClockProvider();
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      provider.setLocale(const Locale('en'));
      expect(provider.locale, const Locale('en'));
      expect(provider.currentLanguageCode, 'en');
      expect(notificationCount, 1);

      provider.setLocale(const Locale('es'));
      expect(provider.locale, const Locale('es'));
      expect(provider.currentLanguageCode, 'es');
      expect(notificationCount, 2);

      provider.setLocale(null);
      expect(provider.locale, isNull);
      expect(provider.currentLanguageCode, 'system');
      expect(notificationCount, 3);
    });

    test('ClockProvider persists and restores locale preference', () async {
      SharedPreferences.setMockInitialValues({
        'clockdo_locale': 'en',
      });

      final provider = ClockProvider();
      // Esperar microtask de carga inicial
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.locale, const Locale('en'));
      expect(provider.currentLanguageCode, 'en');
    });
  });

  group('Localized Models (TaskCategory & TaskStatus)', () {
    testWidgets('TaskCategory and TaskStatus render localized names in English', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  Text(TaskCategory.work.getLocalizedName(context)),
                  Text(TaskCategory.personal.getLocalizedName(context)),
                  Text(TaskStatus.pending.getLocalizedName(context)),
                  Text(TaskStatus.inProgress.getLocalizedName(context)),
                  Text(TaskStatus.completed.getLocalizedName(context)),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('TaskCategory and TaskStatus render localized names in Spanish', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  Text(TaskCategory.work.getLocalizedName(context)),
                  Text(TaskCategory.personal.getLocalizedName(context)),
                  Text(TaskStatus.pending.getLocalizedName(context)),
                  Text(TaskStatus.inProgress.getLocalizedName(context)),
                  Text(TaskStatus.completed.getLocalizedName(context)),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trabajo'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('En progreso'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
    });

    testWidgets('Custom TaskCategory preserves its user-given name across languages', (tester) async {
      final customCat = TaskCategory.custom(
        name: 'Gimnasio Especial',
        color: Colors.orange,
        icon: Icons.fitness_center_rounded,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Text(customCat.getLocalizedName(context));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gimnasio Especial'), findsOneWidget);
    });
  });
}
