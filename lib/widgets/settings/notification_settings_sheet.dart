import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal de configuración global de recordatorios y notificaciones de ClockDo.
class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  static const List<int> _reminderOptions = [0, 1, 5, 10, 15, 30, 60];

  String _optionTitle(BuildContext context, int minutes) {
    final l10n = context.l10n;
    if (minutes == 0) return l10n.advanceAtEventTime;
    return l10n.advanceMinutesBefore(minutes);
  }

  String _optionSubtitle(BuildContext context, int minutes) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    if (minutes == 5) {
      return isSpanish
          ? 'Recomendado para la mayoría de tareas'
          : 'Recommended for most tasks';
    }
    if (minutes == 0) {
      return isSpanish
          ? 'Aviso justo en la hora de inicio'
          : 'Alert right at task start time';
    }
    if (minutes == 30 || minutes == 60) {
      return isSpanish
          ? 'Ideal para tareas que requieren preparación'
          : 'Great for tasks requiring preparation';
    }
    return isSpanish
        ? 'Aviso previo con antelación'
        : 'Advance notification';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 28 + bottomPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificationsSettingsTitle,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        l10n.notificationsMasterToggleDesc,
                        style: const TextStyle(
                          color: Color(0xFF9E98D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Switch Activar / Desactivar Notificaciones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Color(0xFF6C5CE7), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notificationsMasterToggle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          provider.notificationsEnabled ? l10n.success : l10n.remindersDisabledTooltip,
                          style: const TextStyle(
                            color: Color(0xFF9E98D4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: provider.notificationsEnabled,
                    activeColor: const Color(0xFF6C5CE7),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      provider.setNotificationsEnabled(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tiempo de Anticipación
            Text(
              l10n.defaultAdvanceTime.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Lista de opciones
            ..._reminderOptions.map((minutes) {
              final isSelected = provider.reminderMinutesBefore == minutes;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: provider.notificationsEnabled
                      ? () {
                          HapticFeedback.selectionClick();
                          provider.setReminderMinutes(minutes);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.2 : 0.12)
                          : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _optionTitle(context, minutes),
                                style: TextStyle(
                                  color: provider.notificationsEnabled
                                      ? (isSelected ? const Color(0xFF6C5CE7) : textColor)
                                      : const Color(0xFF9E98D4),
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                              Text(
                                _optionSubtitle(context, minutes),
                                style: const TextStyle(
                                  color: Color(0xFF9E98D4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Botón de Prueba
            /*SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.sendTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notificación de prueba enviada 🔔'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                  side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Enviar Notificación de Prueba',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
