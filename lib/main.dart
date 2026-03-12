import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/history_provider.dart';
import 'providers/tab_provider.dart';
import 'utils/app_theme.dart';
import 'screens/browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  final bookmarkProvider = BookmarkProvider();
  await bookmarkProvider.init();

  final historyProvider = HistoryProvider();
  await historyProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: bookmarkProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProxyProvider2<
          HistoryProvider,
          SettingsProvider,
          TabProvider
        >(
          create: (ctx) => TabProvider(
            ctx.read<HistoryProvider>(),
            ctx.read<SettingsProvider>(),
          )..openNewTab(),
          update: (ctx, history, settings, previous) {
            previous?.updateSettings();
            return previous!;
          },
        ),
      ],
      child: const WebBuddyApp(),
    ),
  );
}

class WebBuddyApp extends StatelessWidget {
  const WebBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'WebBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const BrowserScreen(),
    );
  }
}
