import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ── Carousel slides (后台 → 幻灯图设置 · 首页) ───────────────
class SlideItem {
  final String seed;
  final List<Color> grad;
  final String title;
  final String subtitle;
  const SlideItem(
      {required this.seed,
      required this.grad,
      required this.title,
      required this.subtitle});
}

const kHomeSlides = [
  SlideItem(
      seed: 'home-hero-1',
      grad: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      title: '示例主题一',
      subtitle: '本周精选'),
  SlideItem(
      seed: 'home-hero-2',
      grad: [Color(0xFFF97316), Color(0xFFEC4899)],
      title: '示例主题二',
      subtitle: '开学季推荐'),
  SlideItem(
      seed: 'home-hero-3',
      grad: [Color(0xFF10B981), Color(0xFF0EA5E9)],
      title: '示例主题三',
      subtitle: '热门活动'),
];

const kEventSlides = [
  SlideItem(
      seed: 'evt-hero-1',
      grad: [Color(0xFF0EA5E9), Color(0xFF7C3AED)],
      title: 'ANIME',
      subtitle: '动漫嘉年华'),
  SlideItem(
      seed: 'evt-hero-2',
      grad: [Color(0xFFF97316), Color(0xFFEC4899)],
      title: 'CAMPUS',
      subtitle: '校园文化节'),
  SlideItem(
      seed: 'evt-hero-3',
      grad: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      title: 'JOB FAIR',
      subtitle: '春季招聘会'),
  SlideItem(
      seed: 'evt-hero-4',
      grad: [Color(0xFF10B981), Color(0xFF0EA5E9)],
      title: 'SPORTS',
      subtitle: '运动挑战赛'),
  SlideItem(
      seed: 'evt-hero-5',
      grad: [Color(0xFFFBBF24), Color(0xFFEF4444)],
      title: 'MUSIC',
      subtitle: '校园音乐节'),
];

/// ── Feature grid (2 rows × 4) ──────────────────────────────
class FeatureItem {
  final String id;
  final IconData icon;
  final String label;
  final Tint tint;
  const FeatureItem(this.id, this.icon, this.label, this.tint);
}

const kFeatures = [
  FeatureItem('videoPosts', Icons.movie_outlined, '视频帖', Tint.violet),
  FeatureItem('news', Icons.article_outlined, '新闻资讯', Tint.indigo),
  FeatureItem('events', Icons.groups_outlined, '活动频道', Tint.rose),
  FeatureItem('shorts', Icons.play_arrow_rounded, '短视频', Tint.sky),
  FeatureItem('sites', Icons.language, '网站推荐', Tint.mint),
  FeatureItem('circleHub', Icons.grid_view_rounded, '圈子社区', Tint.amber),
  FeatureItem('recommend', Icons.local_fire_department_outlined, '热推展示',
      Tint.pink),
  FeatureItem('messages', Icons.chat_bubble_outline_rounded, '消息信息',
      Tint.teal),
];

/// ── Hot circles tiles (后台 → 首页磁贴) ─────────────────────
class TileItem {
  final String id;
  final String label;
  final String seed;
  final Color? tint;
  const TileItem(this.id, this.label, this.seed, {this.tint});
}

const kHotCircles = [
  TileItem('res', '学习资源交流', 'hc-res'),
  TileItem('team', 'FIND COUPLE IN TEAMWORK', 'hc-team'),
  TileItem('art', '艺术设计', 'hc-art'),
  TileItem('music', '音乐社团', 'hc-music'),
  TileItem('gym', '健身俱乐部', 'hc-gym'),
  TileItem('study', 'University Study Life Makes Easy', 'hc-study'),
  TileItem('yy', '兴趣组团YY', 'hc-yy'),
  TileItem('car', '汽车配件', 'hc-car'),
];

const kHotForums = [
  TileItem('course', '入门课程', 'hf-course', tint: Color(0xFFEC4899)),
  TileItem('abroad', '海外留学', 'hf-abroad', tint: Color(0xFF38BDF8)),
  TileItem('major', '大学学科', 'hf-major', tint: Color(0xFF7C3AED)),
  TileItem('video', 'Video Edition', 'hf-video', tint: Color(0xFF7C3AED)),
  TileItem('stream', 'Streaming', 'hf-stream', tint: Color(0xFF38BDF8)),
  TileItem('digital', 'Digital World', 'hf-digital', tint: Color(0xFF7C3AED)),
];

/// ── Events (活动报名) ──────────────────────────────────────
class EventItem {
  final String id;
  final String title;
  final String date;
  final String time;
  final String place;
  final String detail;
  final String seed;
  final String author;
  final int baseViews;
  final int views;
  final List<String> signups;

  const EventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.place,
    required this.detail,
    required this.seed,
    required this.author,
    required this.baseViews,
    this.views = 0,
    required this.signups,
  });

  EventItem copyWith({List<String>? signups, int? views}) => EventItem(
        id: id,
        title: title,
        date: date,
        time: time,
        place: place,
        detail: detail,
        seed: seed,
        author: author,
        baseViews: baseViews,
        views: views ?? this.views,
        signups: signups ?? this.signups,
      );
}

const kEvents = [
  EventItem(
    id: 'uev-1',
    title: '读书会 · 十月共读《人类简史》',
    date: '2026-10-20',
    time: '19:30',
    place: '吉隆坡中央图书馆',
    detail: '每周一次线下共读，欢迎新朋友加入。',
    seed: 'uev-1',
    author: 'allanliu6',
    baseViews: 0,
    signups: [],
  ),
  EventItem(
    id: 'ev1',
    title: '示例活动一 · 校园周末音乐节',
    date: '2026-12-15',
    time: '19:00',
    place: '示例地点 · 由后台配置',
    detail: '这里是活动详情示例。管理员在后台发布活动后，用户在此看到完整介绍、时间、地点与图片。',
    seed: 'ev1',
    author: 'segi asia marketing (SAM)',
    baseViews: 78,
    signups: ['allanliu6', 'shier', 'mymuse60', 'myunisocial', 'weichen'],
  ),
  EventItem(
    id: 'ev2',
    title: '示例活动二 · 编程马拉松',
    date: '2025-01-30',
    time: '09:00',
    place: '创新中心 3 楼',
    detail: '48 小时团队编程挑战，欢迎所有专业同学报名组队。',
    seed: 'ev2',
    author: 'segi asia marketing (SAM)',
    baseViews: 7,
    signups: ['jacky'],
  ),
  EventItem(
    id: 'ev3',
    title: '示例活动三 · 摄影分享会',
    date: '2025-01-13',
    time: '14:30',
    place: '图书馆多功能厅',
    detail: '分享你的摄影作品和拍摄心得，现场有专业老师点评。',
    seed: 'ev3',
    author: 'segi asia marketing (SAM)',
    baseViews: 3,
    signups: ['future', 'yy', 'segi'],
  ),
];

/// ── Followed circles (圈子 tab) ────────────────────────────
class CircleInfo {
  final String name;
  final String sub;
  final String seed;
  const CircleInfo(this.name, this.sub, this.seed);
}

const kFollowedCircles = [
  CircleInfo('学习资源交流', '我有酒你有故事吗?', 'res'),
  CircleInfo('兴趣组团YY', '做一个沙雕，快乐天天有', 'yy'),
  CircleInfo('FIND COUPLE IN TEAMWORK', 'Find your teammate', 'team'),
  CircleInfo('汽车配件', '目前很多城市虽然发展不敌北上广深，但发展潜力是巨大的', 'car'),
];

/// ── Forum topics (论坛 tab) ────────────────────────────────
class TopicInfo {
  final String name;
  final String category;
  final int posts;
  final String seed;
  const TopicInfo(this.name, this.category, this.posts, this.seed);
}

const kTopics = [
  TopicInfo('开学第一周怎么过？', '入门课程', 128, 't1'),
  TopicInfo('留学申请时间线分享', '海外留学', 96, 't2'),
  TopicInfo('计算机专业选课攻略', '大学学科', 74, 't3'),
  TopicInfo('剪辑软件推荐', 'Video Edition', 52, 't4'),
  TopicInfo('直播设备入门', 'Streaming', 38, 't5'),
  TopicInfo('AI 工具大合集', 'Digital World', 211, 't6'),
];
