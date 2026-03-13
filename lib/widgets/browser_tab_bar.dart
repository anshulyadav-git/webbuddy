import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
// Removed unused import

class BrowserTabBar extends StatelessWidget {
  const BrowserTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final tabs = tabProvider.tabs;
    final activeIndex = tabProvider.activeIndex;

    return Container(
      color: Colors.grey[900],
      height: 48,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Tab',
            onPressed: () => tabProvider.openNewTab(),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return GestureDetector(
                  onTap: () => tabProvider.switchTab(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: index == activeIndex
                          ? Colors.blueGrey
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.web, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          tab.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white70,
                          ),
                          tooltip: 'Close Tab',
                          onPressed: () => tabProvider.closeTab(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
