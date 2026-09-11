import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gamification_data.dart';
import '../../l10n/app_localizations.dart';

/// Modal o diálogo de celebración cuando se desbloquea un logro o se sube de nivel.
class AchievementCelebrationDialog extends StatefulWidget {
  final Achievement? achievement;
  final WatchmakerLevel? levelUp;

  const AchievementCelebrationDialog({
    super.key,
    this.achievement,
    this.levelUp,
  }) : assert(achievement != null || levelUp != null);

  static Future<void> showAchievement(BuildContext context, Achievement achievement) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AchievementCelebrationDialog(achievement: achievement),
    );
  }

  static Future<void> showLevelUp(BuildContext context, WatchmakerLevel level) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AchievementCelebrationDialog(levelUp: level),
    );
  }

  @override
  State<AchievementCelebrationDialog> createState() =>
      _AchievementCelebrationDialogState();
}

class _AchievementCelebrationDialogState
    extends State<AchievementCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _glow = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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

      // Trabajo
      case 'badgeWorkStarterTitle': return l10n.badgeWorkStarterTitle;
      case 'badgeWorkStarterDesc': return l10n.badgeWorkStarterDesc;
      case 'badgeWorkProTitle': return l10n.badgeWorkProTitle;
      case 'badgeWorkProDesc': return l10n.badgeWorkProDesc;
      case 'badgeWorkMasterTitle': return l10n.badgeWorkMasterTitle;
      case 'badgeWorkMasterDesc': return l10n.badgeWorkMasterDesc;

      // Salud
      case 'badgeHealthSparkTitle': return l10n.badgeHealthSparkTitle;
      case 'badgeHealthSparkDesc': return l10n.badgeHealthSparkDesc;
      case 'badgeHealthVitalityTitle': return l10n.badgeHealthVitalityTitle;
      case 'badgeHealthVitalityDesc': return l10n.badgeHealthVitalityDesc;
      case 'badgeHealthZenTitle': return l10n.badgeHealthZenTitle;
      case 'badgeHealthZenDesc': return l10n.badgeHealthZenDesc;

      // Enfoque
      case 'badgeLearningSparkTitle': return l10n.badgeLearningSparkTitle;
      case 'badgeLearningSparkDesc': return l10n.badgeLearningSparkDesc;
      case 'badgeLearningDeepTitle': return l10n.badgeLearningDeepTitle;
      case 'badgeLearningDeepDesc': return l10n.badgeLearningDeepDesc;
      case 'badgeLearningScholarTitle': return l10n.badgeLearningScholarTitle;
      case 'badgeLearningScholarDesc': return l10n.badgeLearningScholarDesc;

      // Personal
      case 'badgePersonalSparkTitle': return l10n.badgePersonalSparkTitle;
      case 'badgePersonalSparkDesc': return l10n.badgePersonalSparkDesc;
      case 'badgePersonalHarmonyTitle': return l10n.badgePersonalHarmonyTitle;
      case 'badgePersonalHarmonyDesc': return l10n.badgePersonalHarmonyDesc;
      case 'badgePersonalZenTitle': return l10n.badgePersonalZenTitle;
      case 'badgePersonalZenDesc': return l10n.badgePersonalZenDesc;

      // Social
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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLevelUp = widget.levelUp != null;

    final color = isLevelUp
        ? widget.levelUp!.primaryColor
        : widget.achievement!.color;
    final icon = isLevelUp
        ? widget.levelUp!.icon
        : widget.achievement!.icon;
    final title = isLevelUp
        ? l10n.levelUpCelebration(_getLocalizedText(context, widget.levelUp!.titleKey))
        : l10n.badgeUnlockedCelebration(_getLocalizedText(context, widget.achievement!.titleKey));
    final desc = isLevelUp
        ? '${l10n.levelLabel} ${widget.levelUp!.level}'
        : _getLocalizedText(context, widget.achievement!.descriptionKey);
    final rewardText = isLevelUp
        ? null
        : '+${widget.achievement!.pointsReward} ${l10n.ticksLabel} 🪙';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E32) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Aura y contenedor del Icono
              AnimatedBuilder(
                animation: _glow,
                builder: (_, child) => Transform.scale(
                  scale: _glow.value,
                  child: child,
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.3),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título de celebración
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Descripción
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFA5ABC4) : const Color(0xFF6B7194),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),

              // Recompensa de Ticks
              if (rewardText != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF1C40F).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    rewardText,
                    style: const TextStyle(
                      color: Color(0xFFF39C12),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón de confirmación / cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangle600(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    l10n.awesomeButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper para bordes redondeados
class RoundedRectangle600 extends RoundedRectangleBorder {
  const RoundedRectangle600({super.borderRadius});
}
