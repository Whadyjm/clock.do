import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';

/// Servicio para interactuar con los calendarios nativos del dispositivo (Google, iCloud, etc.).
class DeviceCalendarService {
  static final DeviceCalendarService _instance = DeviceCalendarService._internal();
  factory DeviceCalendarService() => _instance;
  DeviceCalendarService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Comprueba si se tienen los permisos necesarios para acceder a los calendarios.
  Future<bool> hasPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      debugPrint('[DeviceCalendarService] Error comprobando permisos: $e');
      return false;
    }
  }

  /// Solicita permisos de lectura y escritura para el calendario del sistema.
  Future<bool> requestPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      debugPrint('[DeviceCalendarService] Error solicitando permisos: $e');
      return false;
    }
  }

  /// Obtiene la lista de todos los calendarios disponibles en el dispositivo.
  Future<List<Calendar>> getCalendars() async {
    try {
      final hasPerm = await hasPermissions();
      if (!hasPerm) {
        final granted = await requestPermissions();
        if (!granted) return [];
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        return calendarsResult.data!.toList();
      }
      return [];
    } catch (e) {
      debugPrint('[DeviceCalendarService] Error obteniendo calendarios: $e');
      return [];
    }
  }

  /// Obtiene los eventos para un rango de fechas desde los calendarios indicados por ID.
  Future<List<TimeBlock>> fetchEventsForRange({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> calendarIds,
    Map<String, String>? calendarNames,
  }) async {
    if (calendarIds.isEmpty) return [];

    final hasPerm = await hasPermissions();
    if (!hasPerm) {
      debugPrint('[DeviceCalendarService] Sin permisos de calendario.');
      return [];
    }

    final sDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final eDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final List<TimeBlock> blocks = [];

    for (final calId in calendarIds) {
      final calName = calendarNames?[calId] ?? 'Calendario';
      try {
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calId,
          RetrieveEventsParams(
            startDate: sDate,
            endDate: eDate,
          ),
        );

        if (!eventsResult.isSuccess || eventsResult.data == null) {
          debugPrint('[DeviceCalendarService] retrieveEvents falló para $calName ($calId): ${eventsResult.errors.map((e) => e.errorMessage).join(", ")}');
          continue;
        }

        final events = eventsResult.data!;
        debugPrint('[DeviceCalendarService] $calName ($calId): encontrados ${events.length} eventos.');

        for (final event in events) {
          final block = _convertEventToTimeBlock(event, calName);
          if (block != null) {
            blocks.add(block);
          }
        }
      } catch (e) {
        debugPrint('[DeviceCalendarService] Error obteniendo eventos para calendario $calId: $e');
      }
    }

    return blocks;
  }

  /// Obtiene los eventos para una fecha específica desde los calendarios indicados por ID.
  Future<List<TimeBlock>> fetchEventsForDate({
    required DateTime date,
    required List<String> calendarIds,
    Map<String, String>? calendarNames,
  }) async {
    return fetchEventsForRange(
      startDate: date,
      endDate: date,
      calendarIds: calendarIds,
      calendarNames: calendarNames,
    );
  }

  /// Convierte un [Event] de device_calendar en un [TimeBlock] para Clock.Do.
  TimeBlock? _convertEventToTimeBlock(
    Event event,
    String calendarName,
  ) {
    final eventStart = event.start;
    if (eventStart == null) return null;

    final title = (event.title == null || event.title!.trim().isEmpty)
        ? 'Evento de Calendario'
        : event.title!.trim();

    final startLocal = eventStart.toLocal();
    final eventDate = normalizeDate(startLocal);

    // Eventos de todo el día: Tarea puntual a las 8:00 AM con nota
    if (event.allDay == true) {
      return TimeBlock.create(
        title: title,
        description: event.description,
        date: eventDate,
        startHour: 8.0,
        endHour: null, // Tarea puntual
        category: TaskCategory.work,
        status: TaskStatus.pending,
        isExternalCalendar: true,
        externalEventId: event.eventId,
        externalCalendarName: calendarName,
      );
    }

    // Eventos con horas definidas
    final endLocal = event.end?.toLocal();

    // Calcular hora de inicio decimal para el día correspondiente
    final startDecimal = (startLocal.hour + (startLocal.minute / 60.0)).clamp(0.0, 23.99);

    // Calcular hora de fin decimal
    double? endDecimal;
    if (endLocal != null) {
      if (endLocal.day != startLocal.day && endLocal.isAfter(startLocal)) {
        endDecimal = 24.0;
      } else {
        endDecimal = (endLocal.hour + (endLocal.minute / 60.0)).clamp(0.0, 24.0);
      }

      // Si la duración es 0 o negativa (evento mal configurado), darle al menos 30 min
      if (endDecimal <= startDecimal) {
        endDecimal = (startDecimal + 0.5).clamp(0.0, 24.0);
      }
    } else {
      // Si no tiene fin, darle 1 hora de duración por defecto
      endDecimal = (startDecimal + 1.0).clamp(0.0, 24.0);
    }

    return TimeBlock.create(
      title: title,
      description: event.description,
      date: eventDate,
      startHour: startDecimal,
      endHour: endDecimal,
      category: TaskCategory.work,
      status: TaskStatus.pending,
      isExternalCalendar: true,
      externalEventId: event.eventId,
      externalCalendarName: calendarName,
    );
  }
}
