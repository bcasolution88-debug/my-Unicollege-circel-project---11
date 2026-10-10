import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/common.dart';
import 'simple_pages.dart';

/// 圈子 tab — sub tabs 圈子社区 · 帖子列表 · 我的收藏
class CircleTab extends StatefulWidget {
  final ScrollController controller;
  const CircleTab({super.key, required this.controller});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  int _sub = 0;
  static const _subs = ['圈子社区', '帖子列表', '我的收藏'];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      children: [
        SubTabBar(
            tabs: _subs, active: _sub, onTap: (i) => setState(() => _sub = i)),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            child: switch (_sub) {
              0 => _buildMain(context, p),
              1 => const EmptyHint(
                  icon: Icons.article_outlined, text: '暂无圈子帖子，去发布第一条吧'),
              _ => const EmptyHint(
                  icon: Icons.bookmark_border_rounded, text: '还没有收藏的帖子'),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMain(BuildContext context, p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SimplePage(title: '圈子社区'))),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x444F46E5),
                        blurRadius: 16,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('圈子社区',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF67E8F9), Color(0xFF38BDF8)]),
                  boxShadow: p.shadowMd,
                ),
                child: Text('圈子 ${kHotCircles.length} / 发帖 6',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: p.shadowSm,
          ),
          child: Column(
            children: [
              Text('圈子社区',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: p.ink)),
              const SizedBox(height: 10),
              Text('浏览全部圈子分类 · 探索你感兴趣的社区',
                  style: TextStyle(fontSize: 13, color: p.inkSubtle)),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SimplePage(title: '圈子社区'))),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 11),
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x55FCD34D),
                          blurRadius: 14,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Text('去浏览分类',
                      style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('我关注的圈子',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
            Text('${kFollowedCircles.length} 个',
                style: TextStyle(fontSize: 12, color: p.inkSubtle)),
          ],
        ),
        const SizedBox(height: 12),
        for (final c in kFollowedCircles) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SimplePage(title: c.name))),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: p.shadowSm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SeedPlaceholder(
                        seed: 'hc-${c.seed}', width: 64, height: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.ink)),
                        const SizedBox(height: 4),
                        Text(c.sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: p.inkSubtle, height: 1.4)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.inkSubtle),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sticky sub-tab bar shared by 圈子 / 论坛 tabs.
class SubTabBar extends StatelessWidget {
  final List<String> tabs;
  final int active;
  final ValueChanged<int> onTap;
  const SubTabBar(
      {super.key,
      required this.tabs,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: active == i ? 18 : 14,
                      fontWeight:
                          active == i ? FontWeight.w800 : FontWeight.w500,
                      color: active == i ? p.ink : p.inkMuted,
                      height: 1.2,
                    ),
                    child: Text(tabs[i]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: 3,
                    decoration: BoxDecoration(
                      color: active == i ? p.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            if (i < tabs.length - 1) const SizedBox(width: 22),
          ],
        ],
      ),
    );
  }
}
