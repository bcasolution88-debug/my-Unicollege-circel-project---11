import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

extension PaletteX on BuildContext {
  AppPalette get p => watch<AppState>().palette;
  AppPalette get pRead => read<AppState>().palette;
}

/// Deterministic coloured placeholder — mirrors Placeholder.jsx.
class SeedPlaceholder extends StatelessWidget {
  final String seed;
  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;
  final Widget? child;

  const SeedPlaceholder({
    super.key,
    required this.seed,
    this.width,
    this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: placeholderGradient(seed),
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Circular avatar placeholder — mirrors Avatar in Placeholder.jsx.
class SeedAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final String? label;
  final Color? ring;

  const SeedAvatar(
      {super.key,
      required this.seed,
      this.size = 36,
      this.label,
      this.ring});

  @override
  Widget build(BuildContext context) {
    final initial = (label ?? seed).trim().isEmpty
        ? 'U'
        : (label ?? seed).trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarGradient(seed),
        border: ring != null ? Border.all(color: ring!, width: 2) : null,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
  }
}

/// Overlapping avatars (LikerAvatars).
class StackedAvatars extends StatelessWidget {
  final List<String> users;
  final double size;
  const StackedAvatars({super.key, required this.users, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final shown = users.take(6).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final overlap = 8.0;
    final width = size + (shown.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size + 3,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surface,
                  border: Border.all(color: p.surface, width: 1.5),
                ),
                child: SeedAvatar(seed: shown[i], size: size),
              ),
            ),
        ],
      ),
    );
  }
}

/// Red count badge.
class CountBadge extends StatelessWidget {
  final int count;
  final Color borderColor;
  final double height;
  const CountBadge(
      {super.key,
      required this.count,
      required this.borderColor,
      this.height = 18});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(minWidth: height),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1),
      ),
    );
  }
}

/// Section header: title left, "全部 ▦" right.
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;
  const SectionTitle({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel = '全部',
    this.actionIcon = Icons.grid_view_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(actionLabel,
                    style: TextStyle(fontSize: 13, color: p.inkSubtle)),
                const SizedBox(width: 4),
                Icon(actionIcon, size: 12, color: p.inkSubtle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sub-page header: back pill + home pill + centered title.
class SubHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  const SubHeader({super.key, required this.title, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _NavPill(),
              ),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.ink)),
              if (actions.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(999)),
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: p.ink),
            ),
          ),
          Container(width: 1, height: 16, color: p.divider),
          InkWell(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(999)),
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.home_outlined, size: 17, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }
}

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1600),
      margin: const EdgeInsets.fromLTRB(60, 0, 60, 90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      backgroundColor: const Color(0xCC0F172A),
    ));
}
