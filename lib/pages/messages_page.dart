import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'feedback_page.dart';
import 'service_page.dart';
import 'sysnotify_page.dart';
import 'user_chat_page.dart';

/// 04 Messages — 4 tiles with red unread badges + DM list.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Conversation>? _convs;
  String? _err;

  static const _seed = [
    ('allanliu6', 'allanliu6', 'f', '很高兴认识你，欢迎随时聊聊', '10:32'),
    ('weichen', 'weichen', 'm', 'Thanks for the reply, appreciate it.', '09:18'),
    ('yy2026', '兴趣组团YY', 'f', '一起来玩呀，周末有活动', '昨天'),
    ('shier', '十二', 'm', '收到，稍后联系你', '1-06'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (!state.online) {
      setState(() => _convs = [
            for (final s in _seed)
              Conversation(
                  peer: s.$1, name: s.$2, gender: s.$3, preview: s.$4, ts: 0)
          ]);
      return;
    }
    try {
      final c = await state.api.chats();
      if (mounted) setState(() => _convs = c);
    } catch (e) {
      if (mounted) setState(() => _err = '加载失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final u = state.unread;

    final cats = [
      (
        key: 'share',
        icon: Icons.local_fire_department_outlined,
        label: '平台分享',
        tint: Tint.pink,
        badge: u.share,
        onTap: () {
          state.clearUnread('share');
          _showShareSheet(context);
        }
      ),
      (
        key: 'feedback',
        icon: Icons.local_florist_outlined,
        label: '反馈信息',
        tint: Tint.sky,
        badge: u.feedback,
        onTap: () {
          state.clearUnread('feedback');
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackPage()));
        }
      ),
      (
        key: 'sysnotify',
        icon: Icons.article_outlined,
        label: '系统通知',
        tint: Tint.violet,
        badge: u.sysnotify,
        onTap: () {
          state.clearUnread('sysnotify');
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SysNotifyPage()));
        }
      ),
      (
        key: 'service',
        icon: Icons.star_border_rounded,
        label: '客服中心',
        tint: Tint.amber,
        badge: u.service,
        onTap: () {
          state.clearUnread('service');
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ServicePage()));
        }
      ),
    ];

    final convs = _convs;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '我的消息'),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refresh();
          await _load();
        },
        child: ListView(
          children: [
            Container(
              color: p.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Row(
                children: [
                  for (final c in cats)
                    Expanded(
                      child: GestureDetector(
                        onTap: c.onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Column(children: [
                          Stack(clipBehavior: Clip.none, children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: c.tint.bg),
                              child: Icon(c.icon, size: 24, color: c.tint.fg),
                            ),
                            if (c.badge > 0)
                              Positioned(
                                  top: -3,
                                  right: -5,
                                  child: CountBadge(
                                      count: c.badge, borderColor: p.surface)),
                          ]),
                          const SizedBox(height: 8),
                          Text(c.label,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: p.ink)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('好友用户留言记录',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.inkMuted)),
                  if (u.usersTotal > 0)
                    Text('${u.usersTotal} 条未读',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.pink)),
                ],
              ),
            ),
            if (_err != null)
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_err!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.danger, fontSize: 13)))
            else if (convs == null)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()))
            else
              Container(
                color: p.surface,
                child: Column(children: [
                  for (int i = 0; i < convs.length; i++)
                    _ConvTile(
                      conv: convs[i],
                      badge: u.users[convs[i].peer] ?? 0,
                      last: i == convs.length - 1,
                      onTap: () async {
                        state.clearUnread('user', peer: convs[i].peer);
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => UserChatPage(
                                peer: convs[i].peer, name: convs[i].name)));
                        _load();
                      },
                    ),
                ]),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final p = context.pRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: p.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('平台分享',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PageView(children: [
              for (final s in const ['share-1', 'share-2', 'share-3'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SeedPlaceholder(
                        seed: s,
                        radius: 14,
                        child: const Center(
                            child: Text('圈子社区 · MY COMMUNITY',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)))),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Text('扫码下载圈子社区 APP，发现身边的兴趣圈子',
              style: TextStyle(fontSize: 13, color: p.inkMuted)),
          const SizedBox(height: 4),
          Text('长按图片保存到手机',
              style: TextStyle(fontSize: 12, color: p.inkSubtle)),
        ]),
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final int badge;
  final bool last;
  final VoidCallback onTap;
  const _ConvTile(
      {required this.conv,
      required this.badge,
      required this.last,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: p.divider))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(clipBehavior: Clip.none, children: [
            SeedAvatar(seed: conv.peer, size: 44, label: conv.name),
            if (badge > 0)
              Positioned(
                  top: -3,
                  right: -5,
                  child: CountBadge(count: badge, borderColor: p.surface)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(conv.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.ink)),
                ),
                if (conv.gender == 'f') ...[
                  const SizedBox(width: 4),
                  Icon(Icons.female_rounded, size: 13, color: p.pink)
                ],
                if (conv.gender == 'm') ...[
                  const SizedBox(width: 4),
                  Icon(Icons.male_rounded, size: 13, color: p.sky)
                ],
              ]),
              const SizedBox(height: 2),
              Text(conv.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.inkSubtle)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(fmtTime(conv.ts),
              style: TextStyle(fontSize: 11, color: p.inkSubtle)),
        ]),
      ),
    );
  }
}
