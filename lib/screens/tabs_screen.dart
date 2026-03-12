import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../models/tab_model.dart';

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final tabs = tabProvider.tabs;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tabs.length} Tab${tabs.length == 1 ? '' : 's'}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              tabProvider.openNewTab();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Tab'),
          ),
          TextButton.icon(
            onPressed: () {
              tabProvider.openNewTab(incognito: true);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Private'),
          ),
        ],
      ),
      body: tabs.isEmpty
          ? _emptyState(context)
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: tabs.length,
              itemBuilder: (ctx, i) => _TabCard(
                tab: tabs[i],
                isActive: i == tabProvider.activeIndex,
                onTap: () {
                  tabProvider.switchTab(i);
                  Navigator.pop(context);
                },
                onClose: () => tabProvider.closeTab(i),
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
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
              child: Row(
                children: [
                  if (tab.isIncognito)
                    const Icon(
                      Icons.privacy_tip,
                      size: 14,
                      color: Colors.purpleAccent,
                    )
                  else if (tab.url.startsWith('https://'))
                    Icon(Icons.lock, size: 14, color: Colors.green.shade400)
                  else
                    Icon(
                      Icons.public,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab content preview area
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
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.url == 'about:blank'
                                ? Icons.add_circle_outline
                                : Icons.web,
                            size: 36,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
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
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
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
