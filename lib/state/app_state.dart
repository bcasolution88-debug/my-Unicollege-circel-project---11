import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';

/// Home top tabs: 首页 · 圈子 · 论坛
enum HomeTab { home, circle, forum }

/// Bottom nav destinations.
enum NavTab { home, circle, forum, me }

class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  bool _dark = false;
  HomeTab _homeTab = HomeTab.home;
  NavTab _navTab = NavTab.home;
  int _serviceUnread = 3;
  int _msgUnread = 11;
  final Set<String> _joinedEvents = {};
  final Map<String, int> _eventViews = {};

  bool get isDark => _dark;
  AppPalette get palette => _dark ? AppPalette.dark : AppPalette.light;
  HomeTab get homeTab => _homeTab;
  NavTab get navTab => _navTab;
  int get serviceUnread => _serviceUnread;
  int get msgUnread => _msgUnread;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool('dark') ?? false;
    final tab = prefs.getString('home_tab');
    if (tab != null) {
      _homeTab = HomeTab.values.firstWhere((e) => e.name == tab,
          orElse: () => HomeTab.home);
    }
    _joinedEvents.addAll(prefs.getStringList('event_joins') ?? const []);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _dark = !_dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark', _dark);
  }

  Future<void> setHomeTab(HomeTab tab) async {
    _homeTab = tab;
    _navTab = switch (tab) {
      HomeTab.home => NavTab.home,
      HomeTab.circle => NavTab.circle,
      HomeTab.forum => NavTab.forum,
    };
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

  void clearServiceUnread() {
    _serviceUnread = 0;
    notifyListeners();
  }

  void clearMsgUnread() {
    _msgUnread = 0;
    notifyListeners();
  }

  // ── Events ────────────────────────────────────────────────
  List<EventItem> get events => kEvents.map(_withStats).toList();

  EventItem _withStats(EventItem e) {
    final signups = List<String>.from(e.signups)..remove('me');
    if (_joinedEvents.contains(e.id)) signups.add('me');
    return e.copyWith(
      signups: signups,
      views: e.baseViews + (_eventViews[e.id] ?? 0),
    );
  }

  EventItem? eventById(String id) {
    for (final e in kEvents) {
      if (e.id == id) return _withStats(e);
    }
    return null;
  }

  bool joined(String id) => _joinedEvents.contains(id);

  void bumpView(String id) {
    _eventViews[id] = (_eventViews[id] ?? 0) + 1;
    notifyListeners();
  }

  Future<bool> toggleJoin(String id) async {
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
