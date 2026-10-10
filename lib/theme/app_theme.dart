import 'package:flutter/material.dart';

/// Design tokens from the handoff (theme.js / darkMode.js).
class AppPalette {
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color violet;
  final Color accent;
  final Color accentDeep;
  final Color mint;
  final Color mintSoft;
  final Color pink;
  final Color sky;
  final Color bg;
  final Color surface;
  final Color divider;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color danger;
  final bool isDark;

  const AppPalette({
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.violet,
    required this.accent,
    required this.accentDeep,
    required this.mint,
    required this.mintSoft,
    required this.pink,
    required this.sky,
    required this.bg,
    required this.surface,
    required this.divider,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.danger,
    required this.isDark,
  });

  static const light = AppPalette(
    primary: Color(0xFF4F46E5),
    primaryDeep: Color(0xFF3730A3),
    primarySoft: Color(0xFFEEF2FF),
    violet: Color(0xFF7C3AED),
    accent: Color(0xFFFCD34D),
    accentDeep: Color(0xFFF59E0B),
    mint: Color(0xFF10B981),
    mintSoft: Color(0xFFD1FAE5),
    pink: Color(0xFFEC4899),
    sky: Color(0xFF38BDF8),
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    divider: Color(0xFFEEF0F5),
    ink: Color(0xFF0F172A),
    inkMuted: Color(0xFF475569),
    inkSubtle: Color(0xFF94A3B8),
    danger: Color(0xFFEF4444),
    isDark: false,
  );

  static const dark = AppPalette(
    primary: Color(0xFF818CF8),
    primaryDeep: Color(0xFFC7D2FE),
    primarySoft: Color(0xFF1E1B4B),
    violet: Color(0xFFA78BFA),
    accent: Color(0xFFFCD34D),
    accentDeep: Color(0xFFF59E0B),
    mint: Color(0xFF10B981),
    mintSoft: Color(0xFF063B2E),
    pink: Color(0xFFEC4899),
    sky: Color(0xFF38BDF8),
    bg: Color(0xFF0B1020),
    surface: Color(0xFF151B2E),
    divider: Color(0xFF262F48),
    ink: Color(0xFFE5E9F2),
    inkMuted: Color(0xFFA7B0C4),
    inkSubtle: Color(0xFF6E7894),
    danger: Color(0xFFEF4444),
    isDark: true,
  );

  List<BoxShadow> get shadowSm => const [
        BoxShadow(
            color: Color(0x0D0F172A), blurRadius: 2, offset: Offset(0, 1)),
      ];
  List<BoxShadow> get shadowMd => const [
        BoxShadow(
            color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
      ];
}

/// Category tint pairs (bg / fg).
class Tint {
  final Color bg;
  final Color fg;
  const Tint(this.bg, this.fg);

  static const indigo = Tint(Color(0xFFEEF2FF), Color(0xFF4F46E5));
  static const violet = Tint(Color(0xFFF5F3FF), Color(0xFF7C3AED));
  static const pink = Tint(Color(0xFFFCE7F3), Color(0xFFDB2777));
  static const sky = Tint(Color(0xFFE0F2FE), Color(0xFF0284C7));
  static const mint = Tint(Color(0xFFD1FAE5), Color(0xFF059669));
  static const amber = Tint(Color(0xFFFEF3C7), Color(0xFFD97706));
  static const rose = Tint(Color(0xFFFFE4E6), Color(0xFFE11D48));
  static const slate = Tint(Color(0xFFF1F5F9), Color(0xFF475569));
  static const teal = Tint(Color(0xFFCCFBF1), Color(0xFF0D9488));
}

/// Deterministic hue from a seed string — mirrors Placeholder.jsx.
double hueFromSeed(String seed) {
  int h = 0;
  for (int i = 0; i < seed.length; i++) {
    h = (h * 31 + seed.codeUnitAt(i)) % 360;
  }
  return h.toDouble();
}

LinearGradient placeholderGradient(String seed) {
  final h = hueFromSeed(seed);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HSLColor.fromAHSL(1, h, 0.70, 0.60).toColor(),
      HSLColor.fromAHSL(1, (h + 40) % 360, 0.70, 0.55).toColor(),
    ],
  );
}

LinearGradient avatarGradient(String seed) {
  final h = hueFromSeed(seed);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HSLColor.fromAHSL(1, h, 0.65, 0.65).toColor(),
      HSLColor.fromAHSL(1, (h + 35) % 360, 0.70, 0.55).toColor(),
    ],
  );
}

ThemeData buildThemeData(AppPalette p) {
  final base = p.isDark ? ThemeData.dark() : ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: p.primary,
      secondary: p.violet,
      surface: p.surface,
    ),
    splashFactory: InkRipple.splashFactory,
    textTheme: base.textTheme.apply(
      bodyColor: p.ink,
      displayColor: p.ink,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans SC',
        'Hiragino Sans GB',
        'Microsoft YaHei',
        'Inter',
        'sans-serif',
      ],
    ),
  );
}
