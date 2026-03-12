import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/tab_model.dart';
import '../utils/ad_blocker.dart';
import 'history_provider.dart';
import 'settings_provider.dart';

class TabProvider extends ChangeNotifier {
  final HistoryProvider _historyProvider;
  final SettingsProvider _settingsProvider;

  TabProvider(this._historyProvider, this._settingsProvider);

  final List<BrowserTab> _tabs = [];
  int _activeIndex = 0;

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  BrowserTab? get activeTab => _tabs.isEmpty ? null : _tabs[_activeIndex];
  int get tabCount => _tabs.length;

  void openNewTab({String? url, bool incognito = false}) {
    final tab = BrowserTab(
      id: const Uuid().v4(),
      url: url ?? 'about:blank',
      title: url ?? 'New Tab',
      isIncognito: incognito,
    );
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    _initController(tab);
    notifyListeners();
  }

  void closeTab(int index) {
    if (_tabs.length == 1) {
      openNewTab();
    }
    _tabs.removeAt(index);
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void _initController(BrowserTab tab) {
    final controller = WebViewController()
      ..setJavaScriptMode(
        _settingsProvider.javascriptEnabled
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            tab.isLoading = true;
            tab.url = url;
            notifyListeners();
          },
          onPageFinished: (url) async {
            tab.isLoading = false;
            tab.url = url;
            final title = await tab.controller?.getTitle() ?? url;
            tab.title = title.isNotEmpty ? title : url;
            if (!tab.isIncognito) {
              _historyProvider.add(tab.title, url);
            }
            notifyListeners();
          },
          onNavigationRequest: (request) {
            if (_settingsProvider.adBlockEnabled &&
                AdBlocker.isAdUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            if (_settingsProvider.httpsUpgradeEnabled) {
              final upgraded = AdBlocker.upgradeToHttps(request.url);
              if (upgraded != request.url) {
                tab.controller?.loadRequest(Uri.parse(upgraded));
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            tab.isLoading = false;
            notifyListeners();
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );

    tab.controller = controller;

    if (tab.url != 'about:blank') {
      final url = _settingsProvider.httpsUpgradeEnabled
          ? AdBlocker.upgradeToHttps(tab.url)
          : tab.url;
      controller.loadRequest(Uri.parse(url));
    }
  }

  void loadUrl(String rawInput) {
    if (activeTab == null) return;
    final url = _resolveUrl(rawInput);
    activeTab!.url = url;
    activeTab!.isLoading = true;
    activeTab!.title = url;
    notifyListeners();
    activeTab!.controller?.loadRequest(Uri.parse(url));
  }

  String _resolveUrl(String input) {
    input = input.trim();
    if (input.isEmpty) return _settingsProvider.homepage;
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return _settingsProvider.httpsUpgradeEnabled
          ? AdBlocker.upgradeToHttps(input)
          : input;
    }
    final domainPattern = RegExp(r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/.*)?$');
    if (domainPattern.hasMatch(input)) {
      return 'https://$input';
    }
    return _settingsProvider.searchUrl + Uri.encodeQueryComponent(input);
  }

  Future<void> reload() async {
    await activeTab?.controller?.reload();
  }

  Future<void> goBack() async {
    if (await activeTab?.controller?.canGoBack() == true) {
      await activeTab?.controller?.goBack();
    }
  }

  Future<void> goForward() async {
    if (await activeTab?.controller?.canGoForward() == true) {
      await activeTab?.controller?.goForward();
    }
  }

  Future<bool> canGoBack() async {
    return await activeTab?.controller?.canGoBack() ?? false;
  }

  Future<bool> canGoForward() async {
    return await activeTab?.controller?.canGoForward() ?? false;
  }

  void updateSettings() {
    for (final tab in _tabs) {
      tab.controller?.setJavaScriptMode(
        _settingsProvider.javascriptEnabled
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      );
    }
    notifyListeners();
  }
}
