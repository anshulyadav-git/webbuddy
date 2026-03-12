import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../models/tab_model.dart';

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final allTabs = tabProvider.tabs;
    final normal  = allTabs.where((t) => !t.isIncognito).toList();
    final private = allTabs.where((t) =>  t.isIncognito).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${allTabs.length} Tab${allTabs.length == 1 ? '' : 's'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Tab',
            onPressed: () { tabProvider.openNewTab(); Navigator.pop(context); },
          ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: 'New Private Tab',
            onPressed: () { tabProvider.openNewTab(incognito: true); Navigator.pop(context); },
          ),
        ],
      ),
      body: allTabs.isEmpty
          ? _emptyState(context)
          : CustomScrollView(
              slivers: [
                if (normal.isNotEmpty) ...[
                  _GroupHeader(
                    label: 'Normal Tabs',
                    count: normal.length,
                    icon: Icons.public_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    onCloseAll: () {
                      for (final t in [...normal]) {
                        final idx = tabProvider.tabs.indexOf(t);
                        if (idx != -1) tabProvider.closeTab(idx);
                      }
                    },
                    onNew: () { tabProvider.openNewTab(); Navigator.pop(context); },
                  ),
                  _tabGrid(context, normal, tabProvider),
                ],
                if (private.isNotEmpty) ...[
                  _GroupHeader(
                    label: 'Private Tabs',
                    count: private.length,
                    icon: Icons.privacy_tip_rounded,
                    color: Colors.purpleAccent,
                    onCloseAll: () {
                      for (final t in [...private]) {
                        final idx = tabProvider.tabs.indexOf(t);
                        if (idx != -1) tabProvider.closeTab(idx);
                      }
                    },
                    onNew: () { tabProvider.openNewTab(incognito: true); Navigator.pop(context); },
                  ),
                  _tabGrid(context, private, tabProvider, bottomPad: 24),
                ],
              ],
            ),
    );
  }

  SliverPadding _tabGrid(
    BuildContext context,
    List<BrowserTab> tabs,
    TabProvider tabProvider, {
    double bottomPad = 12,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final tab = tabs[i];
            final idx = tabProvider.tabs.indexOf(tab);
            return _TabCard(
              tab: tab,
              isActive: idx == tabProvider.activeIndex,
              onTap: () { tabProvider.switchTab(idx); Navigator.pop(context); },
              onClose: () => tabProvider.closeTab(idx),
            );
          },
          childCount: tabs.length,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tab_unselected, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No tabs open', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onCloseAll;
  final VoidCallback onNew;

  const _GroupHeader({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onCloseAll,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              '$label  ($count)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onNew,
              icon: Icon(Icons.add, size: 16, color: color),
              label: Text('New', style: TextStyle(fontSize: 12, color: color)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            TextButton.icon(
              onPressed: onCloseAll,
              icon: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.error),
              label: Text('Close all', style: TextStyle(fontSize: 12, color: theme.colorScheme.error)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab card ───────────────────────────────────────────────────────────────
class _TabCard extends StatelessWidget {
  final BrowserTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabCard({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tab.isIncognito
              ? Colors.purple.shade900.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? (tab.isIncognito ? Colors.purpleAccent : theme.colorScheme.primary)
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
              child: Row(
                children: [
                  if (tab.isIncognito)
                    const Icon(Icons.privacy_tip, size: 14, color: Colors.purpleAccent)
                  else if (tab.url.startsWith('https://'))
                    Icon(Icons.lock, size: 14, color: Colors.green.shade400)
                  else
                    Icon(Icons.public, size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: tab.isIncognito
                      ? Colors.purple.shade900.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: tab.isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.url == 'about:blank' ? Icons.add_circle_outline : Icons.web,
                            size: 36,
                            color: tab.isIncognito
                                ? Colors.purpleAccent.withValues(alpha: 0.5)
                                : theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              tab.url == 'about:blank' ? 'New Tab' : tab.url,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
