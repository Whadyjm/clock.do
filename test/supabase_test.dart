import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/services/supabase_config.dart';
import 'package:clockdo/services/supabase_service.dart';
import 'package:clockdo/widgets/auth/auth_sheet.dart';
import 'package:clockdo/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Supabase Config & Service Initialization', () {
    test('SupabaseConfig correctly identifies configuration state', () {
      // With real credentials configured, isConfigured is true
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('SupabaseService handles unconfigured state gracefully', () async {
      final service = SupabaseService();
      expect(service.isInitialized, isFalse);
      expect(service.currentUser, isNull);
      expect(service.isAuthenticated, isFalse);

      final blocks = await service.fetchTimeBlocks();
      expect(blocks, isEmpty);

      final todos = await service.fetchTodos();
      expect(todos, isEmpty);
    });
  });

  group('Supabase Serialization Mapping', () {
    test('TimeBlock toSupabaseMap and fromSupabaseMap roundtrip', () {
      final block = TimeBlock.create(
        title: 'Reunión de Equipo',
        description: 'Revisión de sprint',
        date: DateTime(2026, 9, 2),
        startHour: 9.5,
        endHour: 10.5,
        category: TaskCategory.work,
        status: TaskStatus.inProgress,
      );

      final map = block.toSupabaseMap();
      expect(map['id'], block.id);
      expect(map['title'], 'Reunión de Equipo');
      expect(map['start_hour'], 9.5);
      expect(map['end_hour'], 10.5);
      expect(map['date'], '2026-09-02');
      expect(map['category'], TaskCategory.work.index);
      expect(map['status'], TaskStatus.inProgress.index);

      final fromMap = TimeBlock.fromSupabaseMap(map);
      expect(fromMap.id, block.id);
      expect(fromMap.title, block.title);
      expect(fromMap.description, block.description);
      expect(fromMap.startHour, block.startHour);
      expect(fromMap.endHour, block.endHour);
      expect(fromMap.category, block.category);
      expect(fromMap.status, block.status);
    });

    test('TodoItem toSupabaseMap and fromSupabaseMap roundtrip', () {
      final todo = TodoItem.create(
        title: 'Comprar insumos',
        description: 'Papel y café',
        category: TaskCategory.personal,
      );

      final map = todo.toSupabaseMap();
      expect(map['id'], todo.id);
      expect(map['title'], 'Comprar insumos');
      expect(map['is_completed'], isFalse);
      expect(map['category'], TaskCategory.personal.index);

      final fromMap = TodoItem.fromSupabaseMap(map);
      expect(fromMap.id, todo.id);
      expect(fromMap.title, todo.title);
      expect(fromMap.description, todo.description);
      expect(fromMap.category, todo.category);
      expect(fromMap.isCompleted, isFalse);
    });
  });

  group('Password Recovery & Auth Methods', () {
    test('resetPasswordForEmail throws exception when client not initialized', () async {
      final service = SupabaseService();
      expect(
        () => service.resetPasswordForEmail('test@example.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyRecoveryOtp throws exception when client not initialized', () async {
      final service = SupabaseService();
      expect(
        () => service.verifyRecoveryOtp(
          email: 'test@example.com',
          token: '123456',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePassword throws exception when client not initialized', () async {
      final service = SupabaseService();
      expect(
        () => service.updatePassword('newPassword123'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthSheet Password Recovery Navigation', () {
    Widget createTestWidget({
      AuthSheetMode mode = AuthSheetMode.signIn,
      String? initialEmail,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => ClockProvider(),
            child: AuthSheet(
              initialMode: mode,
              initialEmail: initialEmail,
            ),
          ),
        ),
      );
    }

    testWidgets('Tapping ¿Olvidaste tu contraseña? navigates to forgot password view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar Contraseña'), findsOneWidget);
      expect(find.text('Enviar Código de Recuperación'), findsOneWidget);
      expect(find.text('¿Ya tienes un código? Ingrésalo aquí'), findsOneWidget);
    });

    testWidgets('Navigating from forgot password to reset password and back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createTestWidget(mode: AuthSheetMode.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar Contraseña'), findsOneWidget);
      await tester.tap(find.text('¿Ya tienes un código? Ingrésalo aquí'));
      await tester.pumpAndSettle();

      expect(find.text('Restablecer Contraseña'), findsNWidgets(2));
      expect(find.text('Código OTP (6 dígitos)'), findsOneWidget);
      expect(find.text('Nueva Contraseña'), findsOneWidget);

      await tester.tap(find.text('Volver a Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsWidgets);
    });

    testWidgets('AuthSheet can initialize directly in resetPassword mode with email', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      await tester.pumpWidget(createTestWidget(
        mode: AuthSheetMode.resetPassword,
        initialEmail: 'user@example.com',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Restablecer Contraseña'), findsNWidgets(2));
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Código OTP (6 dígitos)'), findsOneWidget);
    });
  });
}
