import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_service.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum PublishKind { circle, forum }

/// 17 PublishCircle / 18 PublishForum — shared composer.
///
/// Rules (handoff): text ≤2000, images ≤8 (≤500KB each), video ≤5MB/60s,
/// poll title ≤40 + 2–5 options ≤20, circle/topic required, 发帖规则
/// pre-ticked (untick ⇒ cannot submit), unsent draft persists until success.
class PublishPage extends StatefulWidget {
  final PublishKind kind;
  const PublishPage({super.key, required this.kind});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  static const maxLen = 2000;
  static const maxImages = 8;
  static const maxPollOptions = 5;

  final _text = TextEditingController();
  final _pollQ = TextEditingController();
  final List<TextEditingController> _pollOpts = [];
  final List<String> _images = []; // seeds standing in for uploaded images
  bool _hasVideo = false;
  bool _pollOn = false;
  bool _rulesAgreed = true;
  CircleRef? _circle;
  TopicRef? _topic;
  bool _submitting = false;
  bool _loaded = false;

  String get _draftKey => 'publish_draft_${widget.kind.name}';
  bool get isCircle => widget.kind == PublishKind.circle;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _text.addListener(_onChanged);
    _pollQ.addListener(_onChanged);
  }

  @override
  void dispose() {
    _text.dispose();
    _pollQ.dispose();
    for (final c in _pollOpts) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    _saveDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _text.text = j['text'] as String? ?? '';
        _images.addAll(((j['images'] as List?) ?? []).map((e) => e.toString()));
        _hasVideo = j['hasVideo'] as bool? ?? false;
        _rulesAgreed = !(j['rulesOptOut'] as bool? ?? false);
        if (j['poll'] is Map) {
          _pollOn = true;
          _pollQ.text = (j['poll']['question'] as String?) ?? '';
          for (final o in (j['poll']['options'] as List? ?? [])) {
            _pollOpts.add(TextEditingController(text: o.toString())
              ..addListener(_onChanged));
          }
        }
        if (j['circle'] is Map) {
          _circle = CircleRef.fromJson(j['circle'] as Map<String, dynamic>);
        }
        if (j['topic'] is Map) {
          _topic = TopicRef.fromJson(j['topic'] as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    if (_pollOn && _pollOpts.length < 2) _ensurePollOptions();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveDraft() async {
    if (!_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _draftKey,
        jsonEncode({
          'text': _text.text,
          'images': _images,
          'hasVideo': _hasVideo,
          'rulesOptOut': !_rulesAgreed,
          'poll': _pollOn
              ? {
                  'question': _pollQ.text,
                  'options': _pollOpts.map((c) => c.text).toList()
                }
              : null,
          'circle': _circle?.toJson(),
          'topic': _topic?.toJson(),
        }));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _ensurePollOptions() {
    while (_pollOpts.length < 2) {
      _pollOpts.add(TextEditingController()..addListener(_onChanged));
    }
  }

  // ── Media pickers (demo: adds a placeholder tile; real app → image_picker) ──
  void _pickImage() {
    if (_images.length >= maxImages) {
      showToast(context, '最多上传 $maxImages 张图片');
      return;
    }
    final p = context.pRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _addImage('cam');
              }),
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              subtitle: Text('每张 ≤ 500KB，超出自动压缩',
                  style: TextStyle(fontSize: 11, color: p.inkSubtle)),
              onTap: () {
                Navigator.pop(ctx);
                _addImage('album');
              }),
        ]),
      ),
    );
  }

  void _addImage(String src) {
    setState(() => _images
        .add('$src-${DateTime.now().millisecondsSinceEpoch}-${_images.length}'));
    _saveDraft();
  }

  void _pickVideo() {
    if (_hasVideo) {
      setState(() => _hasVideo = false);
      _saveDraft();
      showToast(context, '已移除视频');
      return;
    }
    setState(() => _hasVideo = true);
    _saveDraft();
    showToast(context, '视频已添加（≤ 5MB / 60 秒，超出自动压缩）');
  }

  void _togglePoll() {
    if (_pollOn) return;
    setState(() {
      _pollOn = true;
      _ensurePollOptions();
    });
    _saveDraft();
  }

  void _removePoll() {
    setState(() {
      _pollOn = false;
      _pollQ.clear();
      for (final c in _pollOpts) {
        c.dispose();
      }
      _pollOpts.clear();
    });
    _saveDraft();
  }

  bool get _pollValid =>
      !_pollOn ||
      (_pollQ.text.trim().isNotEmpty &&
          _pollOpts.where((c) => c.text.trim().isNotEmpty).length >= 2);

  bool get _canSubmit =>
      !_submitting &&
      _rulesAgreed &&
      (_text.text.trim().isNotEmpty || _images.isNotEmpty || _hasVideo) &&
      (isCircle ? _circle != null : _topic != null) &&
      _pollValid;

  Future<void> _submit() async {
    if (!_canSubmit) {
      if (!_rulesAgreed) {
        showToast(context, '请先阅读并勾选同意《发帖规则》');
      } else if (isCircle && _circle == null) {
        showToast(context, '请选择圈子');
      } else if (!isCircle && _topic == null) {
        showToast(context, '请选择话题');
      } else if (!_pollValid) {
        showToast(context, '投票需要标题和至少 2 个选项');
      } else {
        showToast(context, '请输入内容');
      }
      return;
    }
    setState(() => _submitting = true);
    final state = context.read<AppState>();
    try {
      if (!state.online) {
        throw ApiException(0, '网络不可用，草稿已保留，请稍后重试');
      }
      await state.api.createPost({
        'type': widget.kind.name,
        'text': _text.text.trim(),
        'images': _images,
        'hasVideo': _hasVideo,
        'poll': _pollOn
            ? {
                'question': _pollQ.text.trim(),
                'options': _pollOpts
                    .where((c) => c.text.trim().isNotEmpty)
                    .map((c) => {'text': c.text.trim()})
                    .toList()
              }
            : null,
        'circle': _circle?.toJson(),
        'topic': _topic?.toJson(),
        'rulesAgreed': _rulesAgreed,
        'author': state.profile.name,
      });
      await _clearDraft();
      if (!mounted) return;
      showToast(context, '发布成功，等待管理员审核');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // Fail loudly — keep the draft.
      showToast(context, e.toString());
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final len = _text.text.length;
    final nearLimit = len >= maxLen * 0.9;
    final accent = isCircle ? p.sky : p.accent;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: SubHeader(title: isCircle ? '圈子发布' : '论坛发布'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title pill + required + counter
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: isCircle
                            ? const LinearGradient(colors: [
                                Color(0xFF67E8F9),
                                Color(0xFF38BDF8),
                                Color(0xFF0EA5E9)
                              ])
                            : const LinearGradient(colors: [
                                Color(0xFFFDE68A),
                                Color(0xFFFCD34D),
                                Color(0xFFF59E0B)
                              ]),
                        boxShadow: [
                          BoxShadow(
                              color: accent.withValues(alpha: 0.33),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25)),
                          child: const Text('#',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Text(isCircle ? '圈子帖子' : '论坛话题',
                            style: TextStyle(
                                color:
                                    isCircle ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Text('*',
                        style: TextStyle(
                            color: p.pink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const Spacer(),
                    Text('$len/$maxLen',
                        style: TextStyle(
                            fontSize: 12,
                            color: nearLimit ? p.pink : p.inkSubtle,
                            fontWeight:
                                nearLimit ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                  const SizedBox(height: 12),
                  // Text area
                  Container(
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      color: p.divider.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _text,
                      maxLength: maxLen,
                      maxLines: null,
                      minLines: 9,
                      style: TextStyle(
                          fontSize: 14, color: p.ink, height: 1.6),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                        hintText: isCircle
                            ? '分享你的想法、图片或视频…'
                            : '发起一个话题，说说你的观点…',
                        hintStyle: TextStyle(color: p.inkSubtle),
                      ),
                    ),
                  ),
                  // Image grid 4 cols
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6),
                      itemBuilder: (_, i) => Stack(children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SeedPlaceholder(seed: _images[i], radius: 8),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _images.removeAt(i));
                              _saveDraft();
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xB30F172A)),
                              child: const Icon(Icons.close,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  // Video chip
                  if (_hasVideo) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(children: [
                        const Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 44, color: Colors.white70)),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: _pickVideo,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x66FFFFFF)),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 8,
                          child: Text('视频 · ≤ 5MB / 60s',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8))),
                        ),
                      ]),
                    ),
                  ],
                  // Poll editor
                  if (_pollOn) ...[
                    const SizedBox(height: 12),
                    _PollEditor(
                      question: _pollQ,
                      options: _pollOpts,
                      onAdd: () {
                        if (_pollOpts.length >= maxPollOptions) return;
                        setState(() => _pollOpts.add(
                            TextEditingController()..addListener(_onChanged)));
                      },
                      onRemove: (i) {
                        if (_pollOpts.length <= 2) return;
                        setState(() => _pollOpts.removeAt(i).dispose());
                        _saveDraft();
                      },
                      onDelete: _removePoll,
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Action row: 图片 / 视频 / 投票
                  Row(children: [
                    _Action(
                        icon: Icons.image_outlined,
                        label: '图片',
                        active: _images.isNotEmpty,
                        onTap: _pickImage),
                    const SizedBox(width: 28),
                    _Action(
                        icon: Icons.play_circle_outline_rounded,
                        label: '视频',
                        active: _hasVideo,
                        onTap: _pickVideo),
                    const SizedBox(width: 28),
                    _Action(
                        icon: Icons.emoji_events_outlined,
                        label: '投票',
                        active: _pollOn,
                        onTap: _togglePoll),
                  ]),
                  const SizedBox(height: 18),
                  // Circle / topic picker row
                  _PickerRow(
                    icon: isCircle
                        ? Icons.local_florist_outlined
                        : Icons.tag_rounded,
                    label: isCircle ? '选择圈子' : '选择话题',
                    hint: isCircle ? '请选择圈子' : '请选择话题',
                    value: isCircle ? _circle?.label : _topic?.name,
                    onClear: () {
                      setState(() {
                        _circle = null;
                        _topic = null;
                      });
                      _saveDraft();
                    },
                    onPick: () async {
                      if (isCircle) {
                        final r = await showModalBottomSheet<CircleRef>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CirclePickerSheet(),
                        );
                        if (r != null) setState(() => _circle = r);
                      } else {
                        final r = await showModalBottomSheet<TopicRef>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const TopicPickerSheet(),
                        );
                        if (r != null) setState(() => _topic = r);
                      }
                      _saveDraft();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Rules pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _rulesAgreed ? Tint.mint.bg : p.divider,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: _rulesAgreed
                              ? p.mint.withValues(alpha: 0.33)
                              : Colors.transparent),
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _rulesAgreed = !_rulesAgreed);
                          _saveDraft();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _rulesAgreed ? p.mint : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _rulesAgreed ? p.mint : p.inkSubtle,
                                width: 1.5),
                          ),
                          child: _rulesAgreed
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => showLegalSheet(context, 'rules'),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _rulesAgreed ? p.mint : p.inkMuted),
                              children: [
                                const TextSpan(text: '我已阅读并同意 '),
                                TextSpan(
                                    text: '《发帖规则》',
                                    style: TextStyle(
                                        color: p.sky,
                                        decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          // Submit bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.divider))),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _canSubmit ? p.mint : const Color(0xFFCBD5E1),
                    boxShadow: _canSubmit
                        ? [
                            BoxShadow(
                                color: p.mint.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ]
                        : null,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('确定发布',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Action(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final c = active ? p.primary : p.inkMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Icon(icon, size: 24, color: c),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: c,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ]),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _PickerRow(
      {required this.icon,
      required this.label,
      required this.hint,
      required this.value,
      required this.onPick,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final selected = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected ? p.primary.withValues(alpha: 0.33) : p.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: p.violet),
        const SizedBox(width: 10),
        if (selected) ...[
          Expanded(
            child: Text('#$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 26,
              height: 26,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: p.divider),
              child: Icon(Icons.close, size: 13, color: p.inkMuted),
            ),
          ),
        ] else
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              behavior: HitTestBehavior.opaque,
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(label,
                            style:
                                TextStyle(fontSize: 11, color: p.inkSubtle)),
                        const SizedBox(width: 4),
                        Text('*',
                            style: TextStyle(
                                color: p.pink, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 2),
                      Text(hint,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: p.inkSubtle)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: p.inkSubtle),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _PollEditor extends StatelessWidget {
  final TextEditingController question;
  final List<TextEditingController> options;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onDelete;
  const _PollEditor(
      {required this.question,
      required this.options,
      required this.onAdd,
      required this.onRemove,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    InputDecoration deco(String hint) => InputDecoration(
          isDense: true,
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: p.inkSubtle, fontSize: 13),
          filled: true,
          fillColor: p.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: p.primarySoft, borderRadius: BorderRadius.circular(999)),
            child: Text('投票 · 单选',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.primary)),
          ),
          const Spacer(),
          GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline, size: 18, color: p.inkSubtle)),
        ]),
        const SizedBox(height: 10),
        TextField(
            controller: question,
            maxLength: 40,
            style: TextStyle(fontSize: 13.5, color: p.ink),
            decoration: deco('请输入投票标题')),
        const SizedBox(height: 8),
        for (int i = 0; i < options.length; i++) ...[
          Row(children: [
            Expanded(
              child: TextField(
                  controller: options[i],
                  maxLength: 20,
                  style: TextStyle(fontSize: 13, color: p.ink),
                  decoration: deco('选项 ${i + 1}')),
            ),
            if (options.length > 2) ...[
              const SizedBox(width: 6),
              GestureDetector(
                  onTap: () => onRemove(i),
                  child: Icon(Icons.remove_circle_outline,
                      size: 18, color: p.inkSubtle)),
            ],
          ]),
          const SizedBox(height: 6),
        ],
        if (options.length < 5)
          GestureDetector(
            onTap: onAdd,
            child: Row(children: [
              Icon(Icons.add_circle_outline, size: 16, color: p.primary),
              const SizedBox(width: 4),
              Text('添加选项',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: p.primary,
                      fontWeight: FontWeight.w600)),
            ]),
          )
        else
          Text('已达上限（最多 5 个选项）',
              style: TextStyle(fontSize: 11.5, color: p.inkSubtle)),
      ]),
    );
  }
}

/// 两栏「选择圈子」弹窗 — 一级分类 | 二级圈子
class CirclePickerSheet extends StatefulWidget {
  const CirclePickerSheet({super.key});

  @override
  State<CirclePickerSheet> createState() => _CirclePickerSheetState();
}

class _CirclePickerSheetState extends State<CirclePickerSheet> {
  List<CircleGroup>? _groups;
  int _l1 = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final g = await state.api.circles();
      if (mounted) setState(() => _groups = g);
    } catch (_) {
      if (mounted) {
        setState(() => _groups = [
              CircleGroup(id: 'all', label: '全部圈子', children: [
                for (final c in kFollowedCircles)
                  CircleRef(id: c.seed, label: c.name, sub: c.sub)
              ])
            ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final groups = _groups;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: p.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(children: [
            Text('选择圈子',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
            const Spacer(),
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 20, color: p.inkMuted)),
          ]),
        ),
        Divider(height: 1, color: p.divider),
        Expanded(
          child: groups == null
              ? const Center(child: CircularProgressIndicator())
              : Row(children: [
                  Container(
                    width: 110,
                    color: p.bg,
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final active = i == _l1;
                        return GestureDetector(
                          onTap: () => setState(() => _l1 = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            color: active ? p.surface : Colors.transparent,
                            child: Row(children: [
                              Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: active
                                          ? p.primary
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(groups[i].label,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color:
                                            active ? p.ink : p.inkMuted)),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final c in groups[_l1].children)
                          GestureDetector(
                            onTap: () => Navigator.pop(context, c),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: p.bg,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SeedPlaceholder(
                                      seed: 'hc-${c.id}',
                                      width: 44,
                                      height: 44),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: p.ink)),
                                      if (c.sub.isNotEmpty)
                                        Text(c.sub,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                color: p.inkSubtle)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18, color: p.inkSubtle),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
        ),
      ]),
    );
  }
}

/// 选择话题 — grouped by 一级 category
class TopicPickerSheet extends StatefulWidget {
  const TopicPickerSheet({super.key});

  @override
  State<TopicPickerSheet> createState() => _TopicPickerSheetState();
}

class _TopicPickerSheetState extends State<TopicPickerSheet> {
  List<TopicRef>? _topics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await context.read<AppState>().api.topics();
      if (mounted) setState(() => _topics = t);
    } catch (_) {
      if (mounted) {
        setState(() => _topics = [
              for (final t in kTopics)
                TopicRef(
                    id: t.seed, name: t.name, category: t.category, posts: t.posts)
            ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final topics = _topics;
    final groups = <String, List<TopicRef>>{};
    for (final t in topics ?? []) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: p.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(children: [
            Text('选择话题',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
            const Spacer(),
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 20, color: p.inkMuted)),
          ]),
        ),
        Divider(height: 1, color: p.divider),
        Expanded(
          child: topics == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (final e in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                        child: Text(e.key,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.inkSubtle)),
                      ),
                      for (final t in e.value)
                        GestureDetector(
                          onTap: () => Navigator.pop(context, t),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                                color: p.bg,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Text('#',
                                  style: TextStyle(
                                      color: p.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(t.name,
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: p.ink))),
                              Text('${t.posts} 帖子',
                                  style: TextStyle(
                                      fontSize: 11, color: p.inkSubtle)),
                            ]),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

/// 发帖规则 / 免责声明 bottom sheet (content from admin 协议与规则).
Future<void> showLegalSheet(BuildContext context, String key) async {
  final p = context.pRead;
  final state = context.read<AppState>();
  LegalDoc doc;
  try {
    doc = await state.api.legal(key);
  } catch (_) {
    doc = LegalDoc(title: key == 'rules' ? '发帖规则' : '免责声明', sections: [
      (h: '一、基本原则', p: '遵守法律法规，尊重他人，禁止发布违法、色情、暴力、谣言等内容。'),
      (h: '二、内容要求', p: '帖子需与所选圈子 / 话题相关；图片每张不超过 500KB，视频不超过 5MB 或 60 秒。'),
      (h: '三、审核机制', p: '所有帖子提交后进入待审核状态，管理员审核通过后方可展示。'),
    ]);
  }
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: p.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(doc.title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            children: [
              for (final s in doc.sections) ...[
                if (s.h.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(s.h,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink)),
                  ),
                Text(s.p,
                    style: TextStyle(
                        fontSize: 13.5, color: p.inkMuted, height: 1.7)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(999)),
              child: const Text('我已阅读',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    ),
  );
}
