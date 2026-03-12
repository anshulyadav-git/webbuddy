import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../providers/settings_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<TabProvider>().activeTab;
    context.watch<SettingsProvider>();
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
          if (tab?.isLoading == true)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else if (_isEditing)
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
            )
          else
            GestureDetector(
              onTap: () => context.read<TabProvider>().reload(),
              child: Icon(
                Icons.refresh,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
