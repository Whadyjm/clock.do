import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/time_block.dart';
import '../utils/radial_math.dart';

/// Servicio singleton para gestionar las notificaciones locales y recordatorios de ClockDo.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'clockdo_tasks_channel';
  static const String _channelName = 'Recordatorios de Tareas';
  static const String _channelDesc = 'Notificaciones para avisar antes del inicio de tus bloques de tiempo.';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Inicializar base de datos de zonas horarias
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(initSettings);
    } catch (_) {
      // En entorno de testing o sin canal nativo disponible
    }
    _isInitialized = true;
  }

  /// Solicita permisos de notificación en Android 13+ y iOS
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await init();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {}

    return true;
  }

  /// Muestra una notificación inmediata de prueba
  Future<void> showTestNotification({required int minutesBefore}) async {
    if (!_isInitialized) await init();

    try {
      final timingText = minutesBefore == 0
          ? 'en este instante'
          : 'en $minutesBefore minutos';

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _plugin.show(
        999999,
        '🔔 Notificación de prueba ClockDo',
        'Tus recordatorios están configurados para avisarte $timingText antes de cada bloque.',
        details,
      );
    } catch (_) {}
  }

  /// Programa el recordatorio de un bloque de tiempo según los minutos globales de anticipación
  Future<void> scheduleTaskReminder({
    required TimeBlock block,
    required int minutesBefore,
    required bool enabled,
  }) async {
    if (!enabled) return;
    if (!_isInitialized) await init();

    // Cancelar recordatorio previo si existe
    await cancelTaskReminder(block.id);

    // No programar tareas ya completadas
    if (block.status == TaskStatus.completed) return;

    // Calcular hora y minutos de inicio
    final hour = block.startHour.floor() % 24;
    final minute = ((block.startHour - block.startHour.floor()) * 60).round();

    final taskStart = DateTime(
      block.date.year,
      block.date.month,
      block.date.day,
      hour,
      minute,
    );

    // Momento exacto del aviso restando los minutos de anticipación
    final reminderTime = taskStart.subtract(Duration(minutes: minutesBefore));

    // Solo programar si la hora del recordatorio es en el futuro
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _notificationId(block.id);
    final timeFormatted = RadialMath.decimalHoursToString(block.startHour);

    final timingMessage = minutesBefore == 0
        ? 'Comienza ahora ($timeFormatted)'
        : 'Comienza en $minutesBefore minutos ($timeFormatted)';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    try {
      final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);

      await _plugin.zonedSchedule(
        id,
        '⏰ ${block.title}',
        '${block.category.displayName} • $timingMessage',
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Cancela el recordatorio de una tarea específica
  Future<void> cancelTaskReminder(String blockId) async {
    if (!_isInitialized) await init();
    try {
      await _plugin.cancel(_notificationId(blockId));
    } catch (_) {}
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAll() async {
    if (!_isInitialized) await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Convierte un UUID string a un entero seguro para Android Notification ID
  int _notificationId(String blockId) {
    return blockId.hashCode.abs() % 2147483647;
  }
}
