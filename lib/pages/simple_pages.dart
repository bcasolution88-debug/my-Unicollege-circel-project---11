import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

LinearGradient placeholderGradientFor(String seed) => placeholderGradient(seed);

/// Generic sub page used for surfaces outside the current design scope.
class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: SubHeader(title: title),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SeedPlaceholder(
                  seed: title, width: 96, height: 96, radius: 20),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 8),
            Text('内容由后台管理 · 即将上线',
                style: TextStyle(fontSize: 13, color: p.inkSubtle)),
          ],
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 48, color: p.inkSubtle),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 13, color: p.inkSubtle)),
        ],
      ),
    );
  }
}

/// 我的 — Me page (summary per handoff).
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      color: p.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SeedAvatar(seed: 'me', size: 64, label: 'M'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('我的昵称',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: p.ink)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _pill(p, 'ID 800123'),
                                  const SizedBox(width: 6),
                                  _pill(p, 'IP 吉隆坡'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _stat(p, '我关注的', 12),
                        _stat(p, '我的粉丝', 8),
                        _stat(p, '我的获赞', 36),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  for (final t in const [
                    ('我的主页', Icons.person_outline, Tint.indigo),
                    ('关于我们', Icons.info_outline, Tint.violet),
                    ('联系我们', Icons.call_outlined, Tint.sky),
                    ('帮助中心', Icons.help_outline, Tint.mint),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => SimplePage(title: t.$1))),
                        child: Column(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  color: t.$3.bg, shape: BoxShape.circle),
                              child: Icon(t.$2, color: t.$3.fg, size: 22),
                            ),
                            const SizedBox(height: 6),
                            Text(t.$1,
                                style: TextStyle(fontSize: 12, color: p.ink)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: p.shadowSm,
              ),
              child: Column(
                children: [
                  for (final (i, item) in const [
                    ('反馈信息', Icons.feedback_outlined),
                    ('在线客服', Icons.headset_mic_outlined),
                    ('开发合作', Icons.handshake_outlined),
                    ('清除缓存', Icons.cleaning_services_outlined),
                    ('在线更新', Icons.system_update_alt_outlined),
                  ].indexed)
                    ListTile(
                      dense: true,
                      leading: Icon(item.$2, color: p.inkMuted, size: 20),
                      title: Text(item.$1,
                          style: TextStyle(fontSize: 14, color: p.ink)),
                      trailing:
                          Icon(Icons.chevron_right_rounded, color: p.inkSubtle),
                      shape: i == 4
                          ? null
                          : Border(bottom: BorderSide(color: p.divider)),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => SimplePage(title: item.$1))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(AppPalette p, String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(s, style: TextStyle(fontSize: 11, color: p.inkMuted)),
      );

  Widget _stat(AppPalette p, String label, int n) => Expanded(
        child: Column(
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: p.inkSubtle)),
          ],
        ),
      );
}
