import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tab_model.dart';
import '../providers/bookmark_provider.dart';
import '../providers/tab_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/platform_service.dart';
import '../utils/url_utils.dart';

class AddressBar extends StatefulWidget {
  const AddressBar({super.key});

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late TextEditingController _controller;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      setState(() => _isEditing = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _controller.selectAll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    context.read<TabProvider>().loadUrl(input);
    _focusNode.unfocus();
  }

  void _showMenu(BuildContext context, BrowserTab? tab) {
    final tabProvider = context.read<TabProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final theme = Theme.of(context);

    final hasPage = tab != null && tab.url != 'about:blank';
    final isBookmarked = hasPage && bookmarkProvider.isBookmarked(tab.url);
    final isSpeedDial = hasPage && settingsProvider.isSpeedDial(tab.url);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (hasPage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  UrlUtils.displayUrl(tab.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            const Divider(height: 1),
            // Reload
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Reload'),
              onTap: () {
                Navigator.pop(ctx);
                tabProvider.reload();
              },
            ),
            // Share
            if (hasPage)
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(ctx);
                  PlatformService.shareUrl(tab.title, tab.url);
                },
              ),
            // Bookmark
            if (hasPage)
              ListTile(
                leading: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  color: isBookmarked ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isBookmarked) {
                    await bookmarkProvider.remove(tab.url);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bookmark removed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    await bookmarkProvider.add(tab.title, tab.url);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bookmark added'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            // Add to → Speed Dials
            if (hasPage)
              ListTile(
                leading: Icon(
                  Icons.speed_rounded,
                  color: isSpeedDial ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  isSpeedDial ? 'Remove from Speed Dials' : 'Add to Speed Dials',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isSpeedDial) {
                    settingsProvider.removeSpeedDial(tab.url);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from Speed Dials'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    settingsProvider.addSpeedDial(tab.title, tab.url);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to Speed Dials'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            // Add to Home Screen
            if (hasPage)
              ListTile(
                leading: const Icon(Icons.add_to_home_screen_rounded),
                title: const Text('Add to Home Screen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok =
                      await PlatformService.addToHomeScreen(tab.title, tab.url);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Shortcut added to home screen'
                              : 'Could not add shortcut',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            // Find in Page
            if (hasPage)
              ListTile(
                leading: const Icon(Icons.search_rounded),
                title: const Text('Find in Page'),
                onTap: () {
                  Navigator.pop(ctx);
                  tabProvider.activateFindInPage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final tab = tabProvider.activeTab;
    final theme = Theme.of(context);

    if (!_isEditing) {
      _controller.text = tab != null && tab.url != 'about:blank'
          ? UrlUtils.displayUrl(tab.url)
          : '';
    }

    final isSecure = tab?.url.startsWith('https://') ?? false;
    final isIncognito = tab?.isIncognito ?? false;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isIncognito
            ? Colors.purple.shade900.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (isIncognito)
            const Icon(Icons.privacy_tip, size: 16, color: Colors.purpleAccent)
          else if (isSecure)
            Icon(Icons.lock, size: 16, color: Colors.green.shade400)
          else
            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.url,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search or enter address',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          // Loading indicator
          if (tab?.isLoading == true)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          // Clear button while editing
          if (_isEditing)
            GestureDetector(
              onTap: () {
                _controller.clear();
                _focusNode.requestFocus();
              },
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          // 3-dot menu (always visible)
          GestureDetector(
            onTap: () => _showMenu(context, tab),
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on TextEditingController {
  void selectAll() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
