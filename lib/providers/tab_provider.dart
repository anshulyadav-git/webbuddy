import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/tab_model.dart';
import '../utils/ad_blocker.dart';
import '../utils/platform_service.dart';
import 'history_provider.dart';
import 'settings_provider.dart';

class TabProvider extends ChangeNotifier {
  final HistoryProvider _historyProvider;
  final SettingsProvider _settingsProvider;

  TabProvider(this._historyProvider, this._settingsProvider);

  final List<BrowserTab> _tabs = [];
  int _activeIndex = 0;
  String? _pendingLinkUrl;
  bool _findInPageActive = false;
  bool _autoplayEnabled = true;

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  BrowserTab? get activeTab => _tabs.isEmpty ? null : _tabs[_activeIndex];
  int get tabCount => _tabs.length;
  String? get pendingLinkUrl => _pendingLinkUrl;
  bool get findInPageActive => _findInPageActive;
  bool get autoplayEnabled => _autoplayEnabled;
  void setAutoplay(bool v) { _autoplayEnabled = v; }
  void clearPendingLinkUrl() {
    _pendingLinkUrl = null;
  }

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
            // Inject media event hooks so notification bar controls work
            await tab.controller?.runJavaScript(_mediaHookJs);
            // Inject long-press link → open in new tab
            await tab.controller?.runJavaScript(_navHookJs);
            // Inject YouTube enhancements if on YouTube
            if (url.contains('youtube.com') || url.contains('youtu.be')) {
              await tab.controller?.runJavaScript(_youtubeEnhancementsJs);
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
      )
      ..addJavaScriptChannel(
        'WebBuddyMedia',
        onMessageReceived: (msg) => _onMediaEvent(msg.message, tab),
      )
      ..addJavaScriptChannel(
        'WebBuddyNav',
        onMessageReceived: (msg) => _onNavEvent(msg.message),
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

  Future<void> toggleDesktopMode() async {
    final tab = activeTab;
    if (tab == null) return;
    tab.isDesktopMode = !tab.isDesktopMode;
    const desktopUA =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    const mobileUA =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    await tab.controller?.setUserAgent(
      tab.isDesktopMode ? desktopUA : mobileUA,
    );
    await tab.controller?.reload();
    notifyListeners();
  }

  bool get isDesktopMode => activeTab?.isDesktopMode ?? false;

  // JavaScript: long-press any link → open in new tab
  static const _navHookJs = '''
(function() {
  if (window._wbNavHooked) return;
  window._wbNavHooked = true;
  var _timer = null;
  document.addEventListener('touchstart', function(e) {
    var el = e.target;
    while (el && el.tagName !== 'A') el = el.parentElement;
    if (!el || !el.href) return;
    var href = el.href;
    _timer = setTimeout(function() {
      _timer = null;
      try { WebBuddyNav.postMessage(href); } catch(x) {}
    }, 600);
  }, {passive: true});
  document.addEventListener('touchend',   function() { if (_timer) { clearTimeout(_timer); _timer = null; } }, {passive: true});
  document.addEventListener('touchmove',  function() { if (_timer) { clearTimeout(_timer); _timer = null; } }, {passive: true});
})();
''';

  // JavaScript injected on every page load to detect media play/pause
  static const _mediaHookJs = '''
(function() {
  function hook(el) {
    if (el._wbHooked) return;
    el._wbHooked = true;
    el.addEventListener('play', function() {
      try { WebBuddyMedia.postMessage(JSON.stringify({e:'play',t:document.title})); } catch(x){}
    });
    el.addEventListener('pause', function() {
      try { WebBuddyMedia.postMessage(JSON.stringify({e:'pause'})); } catch(x){}
    });
    el.addEventListener('ended', function() {
      try { WebBuddyMedia.postMessage(JSON.stringify({e:'ended'})); } catch(x){}
    });
    el.addEventListener('timeupdate', function() {
      if (!el._wbTU || (Date.now() - el._wbTU) > 3000) {
        el._wbTU = Date.now();
        try { WebBuddyMedia.postMessage(JSON.stringify({e:'progress',pos:Math.floor(el.currentTime),dur:Math.floor(el.duration||0)})); } catch(x){}
      }
    });
    // Already playing when hooked (e.g. YouTube autoplay) — fire immediately
    if (!el.paused && !el.ended) {
      try { WebBuddyMedia.postMessage(JSON.stringify({e:'play',t:document.title})); } catch(x){}
    }
  }
  function scan() {
    (document.querySelectorAll('audio,video') || []).forEach(hook);
  }
  scan();
  new MutationObserver(function(ms) {
    ms.forEach(function(m) {
      m.addedNodes.forEach(function(n) {
        if (!n || n.nodeType !== 1) return;
        // Direct match
        if (n.tagName === 'VIDEO' || n.tagName === 'AUDIO') hook(n);
        // Nested match — catches YouTube's <video> inside <div id="movie_player">
        if (n.querySelectorAll) n.querySelectorAll('audio,video').forEach(hook);
      });
    });
  }).observe(document.body || document.documentElement, {childList: true, subtree: true});
  // Fallback scan every 500ms for 15s — catches lazy-loaded players
  var _t = 0;
  var _iv = setInterval(function() { scan(); if (++_t >= 30) clearInterval(_iv); }, 500);
})();
''';

  // YouTube-specific JavaScript enhancements
  static const _youtubeEnhancementsJs = r'''
(function() {
  if (window._wbYTHooked) return;
  window._wbYTHooked = true;

  // ── 1. Auto-skip ads ──────────────────────────────────────────────────────
  function skipAds() {
    // Click "Skip Ads" button when it appears
    var skipBtn = document.querySelector('.ytp-skip-ad-button, .ytp-ad-skip-button, .ytp-ad-skip-button-modern');
    if (skipBtn) { skipBtn.click(); return; }
    // If unskippable ad is playing: mute, set currentTime to end
    var adBadge = document.querySelector('.ytp-ad-badge, .ad-showing');
    if (adBadge) {
      var video = document.querySelector('video');
      if (video && !isNaN(video.duration) && video.duration > 0) {
        video.currentTime = video.duration;
        video.muted = false;
      }
    }
  }

  // ── 2. Remove ad overlay elements ────────────────────────────────────────
  function removeAdOverlays() {
    var selectors = [
      '.ytp-ad-overlay-container',
      '.ytp-ad-text-overlay',
      '.ytp-ad-image-overlay',
      '#player-ads',
      '#masthead-ad',
      '.ytd-banner-promo-renderer',
      'ytd-banner-promo-renderer',
      'ytd-statement-banner-renderer',
      '.ytd-ad-slot-renderer',
      'ytd-ad-slot-renderer',
      '#panels ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-ads"]',
      'ytd-merch-shelf-renderer',
      'ytd-ad-break-service-renderer',
      '.ytp-ce-element',      // card overlay ads
      '.ytp-suggested-action', // suggested action ads
    ];
    selectors.forEach(function(s) {
      document.querySelectorAll(s).forEach(function(el) {
        el.remove();
      });
    });
  }

  // ── 3. Keep background audio alive (disable visibility-based pause) ───────
  Object.defineProperty(document, 'hidden', { get: function() { return false; } });
  Object.defineProperty(document, 'visibilityState', { get: function() { return 'visible'; } });
  document.dispatchEvent(new Event('visibilitychange'));

  // ── 4. Enable 1080p / best quality preference ─────────────────────────────
  // Store preference so YouTube's own quality selector picks it up
  try {
    var qs = window.yt && window.yt.config_ && window.yt.config_.QUALITY_DEFAULTS;
    if (!qs) {
      localStorage.setItem('yt-player-quality', JSON.stringify({data:{quality:1080}}));
    }
  } catch(e) {}

  // ── 5. Run loop ───────────────────────────────────────────────────────────
  var _interval = setInterval(function() {
    skipAds();
    removeAdOverlays();
  }, 500);

  // Stop after 30s on stable pages to save CPU
  setTimeout(function() {
    clearInterval(_interval);
    // Slower sweep after that
    setInterval(function() { skipAds(); removeAdOverlays(); }, 3000);
  }, 30000);

  // Also run on navigation (YouTube is a SPA)
  var _lastUrl = location.href;
  new MutationObserver(function() {
    if (location.href !== _lastUrl) {
      _lastUrl = location.href;
      setTimeout(function() { skipAds(); removeAdOverlays(); }, 800);
    }
  }).observe(document.body || document.documentElement, {childList:true, subtree:true});
})();
''';

  void _onNavEvent(String url) {
    if (url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      _pendingLinkUrl = url;
      notifyListeners();
    }
  }

  Future<void> seekActiveMedia(int seconds) async {
    final tab = activeTab;
    if (tab == null) return;
    await tab.controller?.runJavaScript(
      '(function(){var v=document.querySelector("video,audio");'
      'if(v){v.currentTime=Math.max(0,(v.currentTime||0)+($seconds));}})()',
    );
  }

  void _onMediaEvent(String message, BrowserTab tab) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final event = data['e'] as String?;
      final title = (data['t'] as String?)?.isNotEmpty == true
          ? data['t'] as String
          : tab.title;
      switch (event) {
        case 'play':
          PlatformService.showMediaNotification(title, playing: true);
        case 'pause':
          PlatformService.updateMediaNotification(playing: false);
        case 'ended':
          PlatformService.dismissMediaNotification();
        case 'progress':
          final pos = (data['pos'] as num?)?.toInt() ?? 0;
          final dur = (data['dur'] as num?)?.toInt() ?? 0;
          if (dur > 0) PlatformService.updateMediaProgress(pos, dur);
      }
    } catch (_) {}
  }

  int get textSize => activeTab?.textSize ?? 100;

  Future<void> _applyZoom() async {
    final tab = activeTab;
    if (tab == null) return;
    await tab.controller?.runJavaScript(
      'document.body.style.zoom="${tab.textSize}%";'
      'document.documentElement.style.zoom="${tab.textSize}%";',
    );
    notifyListeners();
  }

  Future<void> zoomIn() async {
    final tab = activeTab;
    if (tab == null) return;
    if (tab.textSize < 200) tab.textSize = (tab.textSize + 10).clamp(50, 200);
    await _applyZoom();
  }

  Future<void> zoomOut() async {
    final tab = activeTab;
    if (tab == null) return;
    if (tab.textSize > 50) tab.textSize = (tab.textSize - 10).clamp(50, 200);
    await _applyZoom();
  }

  Future<void> resetZoom() async {
    final tab = activeTab;
    if (tab == null) return;
    tab.textSize = 100;
    await _applyZoom();
  }

  void activateFindInPage() {
    _findInPageActive = true;
    notifyListeners();
  }

  Future<void> deactivateFindInPage() async {
    _findInPageActive = false;
    await activeTab?.controller?.runJavaScript(
      'if(window.getSelection){window.getSelection().removeAllRanges();}',
    );
    notifyListeners();
  }

  Future<void> findInPage(String query) async {
    if (activeTab?.controller == null) return;
    await activeTab!.controller!.runJavaScript(
      'window._wbQ=${jsonEncode(query)};'
      'if(window._wbQ)window.find(window._wbQ,false,false,true);',
    );
  }

  Future<void> findInPageNext() async {
    await activeTab?.controller?.runJavaScript(
      'if(window._wbQ)window.find(window._wbQ,false,false,true);',
    );
  }

  Future<void> findInPagePrev() async {
    await activeTab?.controller?.runJavaScript(
      'if(window._wbQ)window.find(window._wbQ,false,true,true);',
    );
  }

  void openInBackground(String url, {bool incognito = false}) {
    final tab = BrowserTab(
      id: const Uuid().v4(),
      url: url,
      title: url,
      isIncognito: incognito,
    );
    _tabs.add(tab);
    _initController(tab);
    notifyListeners();
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
