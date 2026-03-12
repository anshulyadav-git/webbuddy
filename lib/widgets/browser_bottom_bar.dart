import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../providers/bookmark_provider.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tabs_screen.dart';
import '../utils/platform_service.dart';

class BrowserBottomBar extends StatelessWidget {
  const BrowserBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final theme = Theme.of(context);
    final tab = tabProvider.activeTab;
    final isBookmarked = tab != null
        ? bookmarkProvider.isBookmarked(tab.url)
        : false;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: _NavBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => tabProvider.goBack(),
                  tooltip: 'Back',
                ),
              ),
              Expanded(
                child: _NavBtn(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => tabProvider.goForward(),
                  tooltip: 'Forward',
                ),
              ),
              Expanded(
                child: _NavBtn(
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? theme.colorScheme.primary : null,
                  onTap: () {
                    if (tab == null || tab.url == 'about:blank') return;
                    if (isBookmarked) {
                      bookmarkProvider.remove(tab.url);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bookmark removed'),
                          duration: Duration(seconds: 2),
                      ),
                    );
                    } else {
                      bookmarkProvider.add(tab.title, tab.url);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bookmark added'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                ),
              ),
              Expanded(
                child: _TabCountButton(
                  count: tabProvider.tabCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TabsScreen()),
                  ),
                ),
              ),
              Expanded(
                child: _NavBtn(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showMenu(context, tabProvider),
                  tooltip: 'More',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, TabProvider tabProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BrowserMenu(tabProvider: tabProvider),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _NavBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _TabCountButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _TabCountButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Tabs',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                width: 1.8,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowserMenu extends StatelessWidget {
  final TabProvider tabProvider;

  const _BrowserMenu({required this.tabProvider});

  @override
  Widget build(BuildContext context) {
    // Use Consumer so zoom/desktop state changes rebuild the sheet live
    return Consumer<TabProvider>(
      builder: (context, tabProv, _) => _buildContent(context, tabProv),
    );
  }

  Widget _buildContent(BuildContext context, TabProvider tabProvider) {
    final theme = Theme.of(context);
    final tab = tabProvider.activeTab;
    final currentUrl = tab?.url ?? '';
    final hasPage = currentUrl.isNotEmpty && currentUrl != 'about:blank';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MenuItem(
              icon: Icons.add_rounded,
              label: 'New Tab',
              onTap: () {
                Navigator.pop(context);
                tabProvider.openNewTab();
              },
            ),
            _MenuItem(
              icon: Icons.privacy_tip_rounded,
              label: 'New Private Tab',
              onTap: () {
                Navigator.pop(context);
                tabProvider.openNewTab(incognito: true);
              },
            ),
            const Divider(height: 1),
            // ── External video player ──────────────────────────────────────
            _MenuItem(
              icon: Icons.play_circle_outline_rounded,
              label: 'Play video externally',
              onTap: () async {
                Navigator.pop(context);
                if (!hasPage) return;
                final launched = await PlatformService.openInExternalPlayer(
                  currentUrl,
                );
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No external player found'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            // ── Picture-in-Picture ─────────────────────────────────────────
            _MenuItem(
              icon: Icons.picture_in_picture_rounded,
              label: 'Run in background (PiP)',
              onTap: () async {
                Navigator.pop(context);
                final ok = await PlatformService.enterPip();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PiP not supported on this device'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            // ── Desktop mode + Text size ───────────────────────────────────
            _DesktopZoomTile(tabProvider: tabProvider, hasPage: hasPage),
            // ── Add to home screen ─────────────────────────────────────────
            _MenuItem(
              icon: Icons.add_to_home_screen_rounded,
              label: 'Add to home screen',
              onTap: () async {
                Navigator.pop(context);
                if (!hasPage) return;
                final title = tab?.title ?? currentUrl;
                await PlatformService.addToHomeScreen(title, currentUrl);
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.bookmark_border_rounded,
              label: 'Bookmarks',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  } // end _buildContent
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      dense: true,
    );
  }
}

// ── Combined Desktop Mode toggle + text zoom row ───────────────────────────
class _DesktopZoomTile extends StatelessWidget {
  final TabProvider tabProvider;
  final bool hasPage;

  const _DesktopZoomTile({required this.tabProvider, required this.hasPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = tabProvider.isDesktopMode;
    final zoom = tabProvider.textSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Desktop mode toggle
          Icon(
            Icons.desktop_windows_rounded,
            size: 22,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Desktop mode', style: theme.textTheme.bodyMedium),
          ),
          Switch(
            value: isDesktop,
            onChanged: hasPage
                ? (_) async => tabProvider.toggleDesktopMode()
                : null,
          ),
          const SizedBox(width: 8),
          // Zoom out
          _ZoomBtn(
            icon: Icons.remove_rounded,
            onTap: hasPage ? () async => tabProvider.zoomOut() : null,
          ),
          // Zoom level — tap to reset
          GestureDetector(
            onTap: hasPage ? () async => tabProvider.resetZoom() : null,
            child: Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                '$zoom%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: zoom != 100
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Zoom in
          _ZoomBtn(
            icon: Icons.add_rounded,
            onTap: hasPage ? () async => tabProvider.zoomIn() : null,
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
