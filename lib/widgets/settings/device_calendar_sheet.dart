import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal bottom sheet para configurar la sincronización con los calendarios nativos del dispositivo.
class DeviceCalendarSheet extends StatefulWidget {
  const DeviceCalendarSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClockProvider>(),
        child: const DeviceCalendarSheet(),
      ),
    );
  }

  @override
  State<DeviceCalendarSheet> createState() => _DeviceCalendarSheetState();
}

class _DeviceCalendarSheetState extends State<DeviceCalendarSheet> {
  bool _isLoadingCalendars = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendars();
    });
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoadingCalendars = true);
    final provider = context.read<ClockProvider>();
    await provider.loadDeviceCalendars();
    if (mounted) {
      setState(() => _isLoadingCalendars = false);
    }
  }

  Color _parseCalendarColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    }
    if (colorValue is String) {
      final clean = colorValue.replaceFirst('#', '');
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        return Color(val.bitLength <= 24 ? (0xFF000000 | val) : val);
      }
    }
    return const Color(0xFF6C5CE7);
  }

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

    final calendars = provider.availableDeviceCalendars;
    final selectedIds = provider.selectedDeviceCalendarIds;
    final syncEnabled = provider.deviceCalendarSyncEnabled;

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

          // Encabezado
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
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deviceCalendarSettingsTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      l10n.deviceCalendarSettingsSubtitle,
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
                  // ── INTERRUPTOR MAESTRO ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: syncEnabled
                            ? const Color(0xFF6C5CE7).withValues(alpha: 0.5)
                            : borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.deviceCalendarSyncToggle,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.deviceCalendarSyncDesc,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch.adaptive(
                          value: syncEnabled,
                          activeColor: const Color(0xFF6C5CE7),
                          activeTrackColor: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            provider.setDeviceCalendarSyncEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── SECCIÓN: LISTADO DE CALENDARIOS ──
                  Text(
                    l10n.deviceCalendarSelectCalendars,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoadingCalendars)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.syncingStatus,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (calendars.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 38,
                            color: textColor.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.deviceCalendarNoCalendarsFound,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C5CE7)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loadCalendars,
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6C5CE7)),
                            label: Text(
                              l10n.deviceCalendarGrantPermission,
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: calendars.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final cal = calendars[idx];
                        final calId = cal.id ?? '';
                        final isSelected = selectedIds.contains(calId);
                        final calColor = _parseCalendarColor(cal.color);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: syncEnabled
                                ? () {
                                    HapticFeedback.selectionClick();
                                    provider.toggleDeviceCalendarSelection(calId);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: sectionBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected && syncEnabled
                                      ? calColor.withValues(alpha: 0.6)
                                      : borderColor,
                                  width: isSelected && syncEnabled ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Color dot
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: calColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: calColor.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nombre del calendario y cuenta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cal.name ?? 'Calendario',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (cal.accountName != null && cal.accountName!.isNotEmpty)
                                          Text(
                                            cal.accountName!,
                                            style: TextStyle(
                                              color: textColor.withValues(alpha: 0.5),
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Checkbox interactivo
                                  Checkbox(
                                    value: isSelected && syncEnabled,
                                    activeColor: calColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    onChanged: syncEnabled
                                        ? (_) {
                                            HapticFeedback.selectionClick();
                                            provider.toggleDeviceCalendarSelection(calId);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // ── BOTÓN: SINCRONIZAR AHORA ──
                  if (syncEnabled)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: provider.isDeviceCalendarSyncing
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                final count = await provider.syncDeviceCalendarEvents();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          const SizedBox(width: 10),
                                          Text(l10n.deviceCalendarSyncedCount(count)),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF00B894),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                        icon: provider.isDeviceCalendarSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 20),
                        label: Text(
                          provider.isDeviceCalendarSyncing
                              ? l10n.syncingStatus
                              : l10n.deviceCalendarSyncNow,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
