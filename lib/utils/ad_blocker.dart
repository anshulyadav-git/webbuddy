/// Lightweight ad/tracker blocker using domain-pattern matching.
class AdBlocker {
  static const List<String> _adDomains = [
    // Google ads
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'ads.google.com', 'pagead2.googlesyndication.com', 'adservice.google.com',
    'adservice.google.co.in', 'googleads.g.doubleclick.net',
    // Programmatic / exchanges
    'adnxs.com', 'adsrvr.org', 'advertising.com', 'adzerk.net',
    'amazon-adsystem.com', 'adform.net', 'media.net', 'outbrain.com',
    'taboola.com', 'casalemedia.com', 'pubmatic.com', 'rubiconproject.com',
    'openx.net', 'criteo.com', 'criteo.net', 'tradedesk.com', 'lijit.com',
    'sharethrough.com', 'triplelift.com', 'indexexchange.com',
    'appnexus.com', 'sovrn.com', 'lkqd.net', 'smartadserver.com',
    'yieldmo.com', 'spotxchange.com', 'telaria.com', 'rhythmone.com',
    'undertone.com', 'adtelligent.com', 'districtm.io', 'sortable.com',
    'bidswitch.net', 'emxdgt.com', '33across.com', 'onetag.net',
    'improvedigital.com', 'yieldlove.com', 'adtech.de', 'onetag.com',
    // Trackers / analytics
    'scorecardresearch.com', 'quantserve.com', 'moatads.com',
    'google-analytics.com', 'googletagmanager.com', 'googletagservices.com',
    'hotjar.com', 'mixpanel.com', 'segment.com', 'amplitude.com',
    'chartbeat.com', 'newrelic.com', 'ssl.google-analytics.com',
    'mc.yandex.ru', 'counter.ok.ru', 'top-fwz1.mail.ru',
    'ads.yahoo.com', 'ads.twitter.com', 'pixel.advertising.com',
    'analytics.twitter.com', 'ads-twitter.com', 'static.ads-twitter.com',
    // Facebook / Meta
    'connect.facebook.net', 'facebook.com/tr', 'pixel.facebook.com',
    'an.facebook.com', 'audiencenetwork.com',
    // Misc trackers
    'bat.bing.com', 'c.bing.com', 'clarity.ms', 'bluekai.com',
    'demdex.net', 'krxd.net', 'exelator.com', 'eyeota.net',
    'adsymptotic.com', 'adkernel.com', 'vidazoo.com', 'synacor.com',
    'adhigh.net', 'adspirit.de', 'adspirit.net', 'ad-stir.com',
    'bizographics.com', 'bkrtx.com', 'brand-display.com',
    'brightmountainmedia.com', 'burt.io', 'buysellads.com',
    'cdn.adnxs.com', 'cdn.doubleverify.com', 'doubleverify.com',
    'cdn.ias.me', 'ias.me', 'integralads.com',
    'contextweb.com', 'cxense.com', 'liveintent.com',
    'mathtag.com', 'mfadsrvr.com', 'n.pr', 'nexac.com',
    'omtrdc.net', 'owneriq.net', 'pagefair.com', 'parsely.com',
    'pippio.com', 'rfihub.com', 'rfihub.net', 'rlcdn.com',
    'sail-horizon.com', 'sekindo.com', 'serving-sys.com',
    'sizmek.com', 'stickyadstv.com', 'tiqcdn.com',
    'trafficjunky.net', 'trustarc.com', 'turn.com',
    'tynt.com', 'uip.me', 'unrulymedia.com', 'userzoom.com',
    'vi.ai', 'vidoomy.com', 'vmweb.net', 'w55c.net',
    'xaxis.com', 'yimg.com', 'yldbt.com',
    // YouTube-specific ad domains
    'ad.youtube.com', 'ads.youtube.com', 'googlevideo.com/videoplayback',
    'static.doubleclick.net', 'www3.doubleclick.net',
    // Malware / phishing patterns
    'malware-traffic-analysis.net',
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
    '/pagead/',
    '/adserving/',
    '/adclick',
    '/adiframe',
    '/adlog',
    '/adpartner',
    '/adscript',
    '/adserver',
    '/adsystem',
    '/advert',
    '/affiliate',
    '/clicktracking',
    '/conversion_pixel',
    '/creativecdn',
    '/cgi-bin/ads',
    '/sponsored',
    '/promo/',
    '/promos/',
  ];

  // YouTube ad video IDs served via redirects look like &ad_type= or &adformat=
  static const List<String> _ytAdQueryMarkers = [
    'ad_type=',
    'adformat=',
    '&oad=',
    'ad_flags=',
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
      // Block YouTube pre-roll / mid-roll ad requests
      if ((host.contains('youtube.com') || host.contains('googlevideo.com')) &&
          _ytAdQueryMarkers.any((m) => url.contains(m))) {
        return true;
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
        'igshid',
        'dclid',
        'zanpid',
        'adgroupid',
        'adposition',
        'creative',
        'device',
        'matchtype',
        'network',
        'placement',
        'target',
        'loc_interest_ms',
        'loc_physical_ms',
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
