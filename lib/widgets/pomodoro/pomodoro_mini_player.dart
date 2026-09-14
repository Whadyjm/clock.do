import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pomodoro_state.dart';
import '../../providers/clock_provider.dart';

/// Mini-reproductor flotante para controlar la sesión de Pomodoro mientras se explora el Reloj o Kanban.
class PomodoroMiniPlayer extends StatelessWidget {
  const PomodoroMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final session = provider.pomodoroState;

    // Solo se muestra si hay una sesión activa/pausada y el usuario NO está en la vista Pomodoro
    if (!provider.hasActivePomodoroSession || provider.viewMode == AppViewMode.pomodoro) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = session.phase;
    final isRunning = session.status.isRunning;
    final taskTitle = session.activeTask?.title ?? 'Enfoque Libre';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF181B2E) : Colors.white).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: phase.primaryColor.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: phase.primaryColor.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.setViewMode(AppViewMode.pomodoro);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Icono animado de la fase
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: phase.primaryColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: phase.isFocus
                      ? const Text('🍅', style: TextStyle(fontSize: 16))
                      : Icon(
                          phase.icon,
                          size: 16,
                          color: phase.primaryColor,
                        ),
                ),

                const SizedBox(width: 10),

                // Tiempo y Tarea
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            session.formattedTime,
                            style: TextStyle(
                              color: phase.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: phase.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              phase.getLocalizedName(context).toUpperCase(),
                              style: TextStyle(
                                color: phase.primaryColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        taskTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF4B4869),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón Play / Pausa rápido
                IconButton(
                  icon: Icon(
                    isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: phase.primaryColor,
                    size: 32,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (isRunning) {
                      provider.pausePomodoro();
                    } else {
                      provider.startPomodoro();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
