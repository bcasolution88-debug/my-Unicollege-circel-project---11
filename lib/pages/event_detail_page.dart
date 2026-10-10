import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

/// 活动详情 — views +1 per open, 报名 / 取消报名 toggle shared with the list.
class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().bumpView(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final ev = state.eventById(widget.eventId);
    if (ev == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: const SubHeader(title: '活动详情'),
        body: Center(
            child: Text('活动不存在', style: TextStyle(color: p.inkSubtle))),
      );
    }
    final joined = state.joined(ev.id);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '活动详情'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SeedPlaceholder(seed: ev.seed, height: 190, radius: 16),
            ),
            const SizedBox(height: 16),
            Text(ev.title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                    height: 1.4)),
            const SizedBox(height: 10),
            Row(
              children: [
                SeedAvatar(seed: ev.author, size: 22, label: ev.author),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ev.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                ),
                Icon(Icons.remove_red_eye_outlined,
                    size: 13, color: p.inkSubtle),
                const SizedBox(width: 3),
                Text('${ev.views}',
                    style: TextStyle(fontSize: 11.5, color: p.inkSubtle)),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(children: [
              _InfoRow(Icons.calendar_today_outlined, '时间',
                  '${ev.date}  ${ev.time}'),
              Divider(height: 18, color: p.divider),
              _InfoRow(Icons.place_outlined, '地点', ev.place),
              Divider(height: 18, color: p.divider),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: p.primary),
                  const SizedBox(width: 10),
                  Text('已报名',
                      style: TextStyle(fontSize: 13, color: p.inkSubtle)),
                  const SizedBox(width: 12),
                  if (ev.signups.isNotEmpty)
                    StackedAvatars(users: ev.signups, size: 24),
                  const SizedBox(width: 8),
                  Text('${ev.signups.length} 人',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.ink)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            Text('活动详情',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 8),
            _InfoCard(children: [
              Text(ev.detail,
                  style: TextStyle(
                      fontSize: 14, color: p.inkMuted, height: 1.7)),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () async {
              final now =
                  await context.read<AppState>().toggleJoin(ev.id);
              if (!context.mounted) return;
              showToast(context, now ? '报名成功' : '已取消报名');
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: joined
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                color: joined ? p.mintSoft : null,
                boxShadow: joined
                    ? null
                    : const [
                        BoxShadow(
                            color: Color(0x404F46E5),
                            blurRadius: 16,
                            offset: Offset(0, 6)),
                      ],
              ),
              child: Text(
                joined ? '已报名 · 点击取消' : '立即报名',
                style: TextStyle(
                  color: joined ? const Color(0xFF047857) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: p.shadowSm,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      children: [
        Icon(icon, size: 16, color: p.primary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: p.inkSubtle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
        ),
      ],
    );
  }
}
