import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'settings_dialogs.dart';

// ── Bölüm Başlığı ────────────────────────────────────────────────────────────
class SettingsSection extends StatelessWidget {
  const SettingsSection(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.midGrey,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Ayar Kartı ───────────────────────────────────────────────────────────────
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children, required this.isDark});
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Ayırıcı (Divider) ────────────────────────────────────────────────────────
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
    );
  }
}

// ── Switch Satırı ────────────────────────────────────────────────────────────
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.helpText,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? helpText;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: helpText != null
          ? () => SettingsDialogs.showHelpDialog(
              context,
              isDark,
              title,
              helpText!,
            )
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppTheme.secondaryBlue,
              inactiveThumbColor: isDark ? Colors.white38 : Colors.white,
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aksiyon Satırı ───────────────────────────────────────────────────────────
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.labelColor,
    required this.onTap,
    this.helpText,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? helpText;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: helpText != null
          ? () => SettingsDialogs.showHelpDialog(
              context,
              isDark,
              title,
              helpText!,
            )
          : null,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: labelColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment Butonları ────────────────────────────────────────────────────────
class SettingsSegmentButtons<T> extends StatelessWidget {
  const SettingsSegmentButtons({
    super.key,
    required this.items,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  final List<(T, String)> items;
  final T current;
  final ValueChanged<T> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (value, label) = item;
          final isSelected = current == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.secondaryBlue : AppTheme.primaryBlue)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Yardımcı İkon Kutusu ─────────────────────────────────────────────────────
Widget _iconBox(IconData icon, Color color) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
