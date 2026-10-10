import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'edit_profile_page.dart';

/// 我的主页 — banner (blank until user adds a background), 资料 / 动态 tabs,
/// own profile shows gradient 资料修改 button.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  int _tab = 0;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (!state.online) return;
    try {
      final all = await state.api.posts();
      if (mounted) {
        setState(() => _posts =
            all.where((p) => p.authorUid == state.uid).toList());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final me = state.profile;
    final isF = me.gender == 'f';

    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '我的主页'),
      body: Stack(children: [
        ListView(padding: EdgeInsets.zero, children: [
          // Banner — blank until bgUrl set
          Stack(clipBehavior: Clip.none, children: [
            Container(
              height: 150,
              color: p.surface,
              child: me.bgUrl.isNotEmpty
                  ? SeedPlaceholder(seed: me.bgUrl, radius: 0)
                  : Center(
                      child: Text('未设置主页背景',
                          style: TextStyle(fontSize: 12, color: p.inkSubtle))),
            ),
            Positioned(
              left: 16,
              bottom: -32,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.bg),
                child: SeedAvatar(
                    seed: me.avatar.isEmpty ? 'me' : me.avatar,
                    size: 72,
                    label: me.name,
                    ring: isF ? p.pink : p.sky),
              ),
            ),
          ]),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(me.name,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
                const SizedBox(width: 6),
                Icon(isF ? Icons.female_rounded : Icons.male_rounded,
                    size: 16, color: isF ? p.pink : p.sky),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _pill(p, 'ID ${me.uid}'),
                const SizedBox(width: 6),
                _pill(p, 'IP ${me.ip}'),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _stat(p, '关注', me.following.length),
                _stat(p, '粉丝', me.followers.length),
                _stat(p, '获赞', me.likes),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.divider))),
            child: Row(children: [
              for (final (i, t) in const ['资料', '动态'].indexed)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(children: [
                      const SizedBox(height: 12),
                      Text(t,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  _tab == i ? FontWeight.w700 : FontWeight.w500,
                              color: _tab == i ? p.ink : p.inkMuted)),
                      const SizedBox(height: 8),
                      Container(
                          width: 22,
                          height: 3,
                          decoration: BoxDecoration(
                              color: _tab == i ? p.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(2))),
                    ]),
                  ),
                ),
            ]),
          ),
          if (_tab == 0) _InfoTab(me: me) else _PostsTab(posts: _posts),
          const SizedBox(height: 100),
        ]),
        Positioned(
          right: 16,
          bottom: 24,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()));
              if (context.mounted) context.read<AppState>().reloadProfile();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x554F46E5),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text('资料修改',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pill(p, String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.divider)),
        child: Text(s, style: TextStyle(fontSize: 11, color: p.inkMuted)),
      );

  Widget _stat(p, String l, int n) => Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Row(children: [
          Text('$n',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(width: 4),
          Text(l, style: TextStyle(fontSize: 12, color: p.inkSubtle)),
        ]),
      );
}

class _InfoTab extends StatelessWidget {
  final Profile me;
  const _InfoTab({required this.me});

  static const _labels = {
    'company': '公司',
    'job': '职业',
    'role': '职务',
    'wechat': '微信号',
    'whatsapp': 'Whatsapp',
    'fb': 'FB',
    'ig': 'IG',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final rows = _labels.entries
        .where((e) => (me.fields[e.key] ?? '').isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('自我介绍',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: p.surface, borderRadius: BorderRadius.circular(12)),
          child: Text(me.bio.isEmpty ? '这个人很懒，什么都没写～' : me.bio,
              style: TextStyle(fontSize: 13.5, color: p.inkMuted, height: 1.6)),
        ),
        const SizedBox(height: 16),
        Text('更多资料',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: p.surface, borderRadius: BorderRadius.circular(12)),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('暂未填写',
                      style: TextStyle(fontSize: 13, color: p.inkSubtle)))
              : Column(children: [
                  for (final (i, e) in rows.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          border: i == rows.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: p.divider))),
                      child: Row(children: [
                        SizedBox(
                            width: 80,
                            child: Text(e.value,
                                style: TextStyle(
                                    fontSize: 13, color: p.inkSubtle))),
                        Expanded(
                            child: Text(me.fields[e.key]!,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.ink))),
                      ]),
                    ),
                ]),
        ),
        if (me.modifiedAt > 0) ...[
          const SizedBox(height: 10),
          Text('资料修改日期：${fmtDateTime(me.modifiedAt)}',
              style: TextStyle(fontSize: 11, color: p.inkSubtle)),
        ],
      ]),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<Post> posts;
  const _PostsTab({required this.posts});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(children: [
          Icon(Icons.article_outlined, size: 44, color: p.inkSubtle),
          const SizedBox(height: 10),
          Text('还没有发布动态', style: TextStyle(fontSize: 13, color: p.inkSubtle)),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        for (final post in posts) PostCard(post: post),
      ]),
    );
  }
}

/// Reusable post card (used by 我的主页 · 动态 and lists).
class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final st = switch (post.status) {
      'approved' => null,
      'rejected' => ('已驳回', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => ('待审核', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: p.shadowSm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SeedAvatar(seed: post.authorUid == '800123' ? 'me' : post.author, size: 34, label: post.author),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink)),
              Text(fmtDateTime(post.ts),
                  style: TextStyle(fontSize: 11, color: p.inkSubtle)),
            ]),
          ),
          if (st != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: st.$2, borderRadius: BorderRadius.circular(999)),
              child: Text(st.$1,
                  style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w700, color: st.$3)),
            ),
        ]),
        const SizedBox(height: 10),
        Text(post.text,
            style: TextStyle(fontSize: 14, color: p.ink, height: 1.55)),
        if (post.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final im in post.images.take(9))
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SeedPlaceholder(seed: im, width: 92, height: 92)),
          ]),
        ],
        if (post.poll != null) ...[
          const SizedBox(height: 10),
          _PollView(poll: post.poll!),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: p.primarySoft, borderRadius: BorderRadius.circular(999)),
            child: Text(
                post.type == 'circle'
                    ? '#${post.circle?.label ?? ''}'
                    : '#${post.topic?.name ?? ''}#',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: p.primary)),
          ),
          const Spacer(),
          if (post.hasVideo) ...[
            Icon(Icons.videocam_outlined, size: 15, color: p.inkSubtle),
            const SizedBox(width: 10),
          ],
          Icon(Icons.favorite_border, size: 15, color: p.inkSubtle),
          const SizedBox(width: 3),
          Text('${post.likes}', style: TextStyle(fontSize: 11.5, color: p.inkSubtle)),
          const SizedBox(width: 10),
          Icon(Icons.chat_bubble_outline, size: 14, color: p.inkSubtle),
          const SizedBox(width: 3),
          Text('${post.comments}',
              style: TextStyle(fontSize: 11.5, color: p.inkSubtle)),
        ]),
      ]),
    );
  }
}

class _PollView extends StatelessWidget {
  final Poll poll;
  const _PollView({required this.poll});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final total = poll.options.fold<int>(0, (a, o) => a + o.votes);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: p.bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.emoji_events_outlined, size: 14, color: p.primary),
          const SizedBox(width: 4),
          Text(poll.question,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        ]),
        const SizedBox(height: 8),
        for (final o in poll.options) ...[
          Stack(children: [
            Container(
                height: 30,
                decoration: BoxDecoration(
                    color: p.surface, borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: total == 0 ? 0 : o.votes / total,
              child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      color: p.primarySoft,
                      borderRadius: BorderRadius.circular(6))),
            ),
            SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  Expanded(
                      child: Text(o.text,
                          style: TextStyle(fontSize: 12.5, color: p.ink))),
                  Text('${o.votes} 票',
                      style: TextStyle(fontSize: 11, color: p.inkSubtle)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }
}
