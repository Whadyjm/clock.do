import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal integral de Ajustes para Clock.Do.
/// Permite configurar:
/// 1. Tema (Claro, Oscuro, Sistema)
/// 2. Idioma (Español, English, Sistema)
/// 3. Notificaciones y recordatorios globales (Switch maestro y anticipación).
class AppSettingsSheet extends StatelessWidget {
  const AppSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClockProvider>(),
        child: const AppSettingsSheet(),
      ),
    );
  }

  static const List<int> _reminderOptions = [0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ClockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final sectionBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD);
    final borderColor = isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Encabezado de Ajustes
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      l10n.settingsSubtitle,
                      style: const TextStyle(
                        color: Color(0xFF9E98D4),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: sectionBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9E98D4)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido desplazable
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SECCIÓN 1: TEMA ─────────────────────────────
                  _buildSectionHeader(
                    title: l10n.themeTitle,
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildThemeSelector(context, provider, isDark, sectionBg, borderColor, textColor),

                  const SizedBox(height: 22),

                  // ── SECCIÓN 2: IDIOMA ───────────────────────────
                  _buildSectionHeader(
                    title: l10n.languageTitle,
                    icon: Icons.language_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildLanguageSelector(context, provider, isDark, sectionBg, borderColor, textColor),

                  const SizedBox(height: 22),

                  // ── SECCIÓN 3: NOTIFICACIONES GLOBALES ──────────
                  _buildSectionHeader(
                    title: l10n.notificationsSettingsTitle,
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationSettings(context, provider, isDark, sectionBg, borderColor, textColor),

                  const SizedBox(height: 24),

                  // Brand Footer
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/clickdologo.png',
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clock.Do • v1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF9E98D4).withValues(alpha: 0.6)
                                : const Color(0xFF636E72).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6C5CE7)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9E98D4),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // 1. Selector de Tema (Claro / Oscuro / Sistema)
  // ──────────────────────────────────────────────
  Widget _buildThemeSelector(
    BuildContext context,
    ClockProvider provider,
    bool isDark,
    Color sectionBg,
    Color borderColor,
    Color textColor,
  ) {
    final l10n = context.l10n;
    final current = provider.themeMode;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildThemeOptionTab(
            title: l10n.lightMode,
            icon: Icons.light_mode_rounded,
            isSelected: current == ThemeMode.light,
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode(ThemeMode.light);
            },
            isDark: isDark,
            textColor: textColor,
          ),
          const SizedBox(width: 6),
          _buildThemeOptionTab(
            title: l10n.darkMode,
            icon: Icons.dark_mode_rounded,
            isSelected: current == ThemeMode.dark,
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode(ThemeMode.dark);
            },
            isDark: isDark,
            textColor: textColor,
          ),
          const SizedBox(width: 6),
          _buildThemeOptionTab(
            title: l10n.systemMode,
            icon: Icons.brightness_auto_rounded,
            isSelected: current == ThemeMode.system,
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setThemeMode(ThemeMode.system);
            },
            isDark: isDark,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9E98D4),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 2. Selector de Idioma (Español / English / Sistema)
  // ──────────────────────────────────────────────
  Widget _buildLanguageSelector(
    BuildContext context,
    ClockProvider provider,
    bool isDark,
    Color sectionBg,
    Color borderColor,
    Color textColor,
  ) {
    final l10n = context.l10n;
    final currentCode = provider.currentLanguageCode;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildLanguageTab(
            label: l10n.languageSpanish,
            flagOrIcon: '🇪🇸',
            isSelected: currentCode == 'es',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setLocale(const Locale('es'));
            },
            textColor: textColor,
          ),
          const SizedBox(width: 6),
          _buildLanguageTab(
            label: l10n.languageEnglish,
            flagOrIcon: '🇺🇸',
            isSelected: currentCode == 'en',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setLocale(const Locale('en'));
            },
            textColor: textColor,
          ),
          const SizedBox(width: 6),
          _buildLanguageTab(
            label: l10n.languageSystem,
            flagOrIcon: '🌐',
            isSelected: currentCode == 'system',
            onTap: () {
              HapticFeedback.selectionClick();
              provider.setLocale(null);
            },
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTab({
    required String label,
    required String flagOrIcon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flagOrIcon,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 3. Notificaciones y Recordatorios Globales
  // ──────────────────────────────────────────────
  Widget _buildNotificationSettings(
    BuildContext context,
    ClockProvider provider,
    bool isDark,
    Color sectionBg,
    Color borderColor,
    Color textColor,
  ) {
    final l10n = context.l10n;
    final enabled = provider.notificationsEnabled;
    final currentMinutes = provider.reminderMinutesBefore;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Switch Maestro
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (enabled ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4))
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  enabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: enabled ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                  size: 20,
                ),
              ),
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
                      enabled ? l10n.success : l10n.remindersDisabledTooltip,
                      style: const TextStyle(
                        color: Color(0xFF9E98D4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: const Color(0xFF6C5CE7),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  provider.setNotificationsEnabled(val);
                },
              ),
            ],
          ),

          if (enabled) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF),
            ),
            const SizedBox(height: 12),

            Text(
              l10n.defaultAdvanceTime,
              style: const TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            // Chips de tiempo de anticipación
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reminderOptions.map((minutes) {
                final isSelected = currentMinutes == minutes;
                final label = minutes == 0
                    ? l10n.advanceAtEventTime
                    : l10n.advanceMinutesBefore(minutes);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setReminderMinutes(minutes);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C5CE7)
                          : (isDark ? const Color(0xFF25283E) : const Color(0xFFECE9FC)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
