class UrlUtils {
  static bool isValidUrl(String input) {
    try {
      final uri = Uri.parse(input);
      return uri.hasScheme && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  static String displayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host + (uri.path.length > 1 ? uri.path : '');
    } catch (_) {
      return url;
    }
  }

  static String faviconUrl(String pageUrl) {
    try {
      final uri = Uri.parse(pageUrl);
      return '${uri.scheme}://${uri.host}/favicon.ico';
    } catch (_) {
      return '';
    }
  }

  static bool isSearchQuery(String input) {
    input = input.trim();
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return false;
    }
    final domainPattern = RegExp(r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/.*)?$');
    return !domainPattern.hasMatch(input);
  }

  static String? extractDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }
}
