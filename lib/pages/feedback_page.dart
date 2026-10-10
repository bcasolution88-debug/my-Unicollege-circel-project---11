import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 反馈信息 — 3 category pills, form (标题 ≤80, 描述 ≤500 *, 联系方式 *, ≤5 images),
/// top-right 官方回复 with unread badge.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const cats = [
    ('circle', '圈子与论坛反馈'),
    ('news', '新闻与热推反馈'),
    ('other', '其它反馈'),
  ];
  static const maxImages = 5;

  String _cat = 'circle';
  final _subject = TextEditingController();
  final _desc = TextEditingController();
  final _contact = TextEditingController();
  final List<String> _images = [];
  bool _sending = false;
  List<FeedbackItem> _mine = [];

  @override
  void initState() {
    super.initState();
    for (final c in [_subject, _desc, _contact]) {
      c.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMine());
  }

  @override
  void dispose() {
    _subject.dispose();
    _desc.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    final state = context.read<AppState>();
    if (!state.online) return;
    try {
      final l = await state.api.feedback();
      if (mounted) setState(() => _mine = l);
    } catch (_) {}
  }

  bool get _canSubmit =>
      !_sending && _desc.text.trim().isNotEmpty && _contact.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) {
      showToast(context, _desc.text.trim().isEmpty ? '请填写意见描述' : '请填写联系方式');
      return;
    }
    setState(() => _sending = true);
    final state = context.read<AppState>();
    try {
      if (!state.online) throw Exception('网络不可用，请稍后重试');
      await state.api.createFeedback({
        'cat': _cat,
        'subject': _subject.text.trim(),
        'desc': _desc.text.trim(),
        'contact': _contact.text.trim(),
        'images': _images,
      });
      if (!mounted) return;
      showToast(context, '提交成功，我们会尽快处理');
      _subject.clear();
      _desc.clear();
      _contact.clear();
      setState(() => _images.clear());
      _loadMine();
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.palette;
    final replyCount = _mine.where((f) => f.replies.isNotEmpty).length;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.inkSubtle, fontSize: 13.5),
          counterText: '',
          filled: true,
          fillColor: p.surface,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.primary)),
        );

    return Scaffold(
      backgroundColor: p.bg,
      appBar: SubHeader(title: '反馈信息', actions: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _RepliesPage(items: _mine, cats: cats))),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: p.primarySoft, borderRadius: BorderRadius.circular(999)),
              child: Text('官方回复',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.primary)),
            ),
            if (state.unread.feedback > 0 || replyCount > 0)
              Positioned(
                  top: -5,
                  right: -5,
                  child: CountBadge(
                      count: state.unread.feedback > 0
                          ? state.unread.feedback
                          : replyCount,
                      borderColor: p.surface,
                      height: 16)),
          ]),
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Category pills
          Row(children: [
            for (final c in cats) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cat = c.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: _cat == c.$1
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                          : null,
                      color: _cat == c.$1 ? null : p.surface,
                      border: Border.all(
                          color: _cat == c.$1 ? Colors.transparent : p.divider),
                    ),
                    child: Text(c.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _cat == c.$1 ? Colors.white : p.inkMuted)),
                  ),
                ),
              ),
              if (c != cats.last) const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 18),
          _label(p, '意见标题', false, '${_subject.text.length} / 80'),
          const SizedBox(height: 6),
          TextField(
              controller: _subject,
              maxLength: 80,
              style: TextStyle(fontSize: 14, color: p.ink),
              decoration: deco('简要描述问题（选填）')),
          const SizedBox(height: 14),
          _label(p, '意见描述', true, '${_desc.text.length} / 500'),
          const SizedBox(height: 6),
          TextField(
              controller: _desc,
              maxLength: 500,
              minLines: 5,
              maxLines: 8,
              style: TextStyle(fontSize: 14, color: p.ink, height: 1.5),
              decoration: deco('请详细描述你遇到的问题或建议')),
          const SizedBox(height: 14),
          _label(p, '联系方式', true, ''),
          const SizedBox(height: 6),
          TextField(
              controller: _contact,
              style: TextStyle(fontSize: 14, color: p.ink),
              decoration: deco('邮箱 / 手机 / 微信，方便我们联系你')),
          const SizedBox(height: 14),
          _label(p, '上传图片', false, '${_images.length} / $maxImages'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < _images.length; i++)
              Stack(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SeedPlaceholder(
                        seed: _images[i], width: 72, height: 72, radius: 10)),
                Positioned(
                  top: 3,
                  right: 3,
                  child: GestureDetector(
                    onTap: () => setState(() => _images.removeAt(i)),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xB30F172A)),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            if (_images.length < maxImages)
              GestureDetector(
                onTap: () => setState(() => _images
                    .add('fb-${DateTime.now().millisecondsSinceEpoch}')),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.divider),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: p.inkSubtle),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text('每张 ≤ 500KB，超出自动压缩',
              style: TextStyle(fontSize: 11, color: p.inkSubtle)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: _canSubmit
                    ? const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                    : null,
                color: _canSubmit ? null : const Color(0xFFCBD5E1),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('提交反馈',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(p, String t, bool req, String counter) => Row(children: [
        Text(t,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        if (req)
          Text(' *',
              style: TextStyle(color: p.pink, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(counter, style: TextStyle(fontSize: 11, color: p.inkSubtle)),
      ]);
}

class _RepliesPage extends StatelessWidget {
  final List<FeedbackItem> items;
  final List<(String, String)> cats;
  const _RepliesPage({required this.items, required this.cats});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    String catLabel(String id) =>
        cats.firstWhere((c) => c.$1 == id, orElse: () => ('', '其它反馈')).$2;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '官方回复'),
      body: items.isEmpty
          ? Center(
              child: Text('暂无反馈记录', style: TextStyle(color: p.inkSubtle)))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final f = items[i];
                final st = switch (f.status) {
                  'done' => ('已处理', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                  'doing' => ('处理中', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
                  _ => ('待处理', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
                };
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: p.shadowSm),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: p.primarySoft,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(catLabel(f.cat),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: p.primary)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: st.$2,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(st.$1,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: st.$3)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(f.subject.isEmpty ? '（无标题）' : f.subject,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink)),
                    const SizedBox(height: 4),
                    Text(f.desc,
                        style: TextStyle(
                            fontSize: 13, color: p.inkMuted, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(fmtDateTime(f.ts),
                        style: TextStyle(fontSize: 11, color: p.inkSubtle)),
                    for (final r in f.replies) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: p.bg, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.verified_rounded,
                                    size: 14, color: p.primary),
                                const SizedBox(width: 4),
                                Text(r.operator,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: p.primary)),
                                const Spacer(),
                                Text(fmtDateTime(r.ts),
                                    style: TextStyle(
                                        fontSize: 11, color: p.inkSubtle)),
                              ]),
                              const SizedBox(height: 6),
                              Text(r.text,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: p.ink,
                                      height: 1.5)),
                            ]),
                      ),
                    ],
                  ]),
                );
              },
            ),
    );
  }
}
