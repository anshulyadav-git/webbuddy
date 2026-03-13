import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/history_provider.dart';
import 'providers/tab_provider.dart';
import 'providers/protect_provider.dart';
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

  final protectProvider = ProtectProvider();
  await protectProvider.load();

  // Private Session: if it was active last run, wipe history on startup.
  final wasPrivateSession = settingsProvider.privateSession;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: bookmarkProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: protectProvider),
        ChangeNotifierProxyProvider3<
          HistoryProvider,
          SettingsProvider,
          ProtectProvider,
          TabProvider
        >(
          create: (ctx) {
            final tp = TabProvider(
              ctx.read<HistoryProvider>(),
              ctx.read<SettingsProvider>(),
              ctx.read<ProtectProvider>(),
            );
            if (wasPrivateSession) {
              // Clear history from previous session, then open fresh tab.
              ctx.read<HistoryProvider>().clear();
              tp.openNewTab();
            } else {
              tp.openNewTab();
            }
            return tp;
          },
          update: (ctx, history, settings, protect, previous) {
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
