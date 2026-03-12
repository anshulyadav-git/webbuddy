import 'package:webview_flutter/webview_flutter.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  String? faviconUrl;
  bool isLoading;
  bool isIncognito;
  bool isDesktopMode;
  int textSize; // 50–200, default 100 = 100%
  double scrollPosition;
  WebViewController? controller;

  BrowserTab({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.faviconUrl,
    this.isLoading = false,
    this.isIncognito = false,
    this.isDesktopMode = false,
    this.textSize = 100,
    this.scrollPosition = 0.0,
    this.controller,
  });

  BrowserTab copyWith({
    String? url,
    String? title,
    String? faviconUrl,
    bool? isLoading,
    bool? isIncognito,
    double? scrollPosition,
    WebViewController? controller,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      isLoading: isLoading ?? this.isLoading,
      isIncognito: isIncognito ?? this.isIncognito,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      controller: controller ?? this.controller,
    );
  }
}
