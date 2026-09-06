import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal Bottom Sheet para seleccionar el idioma de la aplicación.
class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClockProvider>(),
        child: const LanguageSelectorSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ClockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentCode = provider.currentLanguageCode;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2D42)
                    : const Color(0xFFDDD9F5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    l10n.languageSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildOption(
            context: context,
            title: l10n.languageSpanish,
            subtitle: l10n.languageSpanishDesc,
            flagLabel: '🇪🇸',
            isSelected: currentCode == 'es',
            onTap: () {
              provider.setLocale(const Locale('es'));
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: l10n.languageEnglish,
            subtitle: l10n.languageEnglishDesc,
            flagLabel: '🇺🇸',
            isSelected: currentCode == 'en',
            onTap: () {
              provider.setLocale(const Locale('en'));
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            title: l10n.languageSystem,
            subtitle: l10n.languageSystemDesc,
            iconData: Icons.settings_suggest_rounded,
            isSelected: currentCode == 'system',
            onTap: () {
              provider.setLocale(null);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? flagLabel,
    IconData? iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C5CE7)
                    : (isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: flagLabel != null
                  ? Text(
                      flagLabel,
                      style: const TextStyle(fontSize: 20),
                    )
                  : Icon(
                      iconData ?? Icons.language_rounded,
                      color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6C5CE7),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
