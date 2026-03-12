import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/tab_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/address_bar.dart';
import '../widgets/browser_bottom_bar.dart';
import '../utils/platform_service.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _isFullScreen = false;
  bool _inPip = false;

  static const _pipChannel = EventChannel('com.webbuddy.webbuddy/pip_events');
  static const _mediaCtrlChannel = EventChannel(
    'com.webbuddy.webbuddy/media_controls',
  );

  @override
  void initState() {
    super.initState();
    _pipChannel.receiveBroadcastStream().listen((event) {
      if (mounted) setState(() => _inPip = event == true);
    }, onError: (_) {});

    _mediaCtrlChannel.receiveBroadcastStream().listen((event) async {
      if (!mounted) return;
      final tab = context.read<TabProvider>().activeTab;
      if (tab?.controller == null) return;
      final cmd = event.toString();
      if (cmd == 'play') {
        await tab!.controller!.runJavaScript(
          'document.querySelectorAll("video,audio").forEach(function(v){try{v.play();}catch(e){}});',
        );
      } else if (cmd == 'pause') {
        await tab!.controller!.runJavaScript(
          'document.querySelectorAll("video,audio").forEach(function(v){v.pause();});',
        );
      } else if (cmd == 'stop') {
        await tab!.controller!.runJavaScript(
          'document.querySelectorAll("video,audio").forEach(function(v){v.pause();v.currentTime=0;});',
        );
      } else if (cmd == 'prev') {
        await context.read<TabProvider>().goBack();
      } else if (cmd == 'next') {
        await context.read<TabProvider>().goForward();
      } else if (cmd.startsWith('seek:')) {
        final secs = int.tryParse(cmd.substring(5)) ?? 0;
        await context.read<TabProvider>().seekActiveMedia(secs);
      }
    }, onError: (_) {});
  }

  void _showLinkContextMenu(String url) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open in New Tab'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().openNewTab(url: url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Open in Private Tab'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().openNewTab(
                  url: url,
                  incognito: true,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tab_unselected_rounded),
              title: const Text('Open in Background'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().openInBackground(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Link'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: url));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleFullScreen() async {
    if (_isFullScreen) {
      await PlatformService.exitFullScreen();
    } else {
      await PlatformService.enterFullScreen();
    }
    setState(() => _isFullScreen = !_isFullScreen);
  }

  // Called when device back button / gesture is pressed
  Future<bool> _onWillPop(TabProvider tabProvider) async {
    final canGoBack = await tabProvider.canGoBack();
    if (canGoBack) {
      await tabProvider.goBack();
      return false; // stay in app
    }
    // Exit full screen first if active
    if (_isFullScreen) {
      await PlatformService.exitFullScreen();
      setState(() => _isFullScreen = false);
      return false;
    }
    return true; // let the system handle it (exit / go home)
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    context.watch<SettingsProvider>();
    final tab = tabProvider.activeTab;
    final isIncognito = tab?.isIncognito ?? false;
    final topPad = MediaQuery.of(context).padding.top;

    // Long-press link → show context menu
    final pendingUrl = tabProvider.pendingLinkUrl;
    if (pendingUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TabProvider>().clearPendingLinkUrl();
        _showLinkContextMenu(pendingUrl);
      });
    }

    // Hide everything when in PiP – show only the WebView
    if (_inPip) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: tab?.controller != null
            ? WebViewWidget(controller: tab!.controller!)
            : const SizedBox.shrink(),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(tabProvider);
        if (shouldPop && context.mounted) {
          // Move to background instead of closing (browser-like behaviour)
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isIncognito ? const Color(0xFF1A0E2E) : null,
        appBar: _isFullScreen
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(56 + topPad),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                      child: Row(
                        children: [
                          if (isIncognito)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.privacy_tip,
                                color: Colors.purpleAccent,
                                size: 20,
                              ),
                            ),
                          const Expanded(child: AddressBar()),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.fullscreen_rounded),
                              tooltip: 'Full screen',
                              onPressed: _toggleFullScreen,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        body: Stack(
          children: [
            tab == null || tab.url == 'about:blank'
                ? const _NewTabPage()
                : tab.controller != null
                ? WebViewWidget(controller: tab.controller!)
                : const Center(child: CircularProgressIndicator()),
            if (_isFullScreen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_exit_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Exit full screen',
                    onPressed: _toggleFullScreen,
                  ),
                ),
              ),
            if (tabProvider.findInPageActive)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _FindInPageBar(),
              ),
          ],
        ),
        bottomNavigationBar: _isFullScreen ? null : const BrowserBottomBar(),
      ),
    );
  }
}

class _NewTabPage extends StatelessWidget {
  const _NewTabPage();

  static const List<Map<String, dynamic>> _quickLinks = [
    {'label': 'Google', 'url': 'https://google.com', 'icon': Icons.search},
    {'label': 'Codex', 'url': 'https://openai.com/codex', 'icon': Icons.memory},
    {
      'label': 'YouTube',
      'url': 'https://youtube.com',
      'icon': Icons.play_circle_outline,
    },
    {
      'label': 'Gemini',
      'url': 'https://gemini.google.com',
      'icon': Icons.auto_awesome,
    },
    {'label': 'GitHub', 'url': 'https://github.com', 'icon': Icons.code},
    {'label': 'Reddit', 'url': 'https://reddit.com', 'icon': Icons.forum},
    {
      'label': 'Twitter',
      'url': 'https://twitter.com',
      'icon': Icons.alternate_email,
    },
    {
      'label': 'Wikipedia',
      'url': 'https://wikipedia.org',
      'icon': Icons.menu_book,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabProvider = context.read<TabProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3B5BDB), Color(0xFF7048E8)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B5BDB).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.language_rounded, color: Colors.white, size: 44),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF51CF66),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'WebBuddy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Private & Secure Browsing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Quick Access',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: _quickLinks.map((link) {
              return _QuickLinkTile(
                label: link['label'] as String,
                url: link['url'] as String,
                icon: link['icon'] as IconData,
                onTap: () => tabProvider.loadUrl(link['url'] as String),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _PrivacyStatsCard(),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final String label;
  final String url;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.label,
    required this.url,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Protection Active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ads & trackers are being blocked',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Find in Page overlay ───────────────────────────────────────────────────
class _FindInPageBar extends StatefulWidget {
  const _FindInPageBar();

  @override
  State<_FindInPageBar> createState() => _FindInPageBarState();
}

class _FindInPageBarState extends State<_FindInPageBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.read<TabProvider>();
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: Container(
        color: theme.colorScheme.surface,
        padding: EdgeInsets.fromLTRB(
          12,
          6,
          8,
          6 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Find in page...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (q) => tabProvider.findInPage(q),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
              onPressed: () => tabProvider.findInPagePrev(),
              tooltip: 'Previous',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => tabProvider.findInPageNext(),
              tooltip: 'Next',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => tabProvider.deactivateFindInPage(),
              tooltip: 'Close',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}
