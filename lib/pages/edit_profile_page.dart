import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 29 EditProfile — changes are submitted for admin review.
/// 头像/用户名/性别 → 2 chances total; other fields → 5 total.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const otherKeys = [
    ('company', '公司'),
    ('job', '职业'),
    ('role', '职务'),
    ('wechat', '微信号'),
    ('whatsapp', 'Whatsapp'),
    ('fb', 'FB'),
    ('ig', 'IG'),
  ];

  late Profile _cur;
  late String _gender;
  late String _avatar;
  late String _bg;
  late final TextEditingController _name;
  late final TextEditingController _bio;
  final Map<String, TextEditingController> _fields = {};
  ReviewSummary _summary = ReviewSummary.fallback;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cur = context.read<AppState>().profile;
    _gender = _cur.gender;
    _avatar = _cur.avatar;
    _bg = _cur.bgUrl;
    _name = TextEditingController(text: _cur.name)..addListener(_tick);
    _bio = TextEditingController(text: _cur.bio)..addListener(_tick);
    for (final k in otherKeys) {
      _fields[k.$1] = TextEditingController(text: _cur.fields[k.$1] ?? '')
        ..addListener(_tick);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  void _tick() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final state = context.read<AppState>();
    if (!state.online) return;
    try {
      final s = await state.api.reviews();
      if (mounted) setState(() => _summary = s);
    } catch (_) {}
  }

  /// CJK counts 2 units; total ≤ 20.
  int _units(String s) =>
      s.runes.fold(0, (a, r) => a + (r > 0x2E7F ? 2 : 1));

  Map<String, dynamic> get _coreDiff => {
        if (_avatar != _cur.avatar) 'avatar': _avatar,
        if (_name.text.trim() != _cur.name) 'name': _name.text.trim(),
        if (_gender != _cur.gender) 'gender': _gender,
      };

  Map<String, dynamic> get _otherDiff => {
        if (_bio.text.trim() != _cur.bio) 'bio': _bio.text.trim(),
        if (_bg != _cur.bgUrl) 'bgUrl': _bg,
        for (final k in otherKeys)
          if ((_fields[k.$1]!.text.trim()) != (_cur.fields[k.$1] ?? ''))
            k.$1: _fields[k.$1]!.text.trim(),
      };

  bool get _blockCore => _coreDiff.isNotEmpty && _summary.coreLeft <= 0;
  bool get _blockOther => _otherDiff.isNotEmpty && _summary.otherLeft <= 0;
  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      _units(_name.text.trim()) <= 20 &&
      _bio.text.trim().isNotEmpty &&
      (_coreDiff.isNotEmpty || _otherDiff.isNotEmpty) &&
      !_blockCore &&
      !_blockOther;

  Future<void> _save() async {
    if (!_canSave) {
      if (_blockCore) {
        showToast(context, '头像 / 用户名 / 性别修改次数已用完');
      } else if (_blockOther) {
        showToast(context, '其它资料修改次数已用完');
      } else if (_units(_name.text.trim()) > 20) {
        showToast(context, '昵称过长（中文 ≤10 字 / 英文 ≤20 字符）');
      } else if (_coreDiff.isEmpty && _otherDiff.isEmpty) {
        showToast(context, '资料没有变化');
      } else {
        showToast(context, '请填写昵称和自我介绍');
      }
      return;
    }
    final state = context.read<AppState>();
    setState(() => _saving = true);
    try {
      if (!state.online) throw ApiException(0, '网络不可用，请稍后重试');
      await state.api.submitReview(_coreDiff, _otherDiff);
      if (!mounted) return;
      showToast(context, '已提交，等待管理员审核通过后生效');
      await _loadReviews();
      // reset draft to current (unchanged until approved)
      setState(() {
        _gender = _cur.gender;
        _avatar = _cur.avatar;
        _bg = _cur.bgUrl;
        _name.text = _cur.name;
        _bio.text = _cur.bio;
        for (final k in otherKeys) {
          _fields[k.$1]!.text = _cur.fields[k.$1] ?? '';
        }
      });
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (_) {
      if (mounted) showToast(context, '提交失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Demo helper: simulate admin approving the latest pending submission.
  Future<void> _simulateApprove(ProfileReview r) async {
    final state = context.read<AppState>();
    try {
      await state.api.decideReview(r.id, 'approved');
      await state.reloadProfile();
      if (!mounted) return;
      setState(() {
        _cur = state.profile;
        _gender = _cur.gender;
        _avatar = _cur.avatar;
        _bg = _cur.bgUrl;
        _name.text = _cur.name;
        _bio.text = _cur.bio;
        for (final k in otherKeys) {
          _fields[k.$1]!.text = _cur.fields[k.$1] ?? '';
        }
      });
      await _loadReviews();
      if (mounted) showToast(context, '（演示）管理员已通过，资料已生效');
    } catch (e) {
      if (mounted) showToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isF = _gender == 'f';
    final gColor = isF ? p.pink : p.sky;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.inkSubtle, fontSize: 13.5),
          counterText: '',
          filled: true,
          fillColor: p.surface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.primary)),
        );

    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '资料修改'),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Review notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '资料修改需管理员审核通过后生效。头像 / 用户名 / 性别剩余 ${_summary.coreLeft}/${_summary.coreMax} 次；其它资料剩余 ${_summary.otherLeft}/${_summary.otherMax} 次（每次提交均计次）。',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF92400E), height: 1.5),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              // Banner + avatar
              Stack(clipBehavior: Clip.none, children: [
                GestureDetector(
                  onTap: () => _pickBg(context),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.divider),
                      gradient: _bg.isNotEmpty ? null : null,
                    ),
                    child: _bg.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SeedPlaceholder(seed: _bg, radius: 16))
                        : Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: p.inkSubtle),
                                  const SizedBox(height: 4),
                                  Text('添加主页背景（选填）',
                                      style: TextStyle(
                                          fontSize: 12, color: p.inkSubtle)),
                                ])),
                  ),
                ),
                if (_bg.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _bg = ''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xB30F172A),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('移除背景图',
                            style: TextStyle(
                                fontSize: 11, color: Colors.white)),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  bottom: -28,
                  child: GestureDetector(
                    onTap: () => _pickAvatar(context),
                    child: Stack(children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: p.bg),
                        child: SeedAvatar(
                            seed: _avatar.isEmpty ? 'me' : _avatar,
                            size: 68,
                            label: _name.text,
                            ring: gColor),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.primary,
                              border: Border.all(color: p.bg, width: 2)),
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 40),
              // Gender
              _sectionLabel(p, '性别', core: true),
              const SizedBox(height: 8),
              Row(children: [
                _GenderChip(
                    label: '小姐姐',
                    icon: Icons.female_rounded,
                    color: p.pink,
                    soft: const Color(0xFFFCE7F3),
                    active: isF,
                    onTap: () => setState(() => _gender = 'f')),
                const SizedBox(width: 10),
                _GenderChip(
                    label: '小哥哥',
                    icon: Icons.male_rounded,
                    color: p.sky,
                    soft: const Color(0xFFE0F2FE),
                    active: !isF,
                    onTap: () => setState(() => _gender = 'm')),
              ]),
              const SizedBox(height: 16),
              _sectionLabel(p, '昵称',
                  core: true,
                  counter: '${_units(_name.text.trim())} / 20',
                  warn: _units(_name.text.trim()) > 20),
              const SizedBox(height: 6),
              TextField(
                  controller: _name,
                  style: TextStyle(fontSize: 14, color: p.ink),
                  decoration: deco('中文 ≤10 字 / 英文 ≤20 字符')),
              const SizedBox(height: 16),
              _sectionLabel(p, '自我介绍',
                  counter: '${_bio.text.length} / 100'),
              const SizedBox(height: 6),
              TextField(
                  controller: _bio,
                  maxLength: 100,
                  minLines: 3,
                  maxLines: 5,
                  style: TextStyle(fontSize: 14, color: p.ink, height: 1.5),
                  decoration: deco('介绍一下自己吧')),
              const SizedBox(height: 16),
              _sectionLabel(p, '其它资料'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.divider)),
                child: Column(children: [
                  for (final (i, k) in otherKeys.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                          border: i == otherKeys.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: p.divider))),
                      child: Row(children: [
                        SizedBox(
                            width: 70,
                            child: Text(k.$2,
                                style: TextStyle(
                                    fontSize: 13, color: p.inkMuted))),
                        Expanded(
                          child: TextField(
                            controller: _fields[k.$1],
                            style: TextStyle(fontSize: 13.5, color: p.ink),
                            decoration: InputDecoration(
                                hintText: '未填写',
                                hintStyle: TextStyle(color: p.inkSubtle),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12)),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
              // History
              if (_summary.items.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(p, '审核记录'),
                const SizedBox(height: 8),
                for (final r in _summary.items.take(5))
                  _ReviewTile(
                      review: r,
                      onSimulate: r.status == 'pending'
                          ? () => _simulateApprove(r)
                          : null),
              ],
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.divider))),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _canSave ? p.mint : const Color(0xFFCBD5E1)),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('提交审核',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(p, String t,
          {bool core = false, String? counter, bool warn = false}) =>
      Row(children: [
        Text(t,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        if (core) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(999)),
            child: Text('剩余 ${_summary.coreLeft} 次',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFFB45309))),
          ),
        ],
        const Spacer(),
        if (counter != null)
          Text(counter,
              style: TextStyle(
                  fontSize: 11, color: warn ? p.pink : p.inkSubtle)),
      ]);

  void _pickAvatar(BuildContext context) {
    final p = context.pRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('选择头像',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (int i = 0; i < 10; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _avatar = 'preset-$i');
                    Navigator.pop(ctx);
                  },
                  child: SeedAvatar(seed: 'preset-$i', size: 48, label: '${i + 1}'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              setState(() =>
                  _avatar = 'upload-${DateTime.now().millisecondsSinceEpoch}');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('从相册上传（320px 方形裁剪）'),
          ),
        ]),
      ),
    );
  }

  void _pickBg(BuildContext context) {
    setState(() => _bg = 'bg-${DateTime.now().millisecondsSinceEpoch}');
    showToast(context, '背景图已选择（≤ 500KB，自动压缩）');
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color soft;
  final bool active;
  final VoidCallback onTap;
  const _GenderChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.soft,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? soft : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : p.divider, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? color : p.inkSubtle),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? color : p.inkMuted)),
          ]),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProfileReview review;
  final VoidCallback? onSimulate;
  const _ReviewTile({required this.review, this.onSimulate});

  static const _labels = {
    'avatar': '头像',
    'name': '用户名',
    'gender': '性别',
    'bio': '自我介绍',
    'bgUrl': '主页背景',
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
    final st = switch (review.status) {
      'approved' => ('已通过', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'rejected' => ('未通过', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      'deleted' => ('已删除', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
      _ => ('审核中', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
    };
    final changed = [
      ...review.core.keys,
      ...review.other.keys
    ].map((k) => _labels[k] ?? k).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.divider)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('修改：$changed',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
            const SizedBox(height: 3),
            Text(fmtDateTime(review.at),
                style: TextStyle(fontSize: 11, color: p.inkSubtle)),
            if (review.note.isNotEmpty)
              Text('备注：${review.note}',
                  style: TextStyle(fontSize: 11.5, color: p.inkMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: st.$2, borderRadius: BorderRadius.circular(999)),
          child: Text(st.$1,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: st.$3)),
        ),
        if (onSimulate != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onLongPress: onSimulate,
            child: Tooltip(
              message: '长按：演示管理员通过',
              child: Icon(Icons.admin_panel_settings_outlined,
                  size: 18, color: p.inkSubtle),
            ),
          ),
        ],
      ]),
    );
  }
}
