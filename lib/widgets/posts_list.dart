import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../pages/my_profile_page.dart';
import '../pages/simple_pages.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Live post list from the API (circle or forum), sorted by date desc.
class PostsList extends StatefulWidget {
  final String type; // circle | forum
  const PostsList({super.key, required this.type});

  @override
  State<PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  List<Post>? _posts;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final state = context.read<AppState>();
    if (!state.online) {
      setState(() {
        _posts = [];
        _err = null;
      });
      return;
    }
    try {
      final l = await state.api.posts(type: widget.type);
      if (mounted) setState(() => _posts = l);
    } catch (e) {
      if (mounted) setState(() => _err = '加载失败，请下拉重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final posts = _posts;
    if (_err != null) {
      return Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.wifi_off_rounded, size: 40, color: p.inkSubtle),
        const SizedBox(height: 10),
        Text(_err!, style: TextStyle(color: p.inkMuted, fontSize: 13)),
        TextButton(onPressed: load, child: const Text('重试')),
      ]);
    }
    if (posts == null) {
      return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()));
    }
    if (posts.isEmpty) {
      return EmptyHint(
          icon: widget.type == 'circle'
              ? Icons.article_outlined
              : Icons.forum_outlined,
          text: widget.type == 'circle' ? '暂无圈子帖子，去发布第一条吧' : '暂无论坛帖子，去发布第一条吧');
    }
    return Column(children: [for (final post in posts) PostCard(post: post)]);
  }
}
