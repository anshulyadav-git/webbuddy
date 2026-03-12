import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../providers/bookmark_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Privacy & Security'),
          SwitchListTile(
            secondary: const Icon(Icons.block),
            title: const Text('Ad Blocking'),
            subtitle: const Text('Block ads on visited websites'),
            value: settings.adBlockEnabled,
            onChanged: settings.setAdBlock,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.track_changes),
            title: const Text('Tracker Blocking'),
            subtitle: const Text('Block cross-site trackers'),
            value: settings.trackerBlockEnabled,
            onChanged: settings.setTrackerBlock,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('HTTPS Upgrade'),
            subtitle: const Text('Upgrade HTTP connections to HTTPS'),
            value: settings.httpsUpgradeEnabled,
            onChanged: settings.setHttpsUpgrade,
          ),
          const Divider(),
          _SectionHeader('Browser'),
          SwitchListTile(
            secondary: const Icon(Icons.javascript),
            title: const Text('JavaScript'),
            subtitle: const Text('Enable JavaScript on web pages'),
            value: settings.javascriptEnabled,
            onChanged: settings.setJavascript,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.image_outlined),
            title: const Text('Show Images'),
            subtitle: const Text('Load images on web pages'),
            value: settings.showImages,
            onChanged: settings.setShowImages,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: settings.setDarkMode,
          ),
          const Divider(),
          _SectionHeader('Search'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Engine'),
            subtitle: Text(settings.searchEngine),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSearchEnginePicker(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Homepage'),
            subtitle: Text(settings.homepage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editHomepage(context, settings),
          ),
          const Divider(),
          _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear History'),
            onTap: () => _clearHistory(context),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_remove_outlined),
            title: const Text('Clear Bookmarks'),
            onTap: () => _clearBookmarks(context),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'WebBuddy v1.0.0 — Privacy-first browser',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSearchEnginePicker(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose Search Engine'),
        children: settings.searchEngines
            .map(
              (engine) => ListTile(
                leading: Icon(
                  settings.searchEngine == engine
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: settings.searchEngine == engine
                      ? Theme.of(ctx).colorScheme.primary
                      : null,
                ),
                title: Text(engine),
                onTap: () {
                  settings.setSearchEngine(engine);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _editHomepage(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.homepage);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Homepage'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) settings.setHomepage(url);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('History cleared')));
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearBookmarks(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Bookmarks'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookmarkProvider>().clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarks cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
