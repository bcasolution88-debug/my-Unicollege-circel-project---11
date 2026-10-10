import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 客服中心 — composer (avatar + input + emoji + image); long-press recall ≤3 min;
/// App shows last 90 days.
class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ServiceMsg> _msgs = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (!state.online) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _msgs = [
          ServiceMsg(
              id: 's1',
              who: 'agent',
              kind: 'text',
              text: '你好，这里是官方客服，请问有什么可以帮您？',
              image: '',
              ts: now - 1200000),
        ];
        _loading = false;
      });
      return;
    }
    try {
      final l = await state.api.serviceMsgs();
      if (mounted) {
        setState(() {
          _msgs = l;
          _loading = false;
        });
        _toBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final state = context.read<AppState>();
    setState(() => _sending = true);
    try {
      if (!state.online) throw Exception('网络不可用，请稍后重试');
      await state.api.serviceSend(text);
      _input.clear();
      await _load();
      state.clearUnread('service');
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _recall(ServiceMsg m) async {
    final state = context.read<AppState>();
    final age = DateTime.now().millisecondsSinceEpoch - m.ts;
    if (age > 3 * 60000) {
      showToast(context, '超过 3 分钟，无法撤回');
      return;
    }
    try {
      await state.api.serviceRecall(m.id);
      await _load();
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '客服中心'),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: p.primarySoft,
          child: Text('客服工作时间 10:00 – 18:00 · 消息保留 90 天 · 长按可撤回（3 分钟内）',
              style: TextStyle(fontSize: 11, color: p.primary)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(14),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) => _Bubble(
                      msg: _msgs[i],
                      selfName: state.profile.name,
                      onLongPress: _msgs[i].who == 'user' &&
                              _msgs[i].kind != 'recalled'
                          ? () => _recall(_msgs[i])
                          : null),
                ),
        ),
        _Composer(
          controller: _input,
          sending: _sending,
          onSend: _send,
          onImage: () => showToast(context, '图片上传（≤ 500KB，自动压缩）'),
          onEmoji: () {
            _input.text += '😊';
            _input.selection =
                TextSelection.collapsed(offset: _input.text.length);
          },
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ServiceMsg msg;
  final String selfName;
  final VoidCallback? onLongPress;
  const _Bubble({required this.msg, required this.selfName, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final me = msg.who == 'user';
    if (msg.kind == 'recalled') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: p.divider, borderRadius: BorderRadius.circular(999)),
            child: Text(me ? '你撤回了一条消息' : '对方撤回了一条消息',
                style: TextStyle(fontSize: 11, color: p.inkSubtle)),
          ),
        ),
      );
    }
    final avatar = me
        ? SeedAvatar(seed: 'me', size: 36, label: selfName)
        : Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])),
            child: const Icon(Icons.headset_mic_rounded,
                size: 18, color: Colors.white));
    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.66),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: me ? p.primary : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(me ? 14 : 4),
            bottomRight: Radius.circular(me ? 4 : 14),
          ),
          boxShadow: p.shadowSm,
        ),
        child: Text(msg.text,
            style: TextStyle(
                fontSize: 14, color: me ? Colors.white : p.ink, height: 1.5)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                me ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: me
                ? [bubble, const SizedBox(width: 8), avatar]
                : [avatar, const SizedBox(width: 8), bubble],
          ),
          Padding(
            padding: EdgeInsets.only(left: me ? 0 : 44, right: me ? 44 : 0, top: 3),
            child: Text(fmtDateTime(msg.ts),
                style: TextStyle(fontSize: 10, color: p.inkSubtle)),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final VoidCallback onEmoji;
  const _Composer(
      {required this.controller,
      required this.sending,
      required this.onSend,
      required this.onImage,
      required this.onEmoji});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final has = controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
          color: p.surface, border: Border(top: BorderSide(color: p.divider))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          SeedAvatar(seed: 'me', size: 32, label: state.profile.name),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: p.bg, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: p.ink),
                decoration: InputDecoration(
                  hintText: '输入消息…',
                  hintStyle: TextStyle(color: p.inkSubtle),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          IconButton(
              onPressed: onEmoji,
              icon: Icon(Icons.emoji_emotions_outlined, color: p.inkMuted)),
          IconButton(
              onPressed: onImage,
              icon: Icon(Icons.image_outlined, color: p.inkMuted)),
          GestureDetector(
            onTap: has && !sending ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: has ? p.primary : p.divider),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.send_rounded,
                      size: 18, color: has ? Colors.white : p.inkSubtle),
            ),
          ),
        ]),
      ),
    );
  }
}
