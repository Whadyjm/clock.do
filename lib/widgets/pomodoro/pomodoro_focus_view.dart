import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pomodoro_state.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';
import 'radial_pomodoro_timer.dart';
import 'pomodoro_task_selector_sheet.dart';
import 'pomodoro_settings_sheet.dart';

/// Vista principal de enfoque Pomodoro.
class PomodoroFocusView extends StatelessWidget {
  const PomodoroFocusView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final session = provider.pomodoroState;
    final settings = provider.pomodoroSettings;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = session.phase;
    final isRunning = session.status.isRunning;
    final isPaused = session.status.isPaused;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      child: Column(
        children: [
          // ── 1. Barra superior: Selector de Fases + Botón de Ajustes ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161828) : const Color(0xFFEEEAF8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildPhaseTab(
                        context,
                        title: l10n.pomodoroFocus,
                        emoji: '🍅',
                        phaseTarget: PomodoroPhase.focus,
                        currentPhase: phase,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPomodoroPhase(PomodoroPhase.focus);
                        },
                      ),
                      _buildPhaseTab(
                        context,
                        title: l10n.pomodoroShortBreak,
                        phaseTarget: PomodoroPhase.shortBreak,
                        currentPhase: phase,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPomodoroPhase(PomodoroPhase.shortBreak);
                        },
                      ),
                      _buildPhaseTab(
                        context,
                        title: l10n.pomodoroLongBreak,
                        phaseTarget: PomodoroPhase.longBreak,
                        currentPhase: phase,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPomodoroPhase(PomodoroPhase.longBreak);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161828) : const Color(0xFFEEEAF8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  tooltip: l10n.pomodoroSettings,
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF6C5CE7),
                  ),
                  onPressed: () => PomodoroSettingsSheet.show(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. Esfera Radial de Enfoque ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 330),
            child: RadialPomodoroTimer(
              session: session,
              settings: settings,
              onTap: () {
                HapticFeedback.mediumImpact();
                if (isRunning) {
                  provider.pausePomodoro();
                } else {
                  provider.startPomodoro();
                }
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── 3. Tarjeta de Tarea Vinculada ──
          _buildActiveTaskCard(context, provider, session),

          const SizedBox(height: 16),

          // ── 4. Botones de Control Principal ──
          _buildControlsRow(context, provider, session),

          const SizedBox(height: 20),

          // ── 5. Métricas del Día (Estadísticas de Enfoque) ──
          _buildDailyStatsCard(context, session, isDark),
        ],
      ),
    );
  }

  Widget _buildPhaseTab(
    BuildContext context, {
    required String title,
    String? emoji,
    required PomodoroPhase phaseTarget,
    required PomodoroPhase currentPhase,
    required VoidCallback onTap,
  }) {
    final isSelected = phaseTarget == currentPhase;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? phaseTarget.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: phaseTarget.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
              ] else ...[
                Icon(
                  phaseTarget.icon,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF8A90BA) : const Color(0xFF7A75A3)),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF8A90BA) : const Color(0xFF7A75A3)),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard(
    BuildContext context,
    ClockProvider provider,
    PomodoroSessionState session,
  ) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = session.activeTask;

    if (task == null) {
      return GestureDetector(
        onTap: () => PomodoroTaskSelectorSheet.show(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A2C) : const Color(0xFFF6F4FD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
              style: BorderStyle.solid,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_task_rounded, size: 18, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text(
                l10n.pomodoroSelectTask,
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.category.color.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: task.category.color.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: task.category.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.category.icon, size: 16, color: task.category.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  task.category.displayName,
                  style: TextStyle(
                    color: task.category.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.pomodoroChangeTask,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF9E98D4)),
            onPressed: () => PomodoroTaskSelectorSheet.show(context),
          ),
          IconButton(
            tooltip: l10n.pomodoroMarkCompleted,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 22, color: Color(0xFF00CEC9)),
            onPressed: () {
              HapticFeedback.mediumImpact();
              provider.completePomodoroTask();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tarea "${task.title}" completada'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF00CEC9),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    ClockProvider provider,
    PomodoroSessionState session,
  ) {
    final isRunning = session.status.isRunning;
    final phase = session.phase;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón -5 min
        _buildAdjustmentButton(
          context,
          label: '-5m',
          onTap: () {
            HapticFeedback.selectionClick();
            provider.adjustPomodoroTime(-5);
          },
        ),

        const SizedBox(width: 14),

        // Botón Reset
        IconButton.filledTonal(
          icon: const Icon(Icons.replay_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E2238) : const Color(0xFFEEEAF8),
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF4B4869),
            padding: const EdgeInsets.all(14),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            provider.resetPomodoro();
          },
        ),

        const SizedBox(width: 16),

        // Botón Principal Play / Pausa (Glow grande)
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (isRunning) {
              provider.pausePomodoro();
            } else {
              provider.startPomodoro();
            }
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [phase.secondaryColor, phase.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: phase.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Botón Saltar Fase
        IconButton.filledTonal(
          icon: const Icon(Icons.skip_next_rounded, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E2238) : const Color(0xFFEEEAF8),
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF4B4869),
            padding: const EdgeInsets.all(14),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            provider.skipPomodoroPhase();
          },
        ),

        const SizedBox(width: 14),

        // Botón +5 min
        _buildAdjustmentButton(
          context,
          label: '+5m',
          onTap: () {
            HapticFeedback.selectionClick();
            provider.adjustPomodoroTime(5);
          },
        ),
      ],
    );
  }

  Widget _buildAdjustmentButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2238) : const Color(0xFFEEEAF8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF6C5CE7),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStatsCard(
    BuildContext context,
    PomodoroSessionState session,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cardBg = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF252940) : const Color(0xFFEBE7F7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF6C5CE7).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            emoji: '🍅',
            color: const Color(0xFFFF2A3C),
            label: l10n.pomodoroCompletedSessions,
            value: '${session.totalPomodorosToday}',
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? const Color(0xFF282C48) : const Color(0xFFEBE7F7),
          ),
          _buildStatItem(
            icon: Icons.timer_outlined,
            color: const Color(0xFF00CEC9),
            label: l10n.pomodoroTotalFocusTime,
            value: '${session.totalFocusMinutesToday} m',
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark ? const Color(0xFF282C48) : const Color(0xFFEBE7F7),
          ),
          _buildStatItem(
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFF1C40F),
            label: l10n.pomodoroTicksEarned,
            value: '+${session.totalPomodorosToday * 15}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    IconData? icon,
    String? emoji,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9E98D4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
