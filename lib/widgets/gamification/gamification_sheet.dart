import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/gamification_data.dart';
import '../../models/task_category.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal principal de Maestría del Tiempo (Nivel, Rachas, Categorías, Logros y Estadísticas).
class GamificationSheet extends StatefulWidget {
  const GamificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const GamificationSheet(),
      ),
    );
  }

  @override
  State<GamificationSheet> createState() => _GamificationSheetState();
}

class _GamificationSheetState extends State<GamificationSheet> {
  String _selectedCategoryFilter = 'all';

  String _getLocalizedText(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (key) {
      // Niveles
      case 'level1Title': return l10n.level1Title;
      case 'level2Title': return l10n.level2Title;
      case 'level3Title': return l10n.level3Title;
      case 'level4Title': return l10n.level4Title;
      case 'level5Title': return l10n.level5Title;
      case 'level6Title': return l10n.level6Title;

      // Logros Generales
      case 'badgeFirstStepTitle': return l10n.badgeFirstStepTitle;
      case 'badgeFirstStepDesc': return l10n.badgeFirstStepDesc;
      case 'badgeEarlyBirdTitle': return l10n.badgeEarlyBirdTitle;
      case 'badgeEarlyBirdDesc': return l10n.badgeEarlyBirdDesc;
      case 'badgeNightOwlTitle': return l10n.badgeNightOwlTitle;
      case 'badgeNightOwlDesc': return l10n.badgeNightOwlDesc;
      case 'badgeTaskMaster10Title': return l10n.badgeTaskMaster10Title;
      case 'badgeTaskMaster10Desc': return l10n.badgeTaskMaster10Desc;
      case 'badgeTaskMaster50Title': return l10n.badgeTaskMaster50Title;
      case 'badgeTaskMaster50Desc': return l10n.badgeTaskMaster50Desc;
      case 'badgeStreak3Title': return l10n.badgeStreak3Title;
      case 'badgeStreak3Desc': return l10n.badgeStreak3Desc;
      case 'badgeStreak7Title': return l10n.badgeStreak7Title;
      case 'badgeStreak7Desc': return l10n.badgeStreak7Desc;
      case 'badgeGoldenDialTitle': return l10n.badgeGoldenDialTitle;
      case 'badgeGoldenDialDesc': return l10n.badgeGoldenDialDesc;
      case 'badgeCleanSlateTitle': return l10n.badgeCleanSlateTitle;
      case 'badgeCleanSlateDesc': return l10n.badgeCleanSlateDesc;
      case 'badgeBalancedLifeTitle': return l10n.badgeBalancedLifeTitle;
      case 'badgeBalancedLifeDesc': return l10n.badgeBalancedLifeDesc;

      // Logros por Categoría: Trabajo
      case 'badgeWorkStarterTitle': return l10n.badgeWorkStarterTitle;
      case 'badgeWorkStarterDesc': return l10n.badgeWorkStarterDesc;
      case 'badgeWorkProTitle': return l10n.badgeWorkProTitle;
      case 'badgeWorkProDesc': return l10n.badgeWorkProDesc;
      case 'badgeWorkMasterTitle': return l10n.badgeWorkMasterTitle;
      case 'badgeWorkMasterDesc': return l10n.badgeWorkMasterDesc;

      // Logros por Categoría: Salud
      case 'badgeHealthSparkTitle': return l10n.badgeHealthSparkTitle;
      case 'badgeHealthSparkDesc': return l10n.badgeHealthSparkDesc;
      case 'badgeHealthVitalityTitle': return l10n.badgeHealthVitalityTitle;
      case 'badgeHealthVitalityDesc': return l10n.badgeHealthVitalityDesc;
      case 'badgeHealthZenTitle': return l10n.badgeHealthZenTitle;
      case 'badgeHealthZenDesc': return l10n.badgeHealthZenDesc;

      // Logros por Categoría: Enfoque
      case 'badgeLearningSparkTitle': return l10n.badgeLearningSparkTitle;
      case 'badgeLearningSparkDesc': return l10n.badgeLearningSparkDesc;
      case 'badgeLearningDeepTitle': return l10n.badgeLearningDeepTitle;
      case 'badgeLearningDeepDesc': return l10n.badgeLearningDeepDesc;
      case 'badgeLearningScholarTitle': return l10n.badgeLearningScholarTitle;
      case 'badgeLearningScholarDesc': return l10n.badgeLearningScholarDesc;

      // Logros por Categoría: Personal
      case 'badgePersonalSparkTitle': return l10n.badgePersonalSparkTitle;
      case 'badgePersonalSparkDesc': return l10n.badgePersonalSparkDesc;
      case 'badgePersonalHarmonyTitle': return l10n.badgePersonalHarmonyTitle;
      case 'badgePersonalHarmonyDesc': return l10n.badgePersonalHarmonyDesc;
      case 'badgePersonalZenTitle': return l10n.badgePersonalZenTitle;
      case 'badgePersonalZenDesc': return l10n.badgePersonalZenDesc;

      // Logros por Categoría: Social
      case 'badgeSocialSparkTitle': return l10n.badgeSocialSparkTitle;
      case 'badgeSocialSparkDesc': return l10n.badgeSocialSparkDesc;
      case 'badgeSocialConnectorTitle': return l10n.badgeSocialConnectorTitle;
      case 'badgeSocialConnectorDesc': return l10n.badgeSocialConnectorDesc;
      case 'badgeSocialPillarTitle': return l10n.badgeSocialPillarTitle;
      case 'badgeSocialPillarDesc': return l10n.badgeSocialPillarDesc;

      // Sinergia
      case 'badgeCategoryPolymathTitle': return l10n.badgeCategoryPolymathTitle;
      case 'badgeCategoryPolymathDesc': return l10n.badgeCategoryPolymathDesc;

      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final gamification = provider.gamification;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF131628) : Colors.white;
    final currentLevel = gamification.currentLevel;
    final nextLevel = gamification.nextLevel;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Asa de arrastre
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2E45) : const Color(0xFFE2E4F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: currentLevel.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: currentLevel.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gamificationTitle,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          l10n.gamificationSubtitle,
                          style: const TextStyle(
                            color: Color(0xFF9E98D4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1),

            // Contenido con scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Tarjeta 1: Nivel y Ticks ───────────────────
                  _buildLevelCard(context, gamification, currentLevel, nextLevel, isDark),

                  const SizedBox(height: 16),

                  // ── Tarjeta 2: Rachas Inteligentes y Golden Dial
                  Row(
                    children: [
                      // Racha actual
                      Expanded(
                        child: _buildStreakCard(context, gamification, isDark),
                      ),
                      const SizedBox(width: 12),
                      // Golden Dial hoy
                      Expanded(
                        child: _buildGoldenDialCard(context, provider, isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Tarjeta 3: Escudos de Racha (Streak Freeze) ─
                  _buildStreakFreezeCard(context, gamification, isDark),

                  const SizedBox(height: 24),

                  // ── Sección: Maestría por Categorías ────────────
                  _buildCategoryMasterySection(context, gamification, isDark),

                  const SizedBox(height: 24),

                  // ── Sección 4: Catálogo de Medallas ────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.achievementsSectionTitle,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.unlockedBadgeCount(
                            gamification.unlockedAchievementsCount,
                            gamification.totalAchievementsCount,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Barra de Filtros por Categoría
                  _buildAchievementCategoryFilterChips(context, isDark),

                  const SizedBox(height: 12),

                  // Grid de Medallas filtradas
                  ...gamification.achievementsList
                      .where((ach) {
                        if (_selectedCategoryFilter == 'all') return true;
                        if (_selectedCategoryFilter == 'general') return ach.categoryId == null;
                        return ach.categoryId == _selectedCategoryFilter;
                      })
                      .map(
                        (ach) => _buildAchievementTile(context, ach, isDark, gamification),
                      ),

                  const SizedBox(height: 20),

                  // ── Sección 5: Estadísticas Globales ───────────
                  _buildStatsSummary(context, gamification, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tarjeta de Nivel y Barra de Experiencia
  // ──────────────────────────────────────────────

  Widget _buildLevelCard(
    BuildContext context,
    GamificationData data,
    WatchmakerLevel current,
    WatchmakerLevel? next,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: current.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono con insignia
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [current.primaryColor, current.accentColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: current.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(current.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: current.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${l10n.levelLabel} ${current.level}',
                            style: TextStyle(
                              color: current.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '🪙 ${data.ticks} ${l10n.ticksLabel}',
                          style: const TextStyle(
                            color: Color(0xFFF39C12),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLocalizedText(context, current.titleKey),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Barra de progreso de Ticks
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: data.levelProgress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF282C44) : const Color(0xFFE4E0F8),
              valueColor: AlwaysStoppedAnimation<Color>(current.primaryColor),
            ),
          ),

          const SizedBox(height: 8),

          // Texto de siguiente nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(data.levelProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF9E98D4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (next != null)
                Text(
                  '${data.ticksRemainingForNextLevel} ${l10n.ticksLabel} → ${_getLocalizedText(context, next.titleKey)}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  l10n.maxLevelReached,
                  style: const TextStyle(
                    color: Color(0xFFF1C40F),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tarjeta de Racha Actual
  // ──────────────────────────────────────────────

  Widget _buildStreakCard(
    BuildContext context,
    GamificationData data,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE17055).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFE17055),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.currentStreakLabel,
                  style: const TextStyle(
                    color: Color(0xFF9E98D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.currentStreak}',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                data.currentStreak == 1 ? l10n.dayUnit : l10n.daysUnit,
                style: const TextStyle(
                  color: Color(0xFF9E98D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.bestStreakLabel}: ${data.bestStreak} ${l10n.daysUnit}',
            style: TextStyle(
              color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tarjeta de Golden Dial (Día Dorado)
  // ──────────────────────────────────────────────

  Widget _buildGoldenDialCard(
    BuildContext context,
    ClockProvider provider,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);
    final isGolden = provider.isGoldenDialAchieved;
    final percent = (provider.dailyCompletionRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGolden ? const Color(0xFFF1C40F).withValues(alpha: 0.6) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFF1C40F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.goldenDialTodayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9E98D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: isGolden
                      ? const Color(0xFFF39C12)
                      : (isDark ? Colors.white : const Color(0xFF1E1B4B)),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              if (isGolden)
                const Text(
                  '⭐',
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.goldenDialTodayProgress(
              provider.dailyCompletedCount,
              provider.dailyTotalCount,
              percent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tarjeta de Escudo de Racha (Streak Freeze)
  // ──────────────────────────────────────────────

  Widget _buildStreakFreezeCard(
    BuildContext context,
    GamificationData data,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00CEC9),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.streakFreezeLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CEC9).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${data.streakFreezeCount} DISPONIBLE',
                        style: const TextStyle(
                          color: Color(0xFF00CEC9),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.streakFreezeDesc,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Item de Medalla en la lista
  // ──────────────────────────────────────────────

  Widget _buildAchievementTile(
    BuildContext context,
    Achievement ach,
    bool isDark,
    GamificationData data,
  ) {
    final l10n = context.l10n;
    final isUnlocked = ach.isUnlocked;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);

    TaskCategory? category;
    if (ach.categoryId != null) {
      for (final def in TaskCategory.defaultCategories) {
        if (def.id == ach.categoryId) {
          category = def;
          break;
        }
      }
    }

    int currentProgress = 0;
    if (ach.targetCount != null) {
      if (ach.categoryId != null) {
        currentProgress = data.getCompletedCountForCategory(ach.categoryId!);
      } else if (ach.id == 'category_polymath') {
        currentProgress = data.categoryCompletedTasks.values.where((c) => c >= 10).length;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked ? ach.color.withValues(alpha: 0.35) : borderColor,
        ),
      ),
      child: Row(
        children: [
          // Icono de la medalla
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? ach.color.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF25293E) : const Color(0xFFE8E7F0)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked
                    ? ach.color.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              isUnlocked ? ach.icon : Icons.lock_rounded,
              color: isUnlocked
                  ? ach.color
                  : (isDark ? const Color(0xFF606684) : const Color(0xFFA4A7BA)),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _getLocalizedText(context, ach.titleKey),
                        style: TextStyle(
                          color: isUnlocked
                              ? (isDark ? Colors.white : const Color(0xFF1E1B4B))
                              : (isDark ? const Color(0xFF7A809E) : const Color(0xFF8E91A6)),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: isUnlocked ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(category.icon, size: 10, color: category.color),
                            const SizedBox(width: 3),
                            Text(
                              category.getLocalizedName(context),
                              style: TextStyle(
                                color: category.color,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getLocalizedText(context, ach.descriptionKey),
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                    fontSize: 11.5,
                  ),
                ),
                if (!isUnlocked && ach.targetCount != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (currentProgress / ach.targetCount!).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: isDark ? const Color(0xFF25293E) : const Color(0xFFE8E7F0),
                            valueColor: AlwaysStoppedAnimation<Color>(ach.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.categoryProgressText(currentProgress.clamp(0, ach.targetCount!), ach.targetCount!),
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF7D83A4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isUnlocked && ach.unlockedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.badgeUnlockedAt(DateFormat('d MMM yyyy').format(ach.unlockedAt!.toLocal())),
                    style: TextStyle(
                      color: ach.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Puntos recompensa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFF1C40F).withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF222538) : const Color(0xFFEEEEF5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${ach.pointsReward}',
              style: TextStyle(
                color: isUnlocked
                    ? const Color(0xFFF39C12)
                    : (isDark ? const Color(0xFF606684) : const Color(0xFFA4A7BA)),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sección: Maestría por Categorías
  // ──────────────────────────────────────────────

  Widget _buildCategoryMasterySection(
    BuildContext context,
    GamificationData data,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final mainCategories = TaskCategory.defaultCategories
        .where((c) => c.id != 'none')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: Color(0xFF6C5CE7),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.categoryMasteryTitle,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.categoryMasterySubtitle,
          style: TextStyle(
            color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // Carrusel horizontal de tarjetas de categoría
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mainCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = mainCategories[index];
              return _buildCategoryMasteryCard(context, cat, data, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMasteryCard(
    BuildContext context,
    TaskCategory cat,
    GamificationData data,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final count = data.getCompletedCountForCategory(cat.id);
    final minutes = data.getFocusMinutesForCategory(cat.id);
    final isSelected = _selectedCategoryFilter == cat.id;

    // Calcular nivel y próxima meta
    int level = 0;
    int nextTarget = 5;
    if (count >= 50) {
      level = 3;
      nextTarget = 50;
    } else if (count >= 20) {
      level = 2;
      nextTarget = 50;
    } else if (count >= 5) {
      level = 1;
      nextTarget = 20;
    } else {
      level = 0;
      nextTarget = 5;
    }

    final double progress = (count / nextTarget).clamp(0.0, 1.0);
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isSelected
        ? cat.color
        : (isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF));

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryFilter = isSelected ? 'all' : cat.id;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cabecera: Icono y Nivel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.categoryBadgeLevel(level),
                    style: TextStyle(
                      color: cat.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // Nombre y métricas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.getLocalizedName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.categoryTasksCount(count)} • ${l10n.categoryMinutesCount(minutes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF7A809E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Barra de progreso hacia la siguiente recompensa
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.5,
                    backgroundColor: isDark ? const Color(0xFF282C44) : const Color(0xFFE8E7F0),
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      count >= 50
                          ? '100%'
                          : l10n.categoryProgressText(count, nextTarget),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF7D83A4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, size: 12, color: cat.color),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtros de Categoría para Medallas ────────────

  Widget _buildAchievementCategoryFilterChips(BuildContext context, bool isDark) {
    final l10n = context.l10n;
    final filters = <Map<String, dynamic>>[
      {'id': 'all', 'label': l10n.filterAllCategoriesBadge, 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF6C5CE7)},
      {'id': 'work', 'label': TaskCategory.work.getLocalizedName(context), 'icon': TaskCategory.work.icon, 'color': TaskCategory.work.color},
      {'id': 'health', 'label': TaskCategory.health.getLocalizedName(context), 'icon': TaskCategory.health.icon, 'color': TaskCategory.health.color},
      {'id': 'learning', 'label': TaskCategory.learning.getLocalizedName(context), 'icon': TaskCategory.learning.icon, 'color': TaskCategory.learning.color},
      {'id': 'personal', 'label': TaskCategory.personal.getLocalizedName(context), 'icon': TaskCategory.personal.icon, 'color': TaskCategory.personal.color},
      {'id': 'social', 'label': TaskCategory.social.getLocalizedName(context), 'icon': TaskCategory.social.icon, 'color': TaskCategory.social.color},
      {'id': 'general', 'label': l10n.filterGeneralBadge, 'icon': Icons.stars_rounded, 'color': const Color(0xFF747D8C)},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedCategoryFilter == f['id'];
          final Color color = f['color'] as Color;

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryFilter = f['id'] as String;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.18)
                    : (isDark ? const Color(0xFF1F2338) : const Color(0xFFF1F0F7)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 14,
                    color: isSelected ? color : (isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.white : color)
                          : (isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194)),
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Resumen de Estadísticas Globales
  // ──────────────────────────────────────────────

  Widget _buildStatsSummary(
    BuildContext context,
    GamificationData data,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final hours = (data.totalFocusMinutes / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsSectionTitle,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF00B894),
                  value: '${data.totalCompletedTasks}',
                  label: l10n.tasksCompletedStat,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.timelapse_rounded,
                  color: const Color(0xFF0984E3),
                  value: '${hours}h',
                  label: l10n.focusMinutesStat,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9E98D4),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
