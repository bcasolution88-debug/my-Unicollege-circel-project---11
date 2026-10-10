import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../widgets/carousel.dart';
import '../widgets/common.dart';
import '../widgets/events_signup_list.dart';
import 'circle_tab.dart';
import 'events_page.dart';
import 'forum_tab.dart';
import 'simple_pages.dart';

/// 01 Home — top segmented tabs + content + right FAB.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  bool _topVisible = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v = _scroll.offset > 40;
      if (v != _topVisible) setState(() => _topVisible = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final tab = state.homeTab;

    return Container(
      color: p.bg,
      child: Stack(
        children: [
          Column(
            children: [
              HomeTopBar(
                active: tab,
                onTab: (t) {
                  context.read<AppState>().setHomeTab(t);
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                },
              ),
              Expanded(
                child: switch (tab) {
                  HomeTab.home => _HomeMain(controller: _scroll),
                  HomeTab.circle => CircleTab(controller: _scroll),
                  HomeTab.forum => ForumTab(controller: _scroll),
                },
              ),
            ],
          ),
          // Info drawer handle — docked to right edge (only on Home tab)
          if (tab == HomeTab.home)
            Positioned(
              right: 0,
              bottom: 20,
              child: GestureDetector(
                onTap: () => _showInfoSheet(context),
                child: Container(
                  width: 30,
                  height: 44,
                  padding: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(22)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x1F0F172A),
                          blurRadius: 14,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      size: 20, color: p.inkMuted),
                ),
              ),
            ),
          // Scroll to top
          Positioned(
            right: 14,
            bottom: 80,
            child: AnimatedOpacity(
              opacity: _topVisible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_topVisible,
                child: GestureDetector(
                  onTap: () => _scroll.animateTo(0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface,
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1A0F172A),
                            blurRadius: 14,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Icon(Icons.arrow_upward_rounded,
                        size: 20, color: p.inkMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final p = context.pRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: p.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('平台广告',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const SeedPlaceholder(
                  seed: 'ad-1', height: 180, radius: 14),
            ),
            const SizedBox(height: 10),
            Text('长按图片保存到手机',
                style: TextStyle(fontSize: 12, color: p.inkSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Top bar: 首页 · 圈子 · 论坛 + 客服 / 扫一扫 / 夜间 / 搜索
class HomeTopBar extends StatelessWidget {
  final HomeTab active;
  final ValueChanged<HomeTab> onTab;
  const HomeTopBar({super.key, required this.active, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    const tabs = [
      (HomeTab.home, '首页'),
      (HomeTab.circle, '圈子'),
      (HomeTab.forum, '论坛'),
    ];
    return Container(
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (final t in tabs) ...[
                    _TabButton(
                      label: t.$2,
                      active: active == t.$1,
                      onTap: () => onTab(t.$1),
                    ),
                    const SizedBox(width: 20),
                  ],
                ],
              ),
            ),
            _IconBtn(
              icon: Icons.headset_mic_outlined,
              badge: state.serviceUnread,
              onTap: () {
                context.read<AppState>().clearServiceUnread();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SimplePage(title: '客服中心')));
              },
            ),
            _IconBtn(
              icon: Icons.qr_code_scanner_rounded,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SimplePage(title: '扫一扫'))),
            ),
            _IconBtn(
              icon: state.isDark
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
              color: state.isDark ? const Color(0xFFF59E0B) : null,
              onTap: () => context.read<AppState>().toggleTheme(),
            ),
            _IconBtn(
              icon: Icons.search_rounded,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SimplePage(title: '搜索'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: active ? 17 : 14.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? p.ink : p.inkMuted,
                height: 1.2,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: active ? p.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final Color? color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, this.badge = 0, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: color ?? p.ink),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -2,
                child: CountBadge(
                    count: badge, borderColor: p.surface, height: 16),
              ),
          ],
        ),
      ),
    );
  }
}

/// Home main content column.
class _HomeMain extends StatelessWidget {
  final ScrollController controller;
  const _HomeMain({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeroCarousel(slides: kHomeSlides),
          const _FeatureGrid(),
          SectionTitle(
            title: '热门圈子',
            onAction: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SimplePage(title: '圈子社区'))),
          ),
          const _HotCircles(),
          SectionTitle(
            title: '热门论坛',
            onAction: () =>
                context.read<AppState>().setHomeTab(HomeTab.forum),
          ),
          const _HotForums(),
          // 活动报名 — same list + behaviour as 活动频道, circular covers
          const EventsSignupList(roundCover: true),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kFeatures.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 4,
          mainAxisExtent: 72,
        ),
        itemBuilder: (_, i) {
          final it = kFeatures[i];
          final badge = it.id == 'messages' ? state.msgUnread : 0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goFeature(context, it.id),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            it.tint.fg,
                            it.tint.fg.withValues(alpha: 0.87)
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: it.tint.fg.withValues(alpha: 0.27),
                              blurRadius: 14,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Icon(it.icon, size: 22, color: Colors.white),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: CountBadge(count: badge, borderColor: p.bg),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.ink,
                        height: 1.2)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goFeature(BuildContext context, String id) {
    switch (id) {
      case 'events':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EventsPage()));
        break;
      case 'messages':
        context.read<AppState>().clearMsgUnread();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SimplePage(title: '消息信息')));
        break;
      default:
        final it = kFeatures.firstWhere((f) => f.id == id);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SimplePage(title: it.label)));
    }
  }
}

/// 热门圈子 — 2 rows × 4 square tiles, plain label below.
class _HotCircles extends StatelessWidget {
  const _HotCircles();

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: LayoutBuilder(builder: (context, c) {
        final tile = (c.maxWidth - 3 * 10) / 4;
        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final it in kHotCircles)
              SizedBox(
                width: tile,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SimplePage(title: it.label))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SeedPlaceholder(
                            seed: it.seed,
                            width: tile,
                            height: tile,
                            radius: 12),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: Text(it.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: p.ink,
                                height: 1.3)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// 热门论坛 — 3×2 grid with pill-tag labels.
class _HotForums extends StatelessWidget {
  const _HotForums();

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: LayoutBuilder(builder: (context, c) {
        final tile = (c.maxWidth - 2 * 10) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final it in kHotForums)
              SizedBox(
                width: tile,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      context.read<AppState>().setHomeTab(HomeTab.forum),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SeedPlaceholder(
                            seed: it.seed,
                            width: tile,
                            height: 72,
                            radius: 16),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        constraints: BoxConstraints(maxWidth: tile),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: it.tint ?? p.violet,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 10,
                                offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_florist_outlined,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(it.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
