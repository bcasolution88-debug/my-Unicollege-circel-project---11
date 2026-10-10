import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_service.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';

/// Home top tabs: 首页 · 圈子 · 论坛
enum HomeTab { home, circle, forum }

/// Bottom nav destinations.
enum NavTab { home, circle, forum, me }

class AppState extends ChangeNotifier {
  AppState({ApiService? api}) : api = api ?? ApiService() {
    _load();
  }

  final ApiService api;

  bool _dark = false;
  HomeTab _homeTab = HomeTab.home;
  NavTab _navTab = NavTab.home;
  bool _online = false;
  Timer? _poll;

  Unread _unread = const Unread(
      share: 1,
      feedback: 2,
      sysnotify: 3,
      service: 3,
      users: {'allanliu6': 5, 'weichen': 1, 'yy2026': 2});
  Profile _profile = Profile.fallback;
  List<EventItem> _events = List.of(kEvents);
  final Set<String> _joinedEvents = {};
  final Map<String, int> _eventViews = {};

  bool get isDark => _dark;
  bool get online => _online;
  AppPalette get palette => _dark ? AppPalette.dark : AppPalette.light;
  HomeTab get homeTab => _homeTab;
  NavTab get navTab => _navTab;
  Unread get unread => _unread;
  Profile get profile => _profile;
  String get uid => api.uid;
  int get serviceUnread => _unread.service;
  int get msgUnread => _unread.total;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool('dark') ?? false;
    final tab = prefs.getString('home_tab');
    if (tab != null) {
      _homeTab = HomeTab.values.firstWhere((e) => e.name == tab,
          orElse: () => HomeTab.home);
      _navTab = _navFor(_homeTab);
    }
    _joinedEvents.addAll(prefs.getStringList('event_joins') ?? const []);
    notifyListeners();
    await refresh();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _syncUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Pull server state; silently keeps local data when offline.
  Future<void> refresh() async {
    final ok = await api.health();
    if (ok != _online) {
      _online = ok;
      notifyListeners();
    }
    if (!ok) return;
    try {
      final results = await Future.wait([
        api.events(),
        api.unread(),
        api.profile(),
      ]);
      _events = (results[0] as List<Map<String, dynamic>>)
          .map(_eventFromJson)
          .toList();
      _unread = results[1] as Unread;
      _profile = results[2] as Profile;
      notifyListeners();
    } catch (_) {
      // keep local
    }
  }

  Future<void> _syncUnread() async {
    if (!_online) {
      await refresh();
      return;
    }
    try {
      _unread = await api.unread();
      notifyListeners();
    } catch (_) {
      _online = false;
      notifyListeners();
    }
  }

  Future<void> reloadProfile() async {
    if (!_online) return;
    try {
      _profile = await api.profile();
      notifyListeners();
    } catch (_) {}
  }

  EventItem _eventFromJson(Map<String, dynamic> j) {
    final signups =
        ((j['signups'] as List?) ?? []).map((e) => e.toString()).toList();
    return EventItem(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      date: j['date'] as String? ?? '',
      time: j['time'] as String? ?? '',
      place: j['place'] as String? ?? '',
      detail: j['detail'] as String? ?? '',
      seed: j['seed'] as String? ?? 'ev',
      author: j['author'] as String? ?? '',
      baseViews: (j['baseViews'] as num?)?.toInt() ?? 0,
      views: ((j['baseViews'] as num?)?.toInt() ?? 0) +
          ((j['views'] as num?)?.toInt() ?? 0),
      signups: signups,
    );
  }

  // ── Theme / nav ──────────────────────────────────────────
  Future<void> toggleTheme() async {
    _dark = !_dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark', _dark);
  }

  NavTab _navFor(HomeTab t) => switch (t) {
        HomeTab.home => NavTab.home,
        HomeTab.circle => NavTab.circle,
        HomeTab.forum => NavTab.forum,
      };

  Future<void> setHomeTab(HomeTab tab) async {
    _homeTab = tab;
    _navTab = _navFor(tab);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_tab', tab.name);
  }

  void setNavTab(NavTab tab) {
    _navTab = tab;
    if (tab == NavTab.home) _homeTab = HomeTab.home;
    if (tab == NavTab.circle) _homeTab = HomeTab.circle;
    if (tab == NavTab.forum) _homeTab = HomeTab.forum;
    notifyListeners();
  }

  // ── Unread ───────────────────────────────────────────────
  Future<void> clearUnread(String key, {String? peer}) async {
    _unread = switch (key) {
      'share' => _unread.copyWith(share: 0),
      'feedback' => _unread.copyWith(feedback: 0),
      'sysnotify' => _unread.copyWith(sysnotify: 0),
      'service' => _unread.copyWith(service: 0),
      'user' => _unread.copyWith(
          users: {..._unread.users, if (peer != null) peer: 0}),
      _ => _unread,
    };
    notifyListeners();
    if (_online) {
      try {
        _unread = await api.clearUnread(key, peer: peer);
        notifyListeners();
      } catch (_) {}
    }
  }

  void clearServiceUnread() => clearUnread('service');
  void clearMsgUnread() {}

  // ── Events ───────────────────────────────────────────────
  List<EventItem> get events => _events.map(_withLocalStats).toList();

  EventItem _withLocalStats(EventItem e) {
    if (_online) return e.copyWith(views: e.views);
    final signups = List<String>.from(e.signups)..remove('me');
    if (_joinedEvents.contains(e.id)) signups.add('me');
    return e.copyWith(
        signups: signups, views: e.baseViews + (_eventViews[e.id] ?? 0));
  }

  EventItem? eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  bool joined(String id) {
    final e = eventById(id);
    if (_online) return e?.signups.contains('me') ?? false;
    return _joinedEvents.contains(id);
  }

  Future<void> bumpView(String id) async {
    if (_online) {
      try {
        await api.eventView(id);
        _events = (await api.events()).map(_eventFromJson).toList();
        notifyListeners();
        return;
      } catch (_) {}
    }
    _eventViews[id] = (_eventViews[id] ?? 0) + 1;
    notifyListeners();
  }

  Future<bool> toggleJoin(String id) async {
    if (_online) {
      try {
        final joined = await api.eventJoin(id);
        _events = (await api.events()).map(_eventFromJson).toList();
        notifyListeners();
        return joined;
      } catch (_) {}
    }
    final now = !_joinedEvents.contains(id);
    if (now) {
      _joinedEvents.add(id);
    } else {
      _joinedEvents.remove(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('event_joins', _joinedEvents.toList());
    return now;
  }
}
