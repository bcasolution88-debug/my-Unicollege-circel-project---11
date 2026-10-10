import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/publish_page.dart';
import 'pages/simple_pages.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';

/// Root shell: body + bottom nav (首页 · 圈子 · ＋ · 论坛 · 我的).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final isMe = state.navTab == NavTab.me;

    return Scaffold(
      backgroundColor: p.bg,
      body: isMe ? const MePage() : const HomePage(),
      bottomNavigationBar: const BottomNav(),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final active = state.navTab;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.divider)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, -1)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  label: '首页',
                  active: active == NavTab.home,
                  onTap: () => context.read<AppState>().setNavTab(NavTab.home)),
              _NavItem(
                  icon: Icons.hexagon_outlined,
                  label: '圈子',
                  active: active == NavTab.circle,
                  onTap: () =>
                      context.read<AppState>().setNavTab(NavTab.circle)),
              _PublishButton(onTap: () => _showPublishSheet(context)),
              _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '论坛',
                  active: active == NavTab.forum,
                  onTap: () =>
                      context.read<AppState>().setNavTab(NavTab.forum)),
              _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: '我的',
                  active: active == NavTab.me,
                  onTap: () => context.read<AppState>().setNavTab(NavTab.me)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPublishSheet(BuildContext context) {
    final p = context.pRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      barrierColor: const Color(0x590F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: p.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Text('选择发布类型',
                style: TextStyle(fontSize: 13, color: p.inkSubtle)),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PublishBtn(
                  color: p.sky,
                  label: '圈子发布',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PublishPage(kind: PublishKind.circle)));
                  },
                ),
                _PublishBtn(
                  color: p.accent,
                  fg: const Color(0xFF0F172A),
                  label: '论坛发布',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PublishPage(kind: PublishKind.forum)));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active ? p.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  size: 22, color: active ? p.primary : p.inkSubtle),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? p.primary : p.inkSubtle)),
          ],
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Color(0x80FCD34D),
                  blurRadius: 20,
                  offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
    );
  }
}

class _PublishBtn extends StatelessWidget {
  final Color color;
  final Color fg;
  final String label;
  final VoidCallback onTap;
  const _PublishBtn(
      {required this.color,
      this.fg = Colors.white,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 32, color: fg),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: p.ink)),
        ],
      ),
    );
  }
}
