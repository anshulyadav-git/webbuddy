/// Reason a URL was blocked.
enum BlockReason { ad, tracker, malware, social }

/// Result returned by [AdBlocker.checkUrl].
class BlockResult {
  final BlockReason reason;
  final String domain;
  const BlockResult(this.reason, this.domain);
}

/// Lightweight ad/tracker blocker using domain-pattern matching.
class AdBlocker {
  // ── Ad networks ─────────────────────────────────────────────────────────────
  static const List<String> _adDomains = [
    // Google ads
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'ads.google.com', 'pagead2.googlesyndication.com', 'adservice.google.com',
    'adservice.google.co.in', 'googleads.g.doubleclick.net',
    'googleoptimize.com', 'g.doubleclick.net', 'ad.mo.doubleclick.net',
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
    'prebid.org', 'prebid.io', 'magnite.com', 'springserve.com',
    'freewheel.tv', 'yieldlab.net', 'yieldlab.de', 'yastatic.net',
    'adhese.com', 'adagio.io', 'adprime.media', 'adskeeper.com',
    'mediavine.com', 'raptive.com', 'adthrive.com', 'setupad.com',
    'setupad.net', 'monumetric.com', 'ezoic.net', 'ezoic.com',
    'valueclick.com', 'conversantmedia.com', 'conversant.com',
    'undertone.com', 'yieldoptimizer.com', 'aerserv.com',
    'adcash.com', 'hilltopads.net', 'pushground.com', 'propellerads.com',
    'popcash.net', 'popads.net', 'trafficstars.com', 'adsterra.com',
    'juicyads.com', 'exoclick.com', 'trafficjunky.net',
    // YouTube-specific ad domains
    'ad.youtube.com', 'ads.youtube.com',
    'static.doubleclick.net', 'www3.doubleclick.net',
  ];

  // ── Tracker / analytics domains ──────────────────────────────────────────
  static const List<String> _trackerDomains = [
    'scorecardresearch.com', 'quantserve.com', 'moatads.com',
    'google-analytics.com', 'googletagmanager.com', 'googletagservices.com',
    'hotjar.com', 'mixpanel.com', 'segment.com', 'amplitude.com',
    'chartbeat.com', 'newrelic.com', 'ssl.google-analytics.com',
    'mc.yandex.ru', 'counter.ok.ru', 'top-fwz1.mail.ru', 'mc.yandex.com',
    'ads.yahoo.com', 'ads.twitter.com', 'pixel.advertising.com',
    'analytics.twitter.com', 'ads-twitter.com', 'static.ads-twitter.com',
    'bat.bing.com', 'c.bing.com', 'clarity.ms', 'bluekai.com',
    'demdex.net', 'krxd.net', 'exelator.com', 'eyeota.net',
    'adsymptotic.com', 'adkernel.com', 'vidazoo.com', 'synacor.com',
    'adhigh.net', 'adspirit.de', 'adspirit.net', 'ad-stir.com',
    'bizographics.com', 'bkrtx.com', 'brand-display.com',
    'brightmountainmedia.com', 'burt.io',
    'cdn.doubleverify.com', 'doubleverify.com',
    'cdn.ias.me', 'ias.me', 'integralads.com',
    'contextweb.com', 'cxense.com', 'liveintent.com',
    'mathtag.com', 'mfadsrvr.com', 'nexac.com',
    'omtrdc.net', 'owneriq.net', 'pagefair.com', 'parsely.com',
    'pippio.com', 'rfihub.com', 'rfihub.net', 'rlcdn.com',
    'sail-horizon.com', 'sekindo.com', 'serving-sys.com',
    'sizmek.com', 'stickyadstv.com', 'tiqcdn.com',
    'trustarc.com', 'turn.com',
    'tynt.com', 'uip.me', 'unrulymedia.com', 'userzoom.com',
    'vi.ai', 'vidoomy.com', 'vmweb.net', 'w55c.net',
    'xaxis.com', 'yimg.com', 'yldbt.com',
    // FullStory / Heap / Intercom trackers
    'fullstory.com', 'rs6.net', 'heap.io', 'heapanalytics.com',
    'intercom.io', 'intercomcdn.com', 'intercomassets.com',
    'drift.com', 'driftt.com', 'hubspot.com', 'hs-scripts.com',
    'hs-banner.com', 'hsforms.com', 'hubapi.com',
    'loggly.com', 'sentry.io', 'bugsnag.com', 'rollbar.com',
    // Quantcast
    'quantcount.com', 'quantserve.com',
    // TikTok analytics
    'ads-api.tiktok.com', 'analytics.tiktok.com', 'mon.tiktok.com',
    'log.byteoversea.com', 'analytics.byteoversea.net',
    // LinkedIn Insight Tag
    'snap.licdn.com', 'px.ads.linkedin.com', 'dc.ads.linkedin.com',
    // Hotjar (also in ad, kept here for tracker routing)
    'script.hotjar.com', 'static.hotjar.com', 'vars.hotjar.com',
    'insights.hotjar.com',
    // Pinterest Tag
    'ct.pinterest.com',
    // Snap pixel
    'sc-static.net', 'snapchat.com/tr',
  ];

  // ── Social widgets (tracker-class but distinct visually) ─────────────────
  static const List<String> _socialDomains = [
    'connect.facebook.net', 'pixel.facebook.com',
    'an.facebook.com', 'audiencenetwork.com',
    'platform.twitter.com', 'syndication.twitter.com',
    'platform.linkedin.com', 'badge.linkedin.com',
    'apis.google.com', 'plusone.google.com',
    'widgets.pinterest.com',
    'assets.pinterest.com',
    'platform.instagram.com',
  ];

  // ── Malware / phishing ──────────────────────────────────────────────────
  static const List<String> _malwareDomains = [
    'malware-traffic-analysis.net',
    'trackingprotection.cdn.mozilla.net',
    'phishtank.com',
    '2o7.net',
    'webtracking.co.in',
    'trafficredirect.in',
    'clicksor.com', 'clicksor.net',
    'viralads.com',
    'pop-under.ru',
    'bestadbid.com',
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

  /// Returns a [BlockResult] if the URL should be blocked, or `null` if clean.
  static BlockResult? checkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      for (final domain in _malwareDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return BlockResult(BlockReason.malware, domain);
        }
      }
      for (final domain in _adDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return BlockResult(BlockReason.ad, domain);
        }
      }
      for (final domain in _trackerDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return BlockResult(BlockReason.tracker, domain);
        }
      }
      for (final domain in _socialDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return BlockResult(BlockReason.social, domain);
        }
      }
      final path = uri.path.toLowerCase();
      for (final pattern in _adPathPatterns) {
        if (path.contains(pattern)) {
          return BlockResult(BlockReason.ad, host);
        }
      }
      // Block YouTube pre-roll / mid-roll ad requests
      if ((host.contains('youtube.com') || host.contains('googlevideo.com')) &&
          _ytAdQueryMarkers.any((m) => url.contains(m))) {
        return BlockResult(BlockReason.ad, host);
      }
    } catch (_) {}
    return null;
  }

  /// Legacy convenience wrapper — returns true if the URL should be blocked.
  static bool isAdUrl(String url) => checkUrl(url) != null;

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
