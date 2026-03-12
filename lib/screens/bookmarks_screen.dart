import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/tab_provider.dart';
import '../models/bookmark_model.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bookmarks = bookmarkProvider.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          if (bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all',
              onPressed: () => _confirmClear(context, bookmarkProvider),
            ),
        ],
      ),
      body: bookmarks.isEmpty
          ? _emptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bookmarks.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (ctx, i) => _BookmarkTile(
                bookmark: bookmarks[i],
                onOpen: () {
                  context.read<TabProvider>().loadUrl(bookmarks[i].url);
                  Navigator.pop(context);
                },
                onDelete: () => bookmarkProvider.remove(bookmarks[i].url),
              ),
            ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 72,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon while browsing to save pages.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, BookmarkProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Bookmarks'),
        content: const Text('This will delete all bookmarks. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          bookmark.title.isNotEmpty ? bookmark.title[0].toUpperCase() : 'W',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(bookmark.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        bookmark.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: onDelete,
        tooltip: 'Remove',
      ),
      onTap: onOpen,
    );
  }
}
