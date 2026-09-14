import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pomodoro_state.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal bottom sheet para configurar tiempos y preferencias del Pomodoro.
class PomodoroSettingsSheet extends StatefulWidget {
  const PomodoroSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClockProvider>(),
        child: const PomodoroSettingsSheet(),
      ),
    );
  }

  @override
  State<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<PomodoroSettingsSheet> {
  late int _focusDuration;
  late int _shortBreak;
  late int _longBreak;
  late int _longBreakInterval;
  late bool _autoStartBreaks;
  late bool _autoStartPomodoros;
  late bool _enableNotifications;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    final current = context.read<ClockProvider>().pomodoroSettings;
    _focusDuration = current.focusDurationMinutes;
    _shortBreak = current.shortBreakDurationMinutes;
    _longBreak = current.longBreakDurationMinutes;
    _longBreakInterval = current.longBreakInterval;
    _autoStartBreaks = current.autoStartBreaks;
    _autoStartPomodoros = current.autoStartPomodoros;
    _enableNotifications = current.enableNotifications;
    _soundEnabled = current.soundEnabled;
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final newSettings = PomodoroSettings(
      focusDurationMinutes: _focusDuration,
      shortBreakDurationMinutes: _shortBreak,
      longBreakDurationMinutes: _longBreak,
      longBreakInterval: _longBreakInterval,
      autoStartBreaks: _autoStartBreaks,
      autoStartPomodoros: _autoStartPomodoros,
      enableNotifications: _enableNotifications,
      soundEnabled: _soundEnabled,
    );
    context.read<ClockProvider>().updatePomodoroSettings(newSettings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final secondaryColor = isDark ? const Color(0xFF9E98D4) : const Color(0xFF6B7194);
    final screenH = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2A3C), Color(0xFFD63031)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A3C).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🍅', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pomodoroSettings,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Personaliza los intervalos de concentración',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: secondaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contenido desplazable
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Duración de Enfoque
                _buildDurationSelector(
                  title: l10n.pomodoroFocusDuration,
                  currentVal: _focusDuration,
                  options: [15, 20, 25, 30, 45, 50, 60],
                  color: const Color(0xFFFF2A3C),
                  onSelected: (v) => setState(() => _focusDuration = v),
                ),

                const SizedBox(height: 18),

                // 2. Duración de Descanso Corto
                _buildDurationSelector(
                  title: l10n.pomodoroShortBreakDuration,
                  currentVal: _shortBreak,
                  options: [3, 5, 10, 15],
                  color: const Color(0xFF00CEC9),
                  onSelected: (v) => setState(() => _shortBreak = v),
                ),

                const SizedBox(height: 18),

                // 3. Duración de Descanso Largo
                _buildDurationSelector(
                  title: l10n.pomodoroLongBreakDuration,
                  currentVal: _longBreak,
                  options: [10, 15, 20, 25, 30],
                  color: const Color(0xFF6C5CE7),
                  onSelected: (v) => setState(() => _longBreak = v),
                ),

                const SizedBox(height: 18),

                // 4. Ciclos antes de Descanso Largo
                _buildDurationSelector(
                  title: l10n.pomodoroCyclesBeforeLongBreak,
                  currentVal: _longBreakInterval,
                  options: [2, 3, 4, 5, 6],
                  color: const Color(0xFFF39C12),
                  unit: 'ciclos',
                  onSelected: (v) => setState(() => _longBreakInterval = v),
                ),

                const SizedBox(height: 20),

                // 5. Opciones Automáticas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191C2E) : const Color(0xFFF7F5FE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF282C48) : const Color(0xFFE9E4FA),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: Text(
                          l10n.pomodoroAutoStartBreaks,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        activeColor: const Color(0xFF6C5CE7),
                        contentPadding: EdgeInsets.zero,
                        value: _autoStartBreaks,
                        onChanged: (v) => setState(() => _autoStartBreaks = v),
                      ),
                      Divider(
                        color: isDark ? const Color(0xFF282C48) : const Color(0xFFE9E4FA),
                        height: 1,
                      ),
                      SwitchListTile.adaptive(
                        title: Text(
                          l10n.pomodoroAutoStartFocus,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        activeColor: const Color(0xFF6C5CE7),
                        contentPadding: EdgeInsets.zero,
                        value: _autoStartPomodoros,
                        onChanged: (v) => setState(() => _autoStartPomodoros = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 6. Notificaciones y Sonido
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191C2E) : const Color(0xFFF7F5FE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF282C48) : const Color(0xFFE9E4FA),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: Text(
                          l10n.pomodoroNotificationSettingTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          l10n.pomodoroNotificationSettingDesc,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 11.5,
                          ),
                        ),
                        activeColor: const Color(0xFF6C5CE7),
                        contentPadding: EdgeInsets.zero,
                        value: _enableNotifications,
                        onChanged: (v) => setState(() => _enableNotifications = v),
                      ),
                      if (_enableNotifications) ...[
                        Divider(
                          color: isDark ? const Color(0xFF282C48) : const Color(0xFFE9E4FA),
                          height: 1,
                        ),
                        SwitchListTile.adaptive(
                          title: Text(
                            l10n.pomodoroSoundSettingTitle,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          activeColor: const Color(0xFF6C5CE7),
                          contentPadding: EdgeInsets.zero,
                          value: _soundEnabled,
                          onChanged: (v) => setState(() => _soundEnabled = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector({
    required String title,
    required int currentVal,
    required List<int> options,
    required Color color,
    String unit = 'min',
    required ValueChanged<int> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$currentVal $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: options.map((opt) {
              final isSelected = opt == currentVal;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('$opt $unit'),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: isDark ? const Color(0xFF1E2238) : const Color(0xFFF1EEFB),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4B4869)),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: isSelected ? color : Colors.transparent,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onSelected(opt);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
