import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
      // Detectar zona horaria del dispositivo automáticamente
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('[ClockDo Notif] Timezone detected: $timeZoneName');
      } catch (e) {
        debugPrint('[ClockDo Notif] Could not detect timezone, using UTC: $e');
      }


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

      final initialized = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[ClockDo Notif] Notification tapped: ${response.payload}');
        },
      );
      debugPrint('[ClockDo Notif] Plugin initialized: $initialized');

      // Crear canal de Android explícitamente
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        debugPrint('[ClockDo Notif] Android notification channel created');
      }
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR during init: $e');
    }
    _isInitialized = true;
  }

  /// Solicita permisos de notificación en Android 13+ y iOS,
  /// incluyendo permiso de alarma exacta en Android 12+.
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await init();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // Permiso de notificaciones (Android 13+)
        final notifGranted = await androidImpl.requestNotificationsPermission();
        debugPrint('[ClockDo Notif] Android notification permission: $notifGranted');

        // Permiso de alarma exacta (Android 12+ / API 31+)
        final exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
        debugPrint('[ClockDo Notif] Android exact alarm permission: $exactAlarmGranted');

        return notifGranted ?? true;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[ClockDo Notif] iOS permission: $granted');
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR requesting permissions: $e');
    }

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
      debugPrint('[ClockDo Notif] Test notification sent');
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR sending test notification: $e');
    }
  }

  /// Programa el recordatorio de un bloque de tiempo según los minutos globales de anticipación
  Future<void> scheduleTaskReminder({
    required TimeBlock block,
    required int minutesBefore,
    required bool enabled,
  }) async {
    if (!enabled) {
      debugPrint('[ClockDo Notif] Notifications disabled, skipping schedule for "${block.title}"');
      return;
    }
    if (!_isInitialized) await init();

    // Cancelar recordatorios previos de este bloque si existen
    await cancelTaskReminder(block.id);

    // No programar tareas ya completadas
    if (block.status == TaskStatus.completed) {
      debugPrint('[ClockDo Notif] Block "${block.title}" already completed, skipping');
      return;
    }

    // Calcular hora y minutos de inicio a partir del valor decimal 0-24
    final hour = block.startHour.floor() % 24;
    final minute = ((block.startHour - block.startHour.floor()) * 60).round();

    final taskStart = DateTime(
      block.date.year,
      block.date.month,
      block.date.day,
      hour,
      minute,
    );

    final now = DateTime.now();

    // Si la hora de inicio de la tarea ya pasó completamente, no programar
    if (taskStart.isBefore(now)) {
      debugPrint('[ClockDo Notif] Task start for "${block.title}" is in the past '
          '($taskStart vs $now), skipping');
      return;
    }

    final reminderTime = taskStart.subtract(Duration(minutes: minutesBefore));
    final timeFormatted = RadialMath.decimalHoursToString(block.startHour);

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

    // 1. Notificación con anticipación (si minutesBefore > 0 y reminderTime está en el futuro)
    if (minutesBefore > 0) {
      if (reminderTime.isAfter(now)) {
        final advanceId = _notificationId(block.id);
        await _scheduleSingleZonedNotification(
          id: advanceId,
          title: '⏰ ${block.title}',
          body: '${block.category.displayName} • Comienza en $minutesBefore minutos ($timeFormatted)',
          scheduledDate: reminderTime,
          details: details,
        );
      } else {
        debugPrint('[ClockDo Notif] Advance reminder time for "${block.title}" already passed '
            '($reminderTime vs $now), scheduling directly at start time.');
      }
    }

    // 2. Notificación al inicio del evento ("Comienza ahora")
    final startId = minutesBefore == 0
        ? _notificationId(block.id)
        : _startNotificationId(block.id);

    await _scheduleSingleZonedNotification(
      id: startId,
      title: '⏰ ${block.title}',
      body: '${block.category.displayName} • Comienza ahora ($timeFormatted)',
      scheduledDate: taskStart,
      details: details,
    );
  }

  /// Programa una notificación en zona horaria intentando primero alarma exacta y fallback a inexacta
  Future<void> _scheduleSingleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
  }) async {
    try {
      final scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('[ClockDo Notif] Scheduling notification #$id for "$title" at $scheduledTz');

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[ClockDo Notif] ✅ Scheduled (exact) notification #$id');
      } catch (exactError) {
        debugPrint('[ClockDo Notif] ⚠️ Exact alarm failed, falling back to inexact: $exactError');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[ClockDo Notif] ✅ Scheduled (inexact fallback) notification #$id');
      }
    } catch (e) {
      debugPrint('[ClockDo Notif] ❌ ERROR scheduling notification #$id: $e');
    }
  }

  /// Cancela el recordatorio de una tarea específica
  Future<void> cancelTaskReminder(String blockId) async {
    if (!_isInitialized) await init();
    try {
      await _plugin.cancel(_notificationId(blockId));
      await _plugin.cancel(_startNotificationId(blockId));
      await cancelIntervalReminders(blockId);
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR cancelling notification for $blockId: $e');
    }
  }

  /// Programa recordatorios periódicos por intervalo para un bloque de tiempo
  Future<void> scheduleIntervalReminders({
    required TimeBlock block,
    required bool enabled,
  }) async {
    if (!enabled || !block.hasIntervalReminder || block.recurrence?.reminderIntervalMinutes == null) {
      await cancelIntervalReminders(block.id);
      return;
    }
    if (!_isInitialized) await init();

    await cancelIntervalReminders(block.id);

    if (block.status == TaskStatus.completed) return;

    final reminderHours = block.recurrence!.calculateReminderHours(
      startHour: block.startHour,
      endHour: block.endHour,
    );
    if (reminderHours.isEmpty) return;

    final now = DateTime.now();

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

    for (int i = 0; i < reminderHours.length; i++) {
      final hourDecimal = reminderHours[i];
      final h = hourDecimal.floor() % 24;
      final m = ((hourDecimal - hourDecimal.floor()) * 60).round();

      final reminderTime = DateTime(
        block.date.year,
        block.date.month,
        block.date.day,
        h,
        m,
      );

      if (reminderTime.isBefore(now)) continue;

      final id = _intervalNotificationId(block.id, i);
      final timeFormatted = RadialMath.decimalHoursToString(hourDecimal);

      try {
        final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
        await _plugin.zonedSchedule(
          id,
          '🔁 ${block.title}',
          '${block.category.displayName} • Recordatorio ($timeFormatted)',
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[ClockDo Notif] ✅ Scheduled interval reminder #$id at $scheduledTz');
      } catch (e) {
        debugPrint('[ClockDo Notif] Error scheduling interval reminder #$id: $e');
      }
    }
  }

  /// Cancela los recordatorios de intervalo de una tarea específica
  Future<void> cancelIntervalReminders(String blockId) async {
    if (!_isInitialized) await init();
    try {
      for (int i = 0; i < 48; i++) {
        await _plugin.cancel(_intervalNotificationId(blockId, i));
      }
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR cancelling interval notifications for $blockId: $e');
    }
  }

  int _intervalNotificationId(String blockId, int index) {
    return (blockId.hashCode ^ ((index + 1) * 7919)).abs() % 2147483647;
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAll() async {
    if (!_isInitialized) await init();
    try {
      await _plugin.cancelAll();
      debugPrint('[ClockDo Notif] All notifications cancelled');
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR cancelling all notifications: $e');
    }
  }

  /// Obtiene la lista de notificaciones pendientes (útil para debug)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await init();
    try {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[ClockDo Notif] Pending notifications: ${pending.length}');
      for (final n in pending) {
        debugPrint('[ClockDo Notif]   - #${n.id}: ${n.title}');
      }
      return pending;
    } catch (e) {
      debugPrint('[ClockDo Notif] ERROR getting pending notifications: $e');
      return [];
    }
  }

  /// Convierte un UUID string a un entero seguro para Android Notification ID
  int _notificationId(String blockId) {
    return blockId.hashCode.abs() % 2147483647;
  }

  /// Genera un ID secundario seguro para la notificación que avisa al inicio del evento
  int _startNotificationId(String blockId) {
    return (blockId.hashCode ^ 0x2A5A).abs() % 2147483647;
  }
}

