import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Implementación en Español de AppLocalizations.
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs() : super(const Locale('es'));

  @override
  String get appTitle => 'Clock.Do';
  @override
  String get today => 'Hoy';
  @override
  String get cancel => 'Cancelar';
  @override
  String get save => 'Guardar';
  @override
  String get edit => 'Editar';
  @override
  String get delete => 'Eliminar';
  @override
  String get accept => 'Aceptar';
  @override
  String get close => 'Cerrar';
  @override
  String get success => 'Éxito';
  @override
  String get error => 'Error';

  @override
  String get statusPending => 'Pendiente';
  @override
  String get statusInProgress => 'En progreso';
  @override
  String get statusCompleted => 'Completada';

  @override
  String get cloudSyncTooltip => 'Iniciar Sesión / Nube';
  @override
  String accountTooltip(String email) => 'Cuenta: $email';
  @override
  String pendingTodosTooltip(int count) => count == 1
      ? '1 tarea pendiente'
      : '$count tareas pendientes';
  @override
  String remindersActiveTooltip(int minutes) =>
      'Recordatorios: ${minutes == 0 ? "Al comenzar" : "${minutes}m antes"}';
  @override
  String get remindersAtStartTooltip => 'Recordatorios: Al comenzar';
  @override
  String get remindersDisabledTooltip => 'Recordatorios desactivados';
  @override
  String themeTooltip(String modeName) => 'Tema: $modeName';
  @override
  String get monthlyCalendarTooltip => 'Calendario Mensual';
  @override
  String get languageTooltip => 'Cambiar Idioma';
  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get settingsSubtitle => 'Personaliza tema, idioma y recordatorios';

  @override
  String get languageTitle => 'Idioma de la Aplicación';
  @override
  String get languageSubtitle => 'Selecciona tu idioma preferido';
  @override
  String get languageSpanish => 'Español';
  @override
  String get languageSpanishDesc => 'Español (Castellano)';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageEnglishDesc => 'English (US)';
  @override
  String get languageSystem => 'Seguir Sistema';
  @override
  String get languageSystemDesc => 'Detectar automáticamente según tu dispositivo';

  @override
  String get themeTitle => 'Tema de la Aplicación';
  @override
  String get lightMode => 'Modo Claro';
  @override
  String get lightModeDesc => 'Diseño brillante y tonos pastel';
  @override
  String get darkMode => 'Modo Oscuro';
  @override
  String get darkModeDesc => 'Superficies profundas y contrastes vívidos';
  @override
  String get systemMode => 'Seguir Sistema';
  @override
  String get systemModeDesc => 'Se ajusta automáticamente a tu dispositivo';

  @override
  String get dayToday => 'Hoy';
  @override
  String get noTasksDay => 'Sin bloques de tiempo';
  @override
  String get noTasksDaySubtitle => 'Toca el reloj o pulsa + para planificar tu día';

  @override
  String get magnifierMode => 'Modo Lupa';
  @override
  String get hourFormat12 => '12H';
  @override
  String get hourFormat24 => '24H';

  @override
  String get categoryWork => 'Trabajo';
  @override
  String get categoryPersonal => 'Personal';
  @override
  String get categoryHealth => 'Salud';
  @override
  String get categoryStudy => 'Estudio';
  @override
  String get categoryLeisure => 'Ocio';
  @override
  String get categoryOther => 'Otro';

  @override
  String get newCategoryTitle => 'Nueva Categoría';
  @override
  String get editCategoryTitle => 'Editar Categoría';
  @override
  String get categoryNameLabel => 'Nombre de la categoría';
  @override
  String get categoryNameHint => 'Ej: Gimnasio, Proyectos...';
  @override
  String get categoryNameRequired => 'Ingresa un nombre para la categoría';
  @override
  String get categoryColorLabel => 'Color distintivo';
  @override
  String get categoryIconLabel => 'Icono representativo';
  @override
  String get createCategoryButton => 'Crear Categoría';
  @override
  String get saveCategoryButton => 'Guardar Cambios';
  @override
  String get deleteCategoryConfirm => '¿Deseas eliminar esta categoría? Las tareas asociadas pasarán a la categoría Otro.';

  @override
  String get newTaskTitle => 'Nuevo Bloque de Tiempo';
  @override
  String get editTaskTitle => 'Editar Bloque de Tiempo';
  @override
  String get taskTitleLabel => 'Título del bloque';
  @override
  String get taskTitleHint => '¿Qué vas a realizar?';
  @override
  String get taskTitleRequired => 'Ingresa un título para la tarea';
  @override
  String get taskDescLabel => 'Notas o descripción (opcional)';
  @override
  String get taskDescHint => 'Añade detalles, enlaces o subtareas...';
  @override
  String get startTimeLabel => 'Hora de Inicio';
  @override
  String get endTimeLabel => 'Hora de Fin';
  @override
  String get durationLabel => 'Duración';
  @override
  String get categoryLabel => 'Categoría';
  @override
  String get newCategoryOption => '+ Nueva Categoría';
  @override
  String get reminderLabel => 'Notificación de Recordatorio';
  @override
  String get reminderCustomTime => 'Personalizado';
  @override
  String get reminderDisabled => 'Sin notificación';
  @override
  String get reminderGlobalDefault => 'Configuración global';
  @override
  String get deleteTaskConfirmTitle => '¿Eliminar bloque?';
  @override
  String get deleteTaskConfirmMessage => 'Esta acción no se puede deshacer.';
  @override
  String get invalidTimeRangeError => 'La hora de fin debe ser posterior a la hora de inicio';
  @override
  String get taskOverlapWarning => 'Este bloque se superpone con otro horario';

  @override
  String get notificationsSettingsTitle => 'Notificaciones y Recordatorios';
  @override
  String get notificationsMasterToggle => 'Activar notificaciones';
  @override
  String get notificationsMasterToggleDesc => 'Recibe alertas sonoras y visuales antes de que comiencen tus tareas planificadas.';
  @override
  String get defaultAdvanceTime => 'Anticipación predeterminada';
  @override
  String get advanceAtEventTime => 'Al comenzar el evento';
  @override
  String advanceMinutesBefore(int minutes) => '$minutes min antes';
  @override
  String get testNotificationButton => 'Enviar Notificación de Prueba';
  @override
  String get testNotificationSent => 'Notificación de prueba enviada';

  @override
  String get todoListTitle => 'Tareas Pendientes (ToDo)';
  @override
  String get todoListSubtitle => 'Banco de tareas listas para ser agendadas en tu reloj';
  @override
  String get newTodoHint => 'Escribe una nueva tarea...';
  @override
  String get addTodoButton => 'Añadir';
  @override
  String get pendingTab => 'Pendientes';
  @override
  String get completedTab => 'Completadas';
  @override
  String get scheduleTask => 'Agendar en el Reloj';
  @override
  String get emptyTodoList => '¡No tienes tareas pendientes!';
  @override
  String get emptyCompletedList => 'Aún no hay tareas completadas';
  @override
  String get clearCompletedTodos => 'Limpiar completadas';
  @override
  String get clearCompletedConfirm => '¿Deseas eliminar todas las tareas completadas?';

  @override
  String get authTitle => 'Sincronización en la Nube';
  @override
  String get authSubtitle => 'Conecta tu cuenta para respaldar tus tareas y acceder desde cualquier dispositivo.';
  @override
  String get emailLabel => 'Correo electrónico';
  @override
  String get emailHint => 'ejemplo@correo.com';
  @override
  String get passwordLabel => 'Contraseña';
  @override
  String get passwordHint => 'Mínimo 6 caracteres';
  @override
  String get signInButton => 'Iniciar Sesión';
  @override
  String get signUpButton => 'Crear Cuenta';
  @override
  String get signOutButton => 'Cerrar Sesión';
  @override
  String get syncNowButton => 'Sincronizar Ahora';
  @override
  String get syncingStatus => 'Sincronizando...';
  @override
  String get syncedStatus => 'Datos sincronizados';
  @override
  String get authSuccessMessage => 'Sesión iniciada con éxito';
  @override
  String get invalidCredentialsError => 'Error al autenticar: revisa tus credenciales';
}
