import 'package:flutter/material.dart';

/// Niveles de Maestría Temporal inspirados en la relojería y el dominio del tiempo.
class WatchmakerLevel {
  final int level;
  final String titleKey;
  final int minTicks;
  final int maxTicks; // Ticks necesarios para el siguiente nivel (o límite de este)
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;

  const WatchmakerLevel({
    required this.level,
    required this.titleKey,
    required this.minTicks,
    required this.maxTicks,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
  });

  static const List<WatchmakerLevel> allLevels = [
    WatchmakerLevel(
      level: 1,
      titleKey: 'level1Title', // Aprendiz de Relojero
      minTicks: 0,
      maxTicks: 100,
      icon: Icons.handyman_rounded,
      primaryColor: Color(0xFF6C5CE7),
      accentColor: Color(0xFFA29BFE),
    ),
    WatchmakerLevel(
      level: 2,
      titleKey: 'level2Title', // Oficial de Rueda
      minTicks: 100,
      maxTicks: 250,
      icon: Icons.settings_suggest_rounded,
      primaryColor: Color(0xFF00CEC9),
      accentColor: Color(0xFF81ECEC),
    ),
    WatchmakerLevel(
      level: 3,
      titleKey: 'level3Title', // Afinador de Cuarzo
      minTicks: 250,
      maxTicks: 500,
      icon: Icons.diamond_rounded,
      primaryColor: Color(0xFF0984E3),
      accentColor: Color(0xFF74B9FF),
    ),
    WatchmakerLevel(
      level: 4,
      titleKey: 'level4Title', // Guardián del Péndulo
      minTicks: 500,
      maxTicks: 1000,
      icon: Icons.hourglass_full_rounded,
      primaryColor: Color(0xFFE17055),
      accentColor: Color(0xFFFAB1A0),
    ),
    WatchmakerLevel(
      level: 5,
      titleKey: 'level5Title', // Crononauta
      minTicks: 1000,
      maxTicks: 2000,
      icon: Icons.auto_awesome_rounded,
      primaryColor: Color(0xFFFD79A8),
      accentColor: Color(0xFFFF7675),
    ),
    WatchmakerLevel(
      level: 6,
      titleKey: 'level6Title', // Gran Maestro del Tiempo
      minTicks: 2000,
      maxTicks: 5000,
      icon: Icons.workspace_premium_rounded,
      primaryColor: Color(0xFFF1C40F),
      accentColor: Color(0xFFFFEAA7),
    ),
  ];

  static WatchmakerLevel fromTicks(int ticks) {
    for (int i = allLevels.length - 1; i >= 0; i--) {
      if (ticks >= allLevels[i].minTicks) {
        return allLevels[i];
      }
    }
    return allLevels.first;
  }
}

/// Definición de una Medalla / Logro de Productividad.
class Achievement {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Color color;
  final int pointsReward;
  final DateTime? unlockedAt;
  final String? categoryId; // ID de la categoría asociada (ej: 'work', 'health', etc.)
  final int? targetCount; // Meta requerida para desbloquearlo

  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
    required this.pointsReward,
    this.unlockedAt,
    this.categoryId,
    this.targetCount,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      icon: icon,
      color: color,
      pointsReward: pointsReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      categoryId: categoryId,
      targetCount: targetCount,
    );
  }

  static const List<Achievement> catalog = [
    // ── Logros Generales de Productividad ──
    Achievement(
      id: 'first_step',
      titleKey: 'badgeFirstStepTitle',
      descriptionKey: 'badgeFirstStepDesc',
      icon: Icons.flag_rounded,
      color: Color(0xFF6C5CE7),
      pointsReward: 25,
    ),
    Achievement(
      id: 'early_bird',
      titleKey: 'badgeEarlyBirdTitle',
      descriptionKey: 'badgeEarlyBirdDesc',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF39C12),
      pointsReward: 30,
    ),
    Achievement(
      id: 'night_owl',
      titleKey: 'badgeNightOwlTitle',
      descriptionKey: 'badgeNightOwlDesc',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF34495E),
      pointsReward: 30,
    ),
    Achievement(
      id: 'task_master_10',
      titleKey: 'badgeTaskMaster10Title',
      descriptionKey: 'badgeTaskMaster10Desc',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF00CEC9),
      pointsReward: 50,
    ),
    Achievement(
      id: 'task_master_50',
      titleKey: 'badgeTaskMaster50Title',
      descriptionKey: 'badgeTaskMaster50Desc',
      icon: Icons.shield_rounded,
      color: Color(0xFF0984E3),
      pointsReward: 100,
    ),
    Achievement(
      id: 'streak_3',
      titleKey: 'badgeStreak3Title',
      descriptionKey: 'badgeStreak3Desc',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE17055),
      pointsReward: 40,
    ),
    Achievement(
      id: 'streak_7',
      titleKey: 'badgeStreak7Title',
      descriptionKey: 'badgeStreak7Desc',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF1C40F),
      pointsReward: 80,
    ),
    Achievement(
      id: 'golden_dial',
      titleKey: 'badgeGoldenDialTitle',
      descriptionKey: 'badgeGoldenDialDesc',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFB300),
      pointsReward: 50,
    ),
    Achievement(
      id: 'clean_slate',
      titleKey: 'badgeCleanSlateTitle',
      descriptionKey: 'badgeCleanSlateDesc',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF00B894),
      pointsReward: 35,
    ),
    Achievement(
      id: 'balanced_life',
      titleKey: 'badgeBalancedLifeTitle',
      descriptionKey: 'badgeBalancedLifeDesc',
      icon: Icons.balance_rounded,
      color: Color(0xFF9B59B6),
      pointsReward: 45,
    ),

    // ── Recompensas de Categoría: Trabajo (Work) ──
    Achievement(
      id: 'work_starter',
      titleKey: 'badgeWorkStarterTitle',
      descriptionKey: 'badgeWorkStarterDesc',
      icon: Icons.work_outline_rounded,
      color: Color(0xFFFED330),
      pointsReward: 30,
      categoryId: 'work',
      targetCount: 5,
    ),
    Achievement(
      id: 'work_pro',
      titleKey: 'badgeWorkProTitle',
      descriptionKey: 'badgeWorkProDesc',
      icon: Icons.business_center_rounded,
      color: Color(0xFFF39C12),
      pointsReward: 60,
      categoryId: 'work',
      targetCount: 20,
    ),
    Achievement(
      id: 'work_master',
      titleKey: 'badgeWorkMasterTitle',
      descriptionKey: 'badgeWorkMasterDesc',
      icon: Icons.domain_rounded,
      color: Color(0xFFE67E22),
      pointsReward: 120,
      categoryId: 'work',
      targetCount: 50,
    ),

    // ── Recompensas de Categoría: Salud (Health) ──
    Achievement(
      id: 'health_spark',
      titleKey: 'badgeHealthSparkTitle',
      descriptionKey: 'badgeHealthSparkDesc',
      icon: Icons.spa_outlined,
      color: Color(0xFF2ED573),
      pointsReward: 30,
      categoryId: 'health',
      targetCount: 5,
    ),
    Achievement(
      id: 'health_vitality',
      titleKey: 'badgeHealthVitalityTitle',
      descriptionKey: 'badgeHealthVitalityDesc',
      icon: Icons.favorite_outline_rounded,
      color: Color(0xFF00B894),
      pointsReward: 60,
      categoryId: 'health',
      targetCount: 20,
    ),
    Achievement(
      id: 'health_zen',
      titleKey: 'badgeHealthZenTitle',
      descriptionKey: 'badgeHealthZenDesc',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF10AC84),
      pointsReward: 120,
      categoryId: 'health',
      targetCount: 50,
    ),

    // ── Recompensas de Categoría: Enfoque / Estudio (Learning) ──
    Achievement(
      id: 'learning_spark',
      titleKey: 'badgeLearningSparkTitle',
      descriptionKey: 'badgeLearningSparkDesc',
      icon: Icons.lightbulb_outline_rounded,
      color: Color(0xFF70A1FF),
      pointsReward: 30,
      categoryId: 'learning',
      targetCount: 5,
    ),
    Achievement(
      id: 'learning_deep',
      titleKey: 'badgeLearningDeepTitle',
      descriptionKey: 'badgeLearningDeepDesc',
      icon: Icons.psychology_rounded,
      color: Color(0xFF1E90FF),
      pointsReward: 60,
      categoryId: 'learning',
      targetCount: 20,
    ),
    Achievement(
      id: 'learning_scholar',
      titleKey: 'badgeLearningScholarTitle',
      descriptionKey: 'badgeLearningScholarDesc',
      icon: Icons.school_rounded,
      color: Color(0xFF3742FA),
      pointsReward: 120,
      categoryId: 'learning',
      targetCount: 50,
    ),

    // ── Recompensas de Categoría: Personal ──
    Achievement(
      id: 'personal_spark',
      titleKey: 'badgePersonalSparkTitle',
      descriptionKey: 'badgePersonalSparkDesc',
      icon: Icons.person_outline_rounded,
      color: Color(0xFFFF6B81),
      pointsReward: 30,
      categoryId: 'personal',
      targetCount: 5,
    ),
    Achievement(
      id: 'personal_harmony',
      titleKey: 'badgePersonalHarmonyTitle',
      descriptionKey: 'badgePersonalHarmonyDesc',
      icon: Icons.sentiment_very_satisfied_rounded,
      color: Color(0xFFFF4757),
      pointsReward: 60,
      categoryId: 'personal',
      targetCount: 20,
    ),
    Achievement(
      id: 'personal_zen',
      titleKey: 'badgePersonalZenTitle',
      descriptionKey: 'badgePersonalZenDesc',
      icon: Icons.yard_rounded,
      color: Color(0xFFED4C67),
      pointsReward: 120,
      categoryId: 'personal',
      targetCount: 50,
    ),

    // ── Recompensas de Categoría: Social ──
    Achievement(
      id: 'social_spark',
      titleKey: 'badgeSocialSparkTitle',
      descriptionKey: 'badgeSocialSparkDesc',
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFFA55EEA),
      pointsReward: 30,
      categoryId: 'social',
      targetCount: 5,
    ),
    Achievement(
      id: 'social_connector',
      titleKey: 'badgeSocialConnectorTitle',
      descriptionKey: 'badgeSocialConnectorDesc',
      icon: Icons.groups_rounded,
      color: Color(0xFF8854D0),
      pointsReward: 60,
      categoryId: 'social',
      targetCount: 20,
    ),
    Achievement(
      id: 'social_pillar',
      titleKey: 'badgeSocialPillarTitle',
      descriptionKey: 'badgeSocialPillarDesc',
      icon: Icons.diversity_3_rounded,
      color: Color(0xFF5F27CD),
      pointsReward: 120,
      categoryId: 'social',
      targetCount: 50,
    ),

    // ── Sinergia Multicategoría ──
    Achievement(
      id: 'category_polymath',
      titleKey: 'badgeCategoryPolymathTitle',
      descriptionKey: 'badgeCategoryPolymathDesc',
      icon: Icons.all_inclusive_rounded,
      color: Color(0xFF00CEC9),
      pointsReward: 150,
      targetCount: 4,
    ),
  ];
}

/// Estado global de la gamificación del usuario (Ticks, Rachas, Logros y Estadísticas por Categoría).
class GamificationData {
  final int ticks;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastActiveDate;
  final int streakFreezeCount;
  final int totalCompletedTasks;
  final int totalFocusMinutes;
  final Map<String, DateTime> unlockedAchievements;
  final Map<String, int> categoryCompletedTasks;
  final Map<String, int> categoryFocusMinutes;

  const GamificationData({
    this.ticks = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastActiveDate,
    this.streakFreezeCount = 1,
    this.totalCompletedTasks = 0,
    this.totalFocusMinutes = 0,
    this.unlockedAchievements = const {},
    this.categoryCompletedTasks = const {},
    this.categoryFocusMinutes = const {},
  });

  /// Nivel actual basado en los Ticks acumulados
  WatchmakerLevel get currentLevel => WatchmakerLevel.fromTicks(ticks);

  /// Siguiente nivel (o actual si está en el tope)
  WatchmakerLevel? get nextLevel {
    final cur = currentLevel;
    final nextIdx = WatchmakerLevel.allLevels.indexWhere((l) => l.level == cur.level) + 1;
    if (nextIdx < WatchmakerLevel.allLevels.length) {
      return WatchmakerLevel.allLevels[nextIdx];
    }
    return null;
  }

  /// Porcentaje de progreso dentro del nivel actual (0.0 a 1.0)
  double get levelProgress {
    final cur = currentLevel;
    final span = cur.maxTicks - cur.minTicks;
    if (span <= 0) return 1.0;
    final progress = (ticks - cur.minTicks) / span;
    return progress.clamp(0.0, 1.0);
  }

  /// Ticks que faltan para alcanzar el siguiente nivel
  int get ticksRemainingForNextLevel {
    final cur = currentLevel;
    if (ticks >= cur.maxTicks) return 0;
    return cur.maxTicks - ticks;
  }

  /// Lista de logros con estado actualizado según los desbloqueados
  List<Achievement> get achievementsList {
    return Achievement.catalog.map((base) {
      final unlockedAt = unlockedAchievements[base.id];
      return base.copyWith(unlockedAt: unlockedAt);
    }).toList();
  }

  int get unlockedAchievementsCount => unlockedAchievements.length;
  int get totalAchievementsCount => Achievement.catalog.length;

  /// Retorna la cantidad de tareas completadas para una categoría dada
  int getCompletedCountForCategory(String categoryId) =>
      categoryCompletedTasks[categoryId] ?? 0;

  /// Retorna los minutos dedicados a una categoría dada
  int getFocusMinutesForCategory(String categoryId) =>
      categoryFocusMinutes[categoryId] ?? 0;

  /// Retorna la lista de logros asociados a una categoría específica (o generales si categoryId == null)
  List<Achievement> getAchievementsForCategory(String? categoryId) {
    return achievementsList.where((a) => a.categoryId == categoryId).toList();
  }

  GamificationData copyWith({
    int? ticks,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastActiveDate,
    int? streakFreezeCount,
    int? totalCompletedTasks,
    int? totalFocusMinutes,
    Map<String, DateTime>? unlockedAchievements,
    Map<String, int>? categoryCompletedTasks,
    Map<String, int>? categoryFocusMinutes,
  }) {
    return GamificationData(
      ticks: ticks ?? this.ticks,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakFreezeCount: streakFreezeCount ?? this.streakFreezeCount,
      totalCompletedTasks: totalCompletedTasks ?? this.totalCompletedTasks,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      categoryCompletedTasks:
          categoryCompletedTasks ?? this.categoryCompletedTasks,
      categoryFocusMinutes: categoryFocusMinutes ?? this.categoryFocusMinutes,
    );
  }

  // ── Serialización Local (JSON) ─────────────────────────────

  Map<String, dynamic> toJson() {
    final achievementsMap = <String, String>{};
    unlockedAchievements.forEach((key, val) {
      achievementsMap[key] = val.toUtc().toIso8601String();
    });

    return {
      'ticks': ticks,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'streakFreezeCount': streakFreezeCount,
      'totalCompletedTasks': totalCompletedTasks,
      'totalFocusMinutes': totalFocusMinutes,
      'unlockedAchievements': achievementsMap,
      'categoryCompletedTasks': categoryCompletedTasks,
      'categoryFocusMinutes': categoryFocusMinutes,
    };
  }

  factory GamificationData.fromJson(Map<String, dynamic> json) {
    final achRaw = json['unlockedAchievements'];
    final achMap = <String, DateTime>{};
    if (achRaw is Map) {
      achRaw.forEach((k, v) {
        if (v is String) {
          final dt = DateTime.tryParse(v);
          if (dt != null) achMap[k.toString()] = dt;
        }
      });
    }

    final catTasksRaw = json['categoryCompletedTasks'];
    final catTasksMap = <String, int>{};
    if (catTasksRaw is Map) {
      catTasksRaw.forEach((k, v) {
        if (v is num) catTasksMap[k.toString()] = v.toInt();
      });
    }

    final catMinRaw = json['categoryFocusMinutes'];
    final catMinMap = <String, int>{};
    if (catMinRaw is Map) {
      catMinRaw.forEach((k, v) {
        if (v is num) catMinMap[k.toString()] = v.toInt();
      });
    }

    return GamificationData(
      ticks: (json['ticks'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'] as String)
          : null,
      streakFreezeCount: (json['streakFreezeCount'] as num?)?.toInt() ?? 1,
      totalCompletedTasks: (json['totalCompletedTasks'] as num?)?.toInt() ?? 0,
      totalFocusMinutes: (json['totalFocusMinutes'] as num?)?.toInt() ?? 0,
      unlockedAchievements: achMap,
      categoryCompletedTasks: catTasksMap,
      categoryFocusMinutes: catMinMap,
    );
  }

  // ── Serialización Supabase (PostgreSQL / JSONB) ────────────

  Map<String, dynamic> toSupabaseMap() {
    final achievementsList = unlockedAchievements.entries.map((e) => {
      'id': e.key,
      'unlocked_at': e.value.toUtc().toIso8601String(),
    }).toList();

    return {
      'ticks': ticks,
      'level': currentLevel.level,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_active_date': lastActiveDate != null
          ? "${lastActiveDate!.year.toString().padLeft(4, '0')}-${lastActiveDate!.month.toString().padLeft(2, '0')}-${lastActiveDate!.day.toString().padLeft(2, '0')}"
          : null,
      'streak_freeze_count': streakFreezeCount,
      'total_completed_tasks': totalCompletedTasks,
      'total_focus_minutes': totalFocusMinutes,
      'unlocked_achievements': achievementsList,
      'category_stats': {
        'tasks': categoryCompletedTasks,
        'minutes': categoryFocusMinutes,
      },
    };
  }

  factory GamificationData.fromSupabaseMap(Map<String, dynamic> map) {
    final achMap = <String, DateTime>{};
    final achRaw = map['unlocked_achievements'];
    if (achRaw is List) {
      for (final item in achRaw) {
        if (item is Map && item['id'] != null && item['unlocked_at'] != null) {
          final dt = DateTime.tryParse(item['unlocked_at'].toString());
          if (dt != null) {
            achMap[item['id'].toString()] = dt;
          }
        }
      }
    }

    DateTime? parsedDate;
    if (map['last_active_date'] != null) {
      parsedDate = DateTime.tryParse(map['last_active_date'].toString());
    }

    final catStatsRaw = map['category_stats'];
    final catTasksMap = <String, int>{};
    final catMinMap = <String, int>{};
    if (catStatsRaw is Map) {
      final tasks = catStatsRaw['tasks'];
      if (tasks is Map) {
        tasks.forEach((k, v) {
          if (v is num) catTasksMap[k.toString()] = v.toInt();
        });
      }
      final mins = catStatsRaw['minutes'];
      if (mins is Map) {
        mins.forEach((k, v) {
          if (v is num) catMinMap[k.toString()] = v.toInt();
        });
      }
    }

    return GamificationData(
      ticks: (map['ticks'] as num?)?.toInt() ?? 0,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['best_streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: parsedDate,
      streakFreezeCount: (map['streak_freeze_count'] as num?)?.toInt() ?? 1,
      totalCompletedTasks: (map['total_completed_tasks'] as num?)?.toInt() ?? 0,
      totalFocusMinutes: (map['total_focus_minutes'] as num?)?.toInt() ?? 0,
      unlockedAchievements: achMap,
      categoryCompletedTasks: catTasksMap,
      categoryFocusMinutes: catMinMap,
    );
  }
}
