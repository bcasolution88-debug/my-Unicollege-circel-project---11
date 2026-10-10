import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 私聊 — before the other side replies you may send at most 2 messages;
/// then the input locks with an orange notice until a reply arrives.
class UserChatPage extends StatefulWidget {
  final String peer;
  final String name;
  const UserChatPage({super.key, required this.peer, required this.name});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ChatThread? _thread;
  bool _sending = false;
  String? _err;

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
      setState(() => _thread = ChatThread(
          peer: widget.peer,
          name: widget.name,
          gender: '',
          msgs: [],
          locked: false));
      return;
    }
    try {
      final t = await state.api.chat(widget.peer);
      if (mounted) {
        setState(() => _thread = t);
        _toBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _err = '加载失败：$e');
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final t = _thread;
    if (text.isEmpty || _sending || t == null || t.locked) return;
    final state = context.read<AppState>();
    setState(() => _sending = true);
    try {
      if (!state.online) throw ApiException(0, '网络不可用，请稍后重试');
      await state.api.chatSend(widget.peer, text);
      _input.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
      await _load();
    } catch (e) {
      if (mounted) showToast(context, '发送失败');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final t = _thread;
    final locked = t?.locked ?? false;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: SubHeader(title: widget.name),
      body: Column(children: [
        Expanded(
          child: _err != null
              ? Center(child: Text(_err!, style: TextStyle(color: p.danger)))
              : t == null
                  ? const Center(child: CircularProgressIndicator())
                  : t.msgs.isEmpty
                      ? Center(
                          child: Text('打个招呼吧 👋',
                              style: TextStyle(color: p.inkSubtle)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(14),
                          itemCount: t.msgs.length,
                          itemBuilder: (_, i) => _ChatBubble(
                              msg: t.msgs[i],
                              me: t.msgs[i].from == state.uid,
                              peer: widget.peer,
                              peerName: widget.name,
                              selfName: state.profile.name),
                        ),
        ),
        if (locked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            color: const Color(0xFFFFF7ED),
            child: Row(children: [
              const Icon(Icons.lock_clock_outlined,
                  size: 16, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('对方回复前最多发送 2 条消息，请等待对方回复后再继续',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9A3412), height: 1.4)),
              ),
            ]),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
          decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.divider))),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: locked ? p.divider : p.bg,
                      borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _input,
                    enabled: !locked,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(fontSize: 14, color: p.ink),
                    decoration: InputDecoration(
                      hintText: locked ? '等待对方回复…' : '发送私信…',
                      hintStyle: TextStyle(color: p.inkSubtle),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !locked && _input.text.trim().isNotEmpty
                          ? p.primary
                          : p.divider),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.send_rounded,
                          size: 18,
                          color: !locked && _input.text.trim().isNotEmpty
                              ? Colors.white
                              : p.inkSubtle),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final bool me;
  final String peer;
  final String peerName;
  final String selfName;
  const _ChatBubble(
      {required this.msg,
      required this.me,
      required this.peer,
      required this.peerName,
      required this.selfName});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final avatar = me
        ? SeedAvatar(seed: 'me', size: 36, label: selfName)
        : SeedAvatar(seed: peer, size: 36, label: peerName);
    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: me
            ? const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
            : null,
        color: me ? null : p.surface,
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
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            padding:
                EdgeInsets.only(left: me ? 0 : 44, right: me ? 44 : 0, top: 3),
            child: Text(fmtDateTime(msg.ts),
                style: TextStyle(fontSize: 10, color: p.inkSubtle)),
          ),
        ],
      ),
    );
  }
}
