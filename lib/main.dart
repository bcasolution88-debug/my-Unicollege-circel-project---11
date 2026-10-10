import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CampusCircleApp());
}

class CampusCircleApp extends StatelessWidget {
  const CampusCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final p = state.palette;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                p.isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: p.surface,
          ));
          return MaterialApp(
            title: '圈子社区',
            debugShowCheckedModeBanner: false,
            theme: buildThemeData(p),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
