// API data models for 圈子社区.

class CircleGroup {
  final String id;
  final String label;
  final List<CircleRef> children;
  CircleGroup({required this.id, required this.label, required this.children});
  factory CircleGroup.fromJson(Map<String, dynamic> j) => CircleGroup(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        children: ((j['children'] as List?) ?? [])
            .map((e) => CircleRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CircleRef {
  final String id;
  final String label;
  final String sub;
  CircleRef({required this.id, required this.label, this.sub = ''});
  factory CircleRef.fromJson(Map<String, dynamic> j) => CircleRef(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        sub: j['sub'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

class TopicRef {
  final String id;
  final String name;
  final String category;
  final int posts;
  TopicRef(
      {required this.id,
      required this.name,
      this.category = '',
      this.posts = 0});
  factory TopicRef.fromJson(Map<String, dynamic> j) => TopicRef(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
        posts: (j['posts'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class PollOption {
  final String text;
  final int votes;
  PollOption(this.text, this.votes);
  factory PollOption.fromJson(Map<String, dynamic> j) =>
      PollOption(j['text'] as String? ?? '', (j['votes'] as num?)?.toInt() ?? 0);
}

class Poll {
  final String question;
  final List<PollOption> options;
  Poll({required this.question, required this.options});
  factory Poll.fromJson(Map<String, dynamic> j) => Poll(
        question: j['question'] as String? ?? '',
        options: ((j['options'] as List?) ?? [])
            .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Post {
  final String id;
  final String type; // circle | forum
  final String author;
  final String authorUid;
  final String text;
  final List<String> images;
  final bool hasVideo;
  final Poll? poll;
  final CircleRef? circle;
  final TopicRef? topic;
  final int likes;
  final int comments;
  final String status;
  final int ts;

  Post({
    required this.id,
    required this.type,
    required this.author,
    required this.authorUid,
    required this.text,
    required this.images,
    required this.hasVideo,
    this.poll,
    this.circle,
    this.topic,
    required this.likes,
    required this.comments,
    required this.status,
    required this.ts,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'circle',
        author: j['author'] as String? ?? '',
        authorUid: j['authorUid']?.toString() ?? '',
        text: j['text'] as String? ?? '',
        images: ((j['images'] as List?) ?? []).map((e) => e.toString()).toList(),
        hasVideo: j['hasVideo'] as bool? ?? false,
        poll: j['poll'] is Map
            ? Poll.fromJson(j['poll'] as Map<String, dynamic>)
            : null,
        circle: j['circle'] is Map
            ? CircleRef.fromJson(j['circle'] as Map<String, dynamic>)
            : null,
        topic: j['topic'] is Map
            ? TopicRef.fromJson(j['topic'] as Map<String, dynamic>)
            : null,
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'approved',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

class FeedbackReply {
  final String id;
  final String text;
  final String operator;
  final int ts;
  final List<String> images;
  FeedbackReply(
      {required this.id,
      required this.text,
      required this.operator,
      required this.ts,
      required this.images});
  factory FeedbackReply.fromJson(Map<String, dynamic> j) => FeedbackReply(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        operator: j['operator'] as String? ?? '官方客服',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        images: ((j['images'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class FeedbackItem {
  final String id;
  final String cat;
  final String subject;
  final String desc;
  final String contact;
  final List<String> images;
  final int ts;
  final String status; // new | doing | done
  final List<FeedbackReply> replies;
  FeedbackItem({
    required this.id,
    required this.cat,
    required this.subject,
    required this.desc,
    required this.contact,
    required this.images,
    required this.ts,
    required this.status,
    required this.replies,
  });
  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
        id: j['id'] as String? ?? '',
        cat: j['cat'] as String? ?? 'other',
        subject: j['subject'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        contact: j['contact'] as String? ?? '',
        images: ((j['images'] as List?) ?? []).map((e) => e.toString()).toList(),
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'new',
        replies: ((j['replies'] as List?) ?? [])
            .map((e) => FeedbackReply.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final List<String> images;
  final int ts;
  NotificationItem(
      {required this.id,
      required this.title,
      required this.body,
      required this.images,
      required this.ts});
  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        images: ((j['images'] as List?) ?? []).map((e) => e.toString()).toList(),
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

class ServiceMsg {
  final String id;
  final String who; // user | agent
  final String kind; // text | image | recalled
  final String text;
  final String image;
  final int ts;
  ServiceMsg(
      {required this.id,
      required this.who,
      required this.kind,
      required this.text,
      required this.image,
      required this.ts});
  factory ServiceMsg.fromJson(Map<String, dynamic> j) => ServiceMsg(
        id: j['id'] as String? ?? '',
        who: j['who'] as String? ?? 'agent',
        kind: j['kind'] as String? ?? 'text',
        text: j['text'] as String? ?? '',
        image: j['image'] as String? ?? '',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

class Conversation {
  final String peer;
  final String name;
  final String gender;
  final String preview;
  final int ts;
  Conversation(
      {required this.peer,
      required this.name,
      required this.gender,
      required this.preview,
      required this.ts});
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        peer: j['peer'] as String? ?? '',
        name: j['name'] as String? ?? '',
        gender: j['gender'] as String? ?? '',
        preview: j['preview'] as String? ?? '',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

class ChatMsg {
  final String id;
  final String from;
  final String kind;
  final String text;
  final int ts;
  ChatMsg(
      {required this.id,
      required this.from,
      required this.kind,
      required this.text,
      required this.ts});
  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
        id: j['id'] as String? ?? '',
        from: j['from']?.toString() ?? '',
        kind: j['kind'] as String? ?? 'text',
        text: j['text'] as String? ?? '',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

class ChatThread {
  final String peer;
  final String name;
  final String gender;
  final List<ChatMsg> msgs;
  final bool locked;
  ChatThread(
      {required this.peer,
      required this.name,
      required this.gender,
      required this.msgs,
      required this.locked});
  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        peer: j['peer'] as String? ?? '',
        name: j['name'] as String? ?? '',
        gender: j['gender'] as String? ?? '',
        msgs: ((j['msgs'] as List?) ?? [])
            .map((e) => ChatMsg.fromJson(e as Map<String, dynamic>))
            .toList(),
        locked: j['locked'] as bool? ?? false,
      );
}

class Unread {
  final int share;
  final int feedback;
  final int sysnotify;
  final int service;
  final Map<String, int> users;
  const Unread(
      {this.share = 0,
      this.feedback = 0,
      this.sysnotify = 0,
      this.service = 0,
      this.users = const {}});
  factory Unread.fromJson(Map<String, dynamic> j) => Unread(
        share: (j['share'] as num?)?.toInt() ?? 0,
        feedback: (j['feedback'] as num?)?.toInt() ?? 0,
        sysnotify: (j['sysnotify'] as num?)?.toInt() ?? 0,
        service: (j['service'] as num?)?.toInt() ?? 0,
        users: ((j['users'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
      );
  int get usersTotal => users.values.fold(0, (a, b) => a + b);
  int get total => share + feedback + sysnotify + service + usersTotal;
  Unread copyWith(
          {int? share,
          int? feedback,
          int? sysnotify,
          int? service,
          Map<String, int>? users}) =>
      Unread(
          share: share ?? this.share,
          feedback: feedback ?? this.feedback,
          sysnotify: sysnotify ?? this.sysnotify,
          service: service ?? this.service,
          users: users ?? this.users);
}

class Profile {
  final String uid;
  final String name;
  final String gender; // f | m
  final String avatar;
  final String bgUrl;
  final String bio;
  final String ip;
  final Map<String, String> fields;
  final List<String> following;
  final List<String> followers;
  final int likes;
  final int modifiedAt;

  const Profile({
    required this.uid,
    required this.name,
    required this.gender,
    required this.avatar,
    required this.bgUrl,
    required this.bio,
    required this.ip,
    required this.fields,
    required this.following,
    required this.followers,
    required this.likes,
    required this.modifiedAt,
  });

  static const fallback = Profile(
    uid: '800123',
    name: '我的昵称',
    gender: 'f',
    avatar: '',
    bgUrl: '',
    bio: '热爱生活，喜欢分享校园日常。',
    ip: '吉隆坡',
    fields: {'job': '学生'},
    following: ['allanliu6', 'weichen', 'shier'],
    followers: ['allanliu6', 'yy2026'],
    likes: 36,
    modifiedAt: 0,
  );

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        uid: j['uid']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        gender: j['gender'] as String? ?? 'f',
        avatar: j['avatar'] as String? ?? '',
        bgUrl: j['bgUrl'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        ip: j['ip'] as String? ?? '',
        fields: ((j['fields'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
        following:
            ((j['following'] as List?) ?? []).map((e) => e.toString()).toList(),
        followers:
            ((j['followers'] as List?) ?? []).map((e) => e.toString()).toList(),
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        modifiedAt: (j['modifiedAt'] as num?)?.toInt() ?? 0,
      );
}

class ProfileReview {
  final String id;
  final int at;
  final String status; // pending | approved | rejected | deleted
  final Map<String, dynamic> core;
  final Map<String, dynamic> other;
  final String note;
  ProfileReview(
      {required this.id,
      required this.at,
      required this.status,
      required this.core,
      required this.other,
      required this.note});
  factory ProfileReview.fromJson(Map<String, dynamic> j) => ProfileReview(
        id: j['id'] as String? ?? '',
        at: (j['at'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'pending',
        core: Map<String, dynamic>.from((j['core'] as Map?) ?? {}),
        other: Map<String, dynamic>.from((j['other'] as Map?) ?? {}),
        note: j['note'] as String? ?? '',
      );
}

class ReviewSummary {
  final int coreLeft;
  final int otherLeft;
  final int coreMax;
  final int otherMax;
  final List<ProfileReview> items;
  const ReviewSummary(
      {required this.coreLeft,
      required this.otherLeft,
      required this.coreMax,
      required this.otherMax,
      required this.items});
  static const fallback = ReviewSummary(
      coreLeft: 2, otherLeft: 5, coreMax: 2, otherMax: 5, items: []);
  factory ReviewSummary.fromJson(Map<String, dynamic> j) => ReviewSummary(
        coreLeft: ((j['left'] as Map?)?['core'] as num?)?.toInt() ?? 2,
        otherLeft: ((j['left'] as Map?)?['other'] as num?)?.toInt() ?? 5,
        coreMax: ((j['max'] as Map?)?['core'] as num?)?.toInt() ?? 2,
        otherMax: ((j['max'] as Map?)?['other'] as num?)?.toInt() ?? 5,
        items: ((j['items'] as List?) ?? [])
            .map((e) => ProfileReview.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LegalDoc {
  final String title;
  final List<({String h, String p})> sections;
  LegalDoc({required this.title, required this.sections});
  factory LegalDoc.fromJson(Map<String, dynamic> j) => LegalDoc(
        title: j['title'] as String? ?? '',
        sections: ((j['sections'] as List?) ?? [])
            .map((e) => (
                  h: (e as Map)['h']?.toString() ?? '',
                  p: e['p']?.toString() ?? ''
                ))
            .toList(),
      );
}

String fmtTime(int ts) {
  if (ts == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return '${two(d.hour)}:${two(d.minute)}';
  }
  final y = now.subtract(const Duration(days: 1));
  if (d.year == y.year && d.month == y.month && d.day == y.day) return '昨天';
  return '${d.month}-${two(d.day)}';
}

String fmtDateTime(int ts) {
  if (ts == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
