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
  String get taskTypeLabel => 'Tipo de Tarea';
  @override
  String get timeRangeOption => 'Rango de tiempo';
  @override
  String get pointTaskOption => 'Tarea puntual (sin fin)';
  @override
  String get pointTaskTimeLabel => 'Hora de la Tarea';
  @override
  String get pointTaskBadge => 'Puntual';
  @override
  String get pointTaskHint => 'Marca un momento específico del día sin hora de término';
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
  @override
  String get forgotPasswordTitle => 'Recuperar Contraseña';
  @override
  String get forgotPasswordSubtitle => 'Ingresa tu correo electrónico para recibir un código OTP y las instrucciones para restablecer tu contraseña.';
  @override
  String get sendRecoveryEmailButton => 'Enviar Código de Recuperación';
  @override
  String get resetPasswordTitle => 'Restablecer Contraseña';
  @override
  String get resetPasswordSubtitle => 'Ingresa el código OTP de 8 dígitos que enviamos a tu correo y define tu nueva contraseña.';
  @override
  String get otpCodeLabel => 'Código OTP (8 dígitos)';
  @override
  String get otpCodeHint => 'Ej: 123456';
  @override
  String get newPasswordLabel => 'Nueva Contraseña';
  @override
  String get newPasswordHint => 'Mínimo 6 caracteres';
  @override
  String get confirmNewPasswordLabel => 'Confirmar Nueva Contraseña';
  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';
  @override
  String get resetPasswordButton => 'Restablecer Contraseña';
  @override
  String get passwordResetSuccess => '¡Contraseña actualizada con éxito!';
  @override
  String get changePasswordButton => 'Cambiar Contraseña';
  @override
  String get changePasswordTitle => 'Actualizar Contraseña';
  @override
  String get alreadyHaveOtp => '¿Ya tienes un código? Ingrésalo aquí';
  @override
  String get backToSignIn => 'Volver a Iniciar Sesión';
  @override
  String get resendOtp => '¿No recibiste el código? Reenviar';
  @override
  String get recoveryEmailSent => 'Código enviado a tu correo. Revisa tu bandeja de entrada.';

  @override
  String get viewOnboardingOption => 'Ver Guía de Bienvenida';
  @override
  String get onboardingSkip => 'Saltar';
  @override
  String get onboardingNext => 'Siguiente';
  @override
  String get onboardingGetStarted => '¡Comenzar Ahora! 🚀';

  @override
  String get onboardingStep1Badge => '⏱️ INNOVACIÓN RADIAL';
  @override
  String get onboardingStep1Title => 'Tu Tiempo en una Nueva Dimensión';
  @override
  String get onboardingStep1Desc => 'Despídete de las listas lineales aburridas. Visualiza y domina todo tu día en un hermoso reloj circular interactivo.';

  @override
  String get onboardingStep2Badge => '🎯 ENFOQUE TOTAL';
  @override
  String get onboardingStep2Title => 'Planifica al Instante con un Toque';
  @override
  String get onboardingStep2Desc => 'Arrastra sobre el dial para agendar tareas o guarda tus pendientes en el backlog listos para ser programados.';

  @override
  String get onboardingStep3Badge => '🔔 SINCRONIZADO & SEGURO';
  @override
  String get onboardingStep3Title => 'Puntualidad Absoluta y en la Nube';
  @override
  String get onboardingStep3Desc => 'Alertas inteligentes con anticipación personalizada y respaldo automático en la nube para no perder nada jamás.';

  @override
  String get onboardingStep4Badge => '✨ TODO LISTO';
  @override
  String get onboardingStep4Title => 'Bienvenido a Clock.Do';
  @override
  String get onboardingStep4Desc => 'Tu día organizado, tus metas alcanzadas y tu tiempo bajo control absoluto. ¡Es hora de comenzar!';

  // ── Gamificación & Maestría del Tiempo (ES) ──
  @override
  String get gamificationTitle => 'Maestría del Tiempo';
  @override
  String get gamificationSubtitle => 'Tu progreso, rachas y logros de productividad';
  @override
  String get ticksLabel => 'Ticks';
  @override
  String get currentStreakLabel => 'Racha Actual';
  @override
  String get bestStreakLabel => 'Mejor Racha';
  @override
  String get daysUnit => 'días';
  @override
  String get dayUnit => 'día';
  @override
  String get streakFreezeLabel => 'Escudos de Racha';
  @override
  String get streakFreezeDesc => 'Protegen tu racha automáticamente si te tomas un día de descanso';
  @override
  String get levelLabel => 'Nivel';
  @override
  String get levelProgressLabel => 'Progreso de Nivel';
  @override
  String get nextLevelLabel => 'Siguiente Nivel';
  @override
  String get maxLevelReached => '¡Nivel Máximo de Maestría Alcanzado!';
  @override
  String get achievementsSectionTitle => 'Medallas de Logros';
  @override
  String unlockedBadgeCount(int unlocked, int total) => '$unlocked de $total desbloqueadas';
  @override
  String get statsSectionTitle => 'Estadísticas Globales';
  @override
  String get tasksCompletedStat => 'Bloques Completados';
  @override
  String get focusMinutesStat => 'Minutos de Enfoque';
  @override
  String get goldenDialTodayTitle => 'Día Dorado (Golden Dial)';
  @override
  String get goldenDialTodayActive => '¡Esfera dorada conseguida hoy! 🎉';
  @override
  String goldenDialTodayProgress(int completed, int total, int percent) => '$completed de $total bloques ($percent%)';
  @override
  String get streakFreezeUsedToast => '🛡️ ¡Escudo de Racha activado! Tu racha sigue intacta.';
  @override
  String levelUpCelebration(String levelName) => '¡Subiste de nivel! Ahora eres $levelName';
  @override
  String badgeUnlockedCelebration(String badgeName) => '¡Nueva medalla desbloqueada: $badgeName!';
  @override
  String badgeUnlockedAt(String dateStr) => 'Desbloqueado el $dateStr';
  @override
  String get badgeLocked => 'Bloqueado';
  @override
  String get claimReward => '¡Reclamar!';
  @override
  String get awesomeButton => '¡Genial!';

  // Niveles
  @override
  String get level1Title => 'Aprendiz de Relojero';
  @override
  String get level2Title => 'Oficial de Rueda';
  @override
  String get level3Title => 'Afinador de Cuarzo';
  @override
  String get level4Title => 'Guardián del Péndulo';
  @override
  String get level5Title => 'Crononauta';
  @override
  String get level6Title => 'Gran Maestro del Tiempo';

  // Logros
  @override
  String get badgeFirstStepTitle => 'Primer Paso';
  @override
  String get badgeFirstStepDesc => 'Completa tu primer bloque de tiempo en el reloj';
  @override
  String get badgeEarlyBirdTitle => 'Madrugador';
  @override
  String get badgeEarlyBirdDesc => 'Completa un bloque antes de las 8:00 AM';
  @override
  String get badgeNightOwlTitle => 'Búho Nocturno';
  @override
  String get badgeNightOwlDesc => 'Completa un bloque después de las 9:00 PM';
  @override
  String get badgeTaskMaster10Title => 'Enfoque Constante';
  @override
  String get badgeTaskMaster10Desc => 'Completa 10 bloques de tiempo en el reloj';
  @override
  String get badgeTaskMaster50Title => 'Maestro de la Rutina';
  @override
  String get badgeTaskMaster50Desc => 'Completa 50 bloques de tiempo';
  @override
  String get badgeStreak3Title => 'Chispa Inicial';
  @override
  String get badgeStreak3Desc => 'Mantén una racha de 3 días consecutivos';
  @override
  String get badgeStreak7Title => 'Hábito de Acero';
  @override
  String get badgeStreak7Desc => 'Alcanza una racha de 7 días seguidos';
  @override
  String get badgeGoldenDialTitle => 'Día Dorado';
  @override
  String get badgeGoldenDialDesc => 'Completa el 80% o más de tus tareas en un día (mínimo 3 bloques)';
  @override
  String get badgeCleanSlateTitle => 'Mesa Limpia';
  @override
  String get badgeCleanSlateDesc => 'Completa 5 tareas pendientes del Backlog ToDo';
  @override
  String get badgeBalancedLifeTitle => 'Vida Equilibrada';
  @override
  String get badgeBalancedLifeDesc => 'Completa bloques de al menos 3 categorías distintas en un día';
}
