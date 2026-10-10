import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 系统通知 — list; tap opens detail popup.
class SysNotifyPage extends StatefulWidget {
  const SysNotifyPage({super.key});

  @override
  State<SysNotifyPage> createState() => _SysNotifyPageState();
}

class _SysNotifyPageState extends State<SysNotifyPage> {
  List<NotificationItem>? _items;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (!state.online) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() => _items = [
            NotificationItem(
                id: 'n3',
                title: '国庆假期客服时间',
                body: '国庆假期期间（10/1 – 10/7），在线客服服务时间调整为每天 10:00 – 18:00，感谢理解。',
                images: [],
                ts: now - 4 * 3600000),
            NotificationItem(
                id: 'n2',
                title: '新版本上线',
                body: 'APP 已更新至最新版本：新增短视频频道、圈子分享卡片，修复了若干已知问题。',
                images: [],
                ts: now - 86400000),
            NotificationItem(
                id: 'n1',
                title: '社区规范更新',
                body: '为营造良好的社区氛围，我们更新了《社区规范》，请大家文明发言、友善交流。',
                images: [],
                ts: now - 3 * 86400000),
          ]);
      return;
    }
    try {
      final l = await state.api.notifications();
      if (mounted) setState(() => _items = l);
    } catch (e) {
      if (mounted) setState(() => _err = '加载失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final items = _items;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '系统通知'),
      body: _err != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 40, color: p.danger),
              const SizedBox(height: 10),
              Text(_err!, style: TextStyle(color: p.inkMuted)),
              TextButton(onPressed: _load, child: const Text('重试')),
            ]))
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(
                      child: Text('暂无通知',
                          style: TextStyle(color: p.inkSubtle)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _NotifyCard(
                          item: items[i],
                          onTap: () => _showDetail(context, items[i])),
                    ),
    );
  }

  void _showDetail(BuildContext context, NotificationItem n) {
    final p = context.pRead;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: p.primarySoft),
                child: Icon(Icons.campaign_outlined, color: p.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(n.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.ink)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(fmtDateTime(n.ts),
                style: TextStyle(fontSize: 11, color: p.inkSubtle)),
            const SizedBox(height: 12),
            Text(n.body,
                style: TextStyle(fontSize: 14, color: p.inkMuted, height: 1.7)),
            for (final im in n.images) ...[
              const SizedBox(height: 10),
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SeedPlaceholder(seed: im, height: 140, radius: 10)),
            ],
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('知道了',
                      style: TextStyle(
                          color: p.primary, fontWeight: FontWeight.w700))),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NotifyCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotifyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: p.shadowSm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: p.primarySoft),
            child: Icon(Icons.notifications_none_rounded,
                color: p.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(item.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink))),
                Text(fmtTime(item.ts),
                    style: TextStyle(fontSize: 11, color: p.inkSubtle)),
              ]),
              const SizedBox(height: 4),
              Text(item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5, color: p.inkMuted, height: 1.5)),
            ]),
          ),
        ]),
      ),
    );
  }
}
