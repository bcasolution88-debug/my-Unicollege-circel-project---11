import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// REST client for the Campus Circle backend.
///
/// Base URL resolution:
///   1. `--dart-define=API_BASE=https://...`
///   2. Web: same host as the page, port 8787 (dev convenience)
///   3. Android: 10.0.2.2:8787 (emulator) — override with API_BASE for devices
class ApiService {
  static const _define = String.fromEnvironment('API_BASE', defaultValue: '');

  final String baseUrl;
  final String uid;
  final http.Client _client = http.Client();

  ApiService({String? baseUrl, this.uid = '800123'})
      : baseUrl = baseUrl ?? resolveBase();

  static String resolveBase() {
    if (_define.isNotEmpty) return _define;
    if (kIsWeb) {
      final loc = Uri.base;
      // sandbox preview: 5060-xxx.host → 8787-xxx.host
      final host = loc.host;
      if (host.startsWith('5060-')) {
        return '${loc.scheme}://${host.replaceFirst('5060-', '8787-')}';
      }
      return '${loc.scheme}://${loc.host}:8787';
    }
    return 'http://10.0.2.2:8787';
  }

  Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: q);
    final r = await _client.get(uri).timeout(const Duration(seconds: 8));
    return _unwrap(r);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await _client
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 8));
    return _unwrap(r);
  }

  dynamic _unwrap(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      throw ApiException(
          r.statusCode, (body is Map ? body['error'] : null)?.toString() ?? '请求失败');
    }
    return body is Map ? body['data'] : body;
  }

  // ── Health ───────────────────────────────────────────────
  Future<bool> health() async {
    try {
      final d = await _get('/api/health');
      return d is Map && d['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Taxonomy ─────────────────────────────────────────────
  Future<List<CircleGroup>> circles() async => ((await _get('/api/circles')) as List)
      .map((e) => CircleGroup.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<TopicRef>> topics() async => ((await _get('/api/topics')) as List)
      .map((e) => TopicRef.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<LegalDoc> legal(String key) async =>
      LegalDoc.fromJson((await _get('/api/legal/$key')) as Map<String, dynamic>);

  // ── Events ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> events() async =>
      ((await _get('/api/events')) as List).cast<Map<String, dynamic>>();

  Future<void> eventView(String id) => _post('/api/events/$id/view');

  Future<bool> eventJoin(String id) async {
    final d = await _post('/api/events/$id/join', {'uid': uid});
    return (d as Map)['joined'] == true;
  }

  Future<void> eventSubmit(Map<String, dynamic> ev) =>
      _post('/api/events', {...ev, 'author': '我的昵称'});

  // ── Posts ────────────────────────────────────────────────
  Future<List<Post>> posts({String? type}) async {
    final d = await _get('/api/posts', {
      if (type != null) 'type': type,
      'uid': uid,
    });
    return (d as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost(Map<String, dynamic> body) async =>
      Post.fromJson((await _post('/api/posts', {...body, 'uid': uid}))
          as Map<String, dynamic>);

  // ── Feedback ─────────────────────────────────────────────
  Future<List<FeedbackItem>> feedback() async =>
      ((await _get('/api/feedback', {'uid': uid})) as List)
          .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<FeedbackItem> createFeedback(Map<String, dynamic> body) async =>
      FeedbackItem.fromJson((await _post('/api/feedback', {...body, 'uid': uid}))
          as Map<String, dynamic>);

  // ── Notifications ────────────────────────────────────────
  Future<List<NotificationItem>> notifications() async =>
      ((await _get('/api/notifications')) as List)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();

  // ── Service chat ─────────────────────────────────────────
  Future<List<ServiceMsg>> serviceMsgs() async =>
      ((await _get('/api/service/$uid')) as List)
          .map((e) => ServiceMsg.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<ServiceMsg> serviceSend(String text) async => ServiceMsg.fromJson(
      (await _post('/api/service/$uid', {'kind': 'text', 'text': text}))
          as Map<String, dynamic>);

  Future<void> serviceRecall(String mid) => _post('/api/service/$uid/recall/$mid');

  // ── User chats ───────────────────────────────────────────
  Future<List<Conversation>> chats() async =>
      ((await _get('/api/chats/$uid')) as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<ChatThread> chat(String peer) async => ChatThread.fromJson(
      (await _get('/api/chats/$uid/$peer')) as Map<String, dynamic>);

  Future<({ChatMsg msg, bool locked})> chatSend(String peer, String text) async {
    final d = await _post('/api/chats/$uid/$peer', {'text': text}) as Map;
    return (
      msg: ChatMsg.fromJson(d['msg'] as Map<String, dynamic>),
      locked: d['locked'] == true
    );
  }

  // ── Unread ───────────────────────────────────────────────
  Future<Unread> unread() async =>
      Unread.fromJson((await _get('/api/unread/$uid')) as Map<String, dynamic>);

  Future<Unread> clearUnread(String key, {String? peer}) async =>
      Unread.fromJson((await _post('/api/unread/$uid/clear',
          {'key': key, if (peer != null) 'peer': peer})) as Map<String, dynamic>);

  // ── Profile & review ─────────────────────────────────────
  Future<Profile> profile() async =>
      Profile.fromJson((await _get('/api/profile/$uid')) as Map<String, dynamic>);

  Future<ReviewSummary> reviews() async => ReviewSummary.fromJson(
      (await _get('/api/profile/$uid/reviews')) as Map<String, dynamic>);

  Future<ProfileReview> submitReview(
          Map<String, dynamic> core, Map<String, dynamic> other) async =>
      ProfileReview.fromJson((await _post(
              '/api/profile/$uid/reviews', {'core': core, 'other': other}))
          as Map<String, dynamic>);

  /// Demo-only: simulate admin approval from the app (hidden dev action).
  Future<void> decideReview(String id, String status) =>
      _post('/api/admin/reviews/$id/decide', {'status': status});
}
