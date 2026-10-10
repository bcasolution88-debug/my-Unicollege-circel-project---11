import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/common.dart';
import '../widgets/posts_list.dart';
import 'circle_tab.dart';
import 'simple_pages.dart';

/// 论坛 tab — sub tabs 话题讨论 · 最新帖子 · 我的收藏
class ForumTab extends StatefulWidget {
  final ScrollController controller;
  const ForumTab({super.key, required this.controller});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  int _sub = 0;
  static const _subs = ['话题讨论', '最新帖子', '我的收藏'];

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
              0 => _topics(context, p),
              1 => const PostsList(type: 'forum'),
              _ => const EmptyHint(
                  icon: Icons.bookmark_border_rounded, text: '还没有收藏的话题'),
            },
          ),
        ),
      ],
    );
  }

  Widget _topics(BuildContext context, p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('热门话题',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 12),
        for (final t in kTopics)
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SimplePage(title: '#${t.name}#'))),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: p.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: placeholderGradientFor(t.seed),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('#',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${t.name}#',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.ink)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(t.category,
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.primary)),
                            ),
                            const SizedBox(width: 8),
                            Text('${t.posts} 帖子',
                                style: TextStyle(
                                    fontSize: 11.5, color: p.inkSubtle)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.inkSubtle),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
