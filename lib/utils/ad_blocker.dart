/// Lightweight ad/tracker blocker using domain-pattern matching.
/// In a production app, replace with a full EasyList/uBlock filter engine.
class AdBlocker {
  static const List<String> _adDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adnxs.com',
    'adsrvr.org',
    'advertising.com',
    'adzerk.net',
    'amazon-adsystem.com',
    'ads.yahoo.com',
    'adform.net',
    'media.net',
    'outbrain.com',
    'taboola.com',
    'scorecardresearch.com',
    'quantserve.com',
    'moatads.com',
    'casalemedia.com',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'criteo.com',
    'facebook.com/tr',
    'connect.facebook.net',
    'google-analytics.com',
    'googletagmanager.com',
    'googletagservices.com',
    'hotjar.com',
    'mixpanel.com',
    'segment.com',
    'amplitude.com',
    'chartbeat.com',
    'newrelic.com',
    'ads.twitter.com',
    'pixel.advertising.com',
    'ssl.google-analytics.com',
    'mc.yandex.ru',
  ];

  static const List<String> _adPathPatterns = [
    '/ads/',
    '/ad/',
    '/advertisement/',
    '/banner/',
    '/popup/',
    '/tracking/',
    '/tracker/',
    '/pixel.gif',
    '/beacon',
  ];

  static bool isAdUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      for (final domain in _adDomains) {
        if (host == domain || host.endsWith('.$domain')) return true;
      }
      final path = uri.path.toLowerCase();
      for (final pattern in _adPathPatterns) {
        if (path.contains(pattern)) return true;
      }
    } catch (_) {}
    return false;
  }

  static String upgradeToHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  static String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Strip common tracking query params
      const trackingParams = {
        'utm_source',
        'utm_medium',
        'utm_campaign',
        'utm_term',
        'utm_content',
        'fbclid',
        'gclid',
        'msclkid',
        '_ga',
        'mc_eid',
        'ref',
        'source',
        'campaign',
        'yclid',
      };
      final cleaned = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((k, _) => trackingParams.contains(k.toLowerCase()));
      return uri
          .replace(queryParameters: cleaned.isEmpty ? null : cleaned)
          .toString();
    } catch (_) {
      return url;
    }
  }
}
