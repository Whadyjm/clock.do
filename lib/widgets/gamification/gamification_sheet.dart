import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/gamification_data.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal principal de Maestría del Tiempo (Nivel, Rachas, Logros y Estadísticas).
class GamificationSheet extends StatelessWidget {
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

      // Logros
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

                  // Grid de Medallas
                  ...gamification.achievementsList.map(
                    (ach) => _buildAchievementTile(context, ach, isDark),
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
  ) {
    final l10n = context.l10n;
    final isUnlocked = ach.isUnlocked;
    final cardBg = isDark ? const Color(0xFF1B1E32) : const Color(0xFFF9F8FF);
    final borderColor = isDark ? const Color(0xFF2A2E48) : const Color(0xFFEAE5FF);

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
                Text(
                  _getLocalizedText(context, ach.titleKey),
                  style: TextStyle(
                    color: isUnlocked
                        ? (isDark ? Colors.white : const Color(0xFF1E1B4B))
                        : (isDark ? const Color(0xFF7A809E) : const Color(0xFF8E91A6)),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getLocalizedText(context, ach.descriptionKey),
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                    fontSize: 11.5,
                  ),
                ),
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
