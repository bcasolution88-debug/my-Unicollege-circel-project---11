import 'package:campus_circle/data/api_service.dart';
import 'package:campus_circle/pages/edit_profile_page.dart';
import 'package:campus_circle/pages/feedback_page.dart';
import 'package:campus_circle/pages/messages_page.dart';
import 'package:campus_circle/pages/my_profile_page.dart';
import 'package:campus_circle/pages/publish_page.dart';
import 'package:campus_circle/pages/service_page.dart';
import 'package:campus_circle/pages/user_chat_page.dart';
import 'package:campus_circle/state/app_state.dart';
import 'package:campus_circle/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrap(Widget child) => ChangeNotifierProvider(
      // unreachable base → offline fallback path
      create: (_) => AppState(api: ApiService(baseUrl: 'http://127.0.0.1:1')),
      child: Builder(builder: (context) {
        final p = context.watch<AppState>().palette;
        return MaterialApp(theme: buildThemeData(p), home: child);
      }),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Publish circle: rules pre-ticked, picker row, submit button',
      (tester) async {
    await tester.pumpWidget(wrap(const PublishPage(kind: PublishKind.circle)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('圈子帖子'), findsOneWidget);
    expect(find.text('请选择圈子'), findsOneWidget);
    expect(find.text('我已阅读并同意 《发帖规则》', findRichText: true), findsOneWidget);
    expect(find.text('确定发布'), findsOneWidget);
    // poll editor appears when tapping 投票
    await tester.tap(find.text('投票'));
    await tester.pump();
    expect(find.text('投票 · 单选'), findsOneWidget);
    expect(find.text('选项 1'), findsOneWidget);
    expect(find.text('选项 2'), findsOneWidget);
  });

  testWidgets('Publish forum: topic picker label', (tester) async {
    await tester.pumpWidget(wrap(const PublishPage(kind: PublishKind.forum)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('论坛话题'), findsOneWidget);
    expect(find.text('请选择话题'), findsOneWidget);
  });

  testWidgets('Messages: 4 tiles + conversations', (tester) async {
    await tester.pumpWidget(wrap(const MessagesPage()));
    await tester.pump(const Duration(milliseconds: 300));
    for (final t in ['平台分享', '反馈信息', '系统通知', '客服中心']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('好友用户留言记录'), findsOneWidget);
  });

  testWidgets('Feedback: categories + required fields', (tester) async {
    await tester.pumpWidget(wrap(const FeedbackPage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('圈子与论坛反馈'), findsOneWidget);
    expect(find.text('提交反馈'), findsOneWidget);
    expect(find.text('官方回复'), findsOneWidget);
  });

  testWidgets('Service + user chat render composers', (tester) async {
    await tester.pumpWidget(wrap(const ServicePage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('输入消息…'), findsOneWidget);
    await tester
        .pumpWidget(wrap(const UserChatPage(peer: 'weichen', name: 'weichen')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('发送私信…'), findsOneWidget);
  });

  testWidgets('Edit profile: review notice, gender chips, submit',
      (tester) async {
    await tester.pumpWidget(wrap(const EditProfilePage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('资料修改需管理员审核通过后生效'), findsOneWidget);
    expect(find.text('小姐姐'), findsOneWidget);
    expect(find.text('小哥哥'), findsOneWidget);
    expect(find.text('提交审核'), findsOneWidget);
  });

  testWidgets('My profile: blank banner + 资料修改 button', (tester) async {
    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('未设置主页背景'), findsOneWidget);
    expect(find.text('资料修改'), findsOneWidget);
  });
}
