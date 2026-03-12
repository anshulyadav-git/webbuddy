import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _adBlockEnabled = true;
  bool _trackerBlockEnabled = true;
  bool _httpsUpgradeEnabled = true;
  bool _javascriptEnabled = true;
  bool _darkMode = false;
  String _searchEngine = 'DuckDuckGo';
  String _homepage = 'https://duckduckgo.com';
  bool _showImages = true;
  List<Map<String, String>> _speedDials = [];

  bool get adBlockEnabled => _adBlockEnabled;
  bool get trackerBlockEnabled => _trackerBlockEnabled;
  bool get httpsUpgradeEnabled => _httpsUpgradeEnabled;
  bool get javascriptEnabled => _javascriptEnabled;
  bool get darkMode => _darkMode;
  String get searchEngine => _searchEngine;
  String get homepage => _homepage;
  bool get showImages => _showImages;
  List<Map<String, String>> get speedDials => List.unmodifiable(_speedDials);

  static const String _searchEngines = 'DuckDuckGo,Google,Bing,Brave';
  List<String> get searchEngines => _searchEngines.split(',');

  Map<String, String> get searchEngineUrls => {
    'DuckDuckGo': 'https://duckduckgo.com/?q=',
    'Google': 'https://www.google.com/search?q=',
    'Bing': 'https://www.bing.com/search?q=',
    'Brave': 'https://search.brave.com/search?q=',
  };

  String get searchUrl =>
      searchEngineUrls[_searchEngine] ?? 'https://duckduckgo.com/?q=';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _adBlockEnabled = prefs.getBool('adBlock') ?? true;
    _trackerBlockEnabled = prefs.getBool('trackerBlock') ?? true;
    _httpsUpgradeEnabled = prefs.getBool('httpsUpgrade') ?? true;
    _javascriptEnabled = prefs.getBool('javascript') ?? true;
    _darkMode = prefs.getBool('darkMode') ?? false;
    _searchEngine = prefs.getString('searchEngine') ?? 'DuckDuckGo';
    _homepage = prefs.getString('homepage') ?? 'https://duckduckgo.com';
    _showImages = prefs.getBool('showImages') ?? true;
    final raw = prefs.getString('speedDials');
    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      _speedDials = decoded
          .cast<Map<String, dynamic>>()
          .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adBlock', _adBlockEnabled);
    await prefs.setBool('trackerBlock', _trackerBlockEnabled);
    await prefs.setBool('httpsUpgrade', _httpsUpgradeEnabled);
    await prefs.setBool('javascript', _javascriptEnabled);
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('searchEngine', _searchEngine);
    await prefs.setString('homepage', _homepage);
    await prefs.setBool('showImages', _showImages);
    await prefs.setString('speedDials', jsonEncode(_speedDials));
  }

  void setAdBlock(bool value) {
    _adBlockEnabled = value;
    notifyListeners();
    _save();
  }

  void setTrackerBlock(bool value) {
    _trackerBlockEnabled = value;
    notifyListeners();
    _save();
  }

  void setHttpsUpgrade(bool value) {
    _httpsUpgradeEnabled = value;
    notifyListeners();
    _save();
  }

  void setJavascript(bool value) {
    _javascriptEnabled = value;
    notifyListeners();
    _save();
  }

  void setDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
    _save();
  }

  void setSearchEngine(String engine) {
    _searchEngine = engine;
    notifyListeners();
    _save();
  }

  void setHomepage(String url) {
    _homepage = url;
    notifyListeners();
    _save();
  }

  void setShowImages(bool value) {
    _showImages = value;
    notifyListeners();
    _save();
  }

  bool isSpeedDial(String url) => _speedDials.any((d) => d['url'] == url);

  void addSpeedDial(String title, String url) {
    if (isSpeedDial(url)) return;
    _speedDials.add({'title': title, 'url': url});
    notifyListeners();
    _save();
  }

  void removeSpeedDial(String url) {
    _speedDials.removeWhere((d) => d['url'] == url);
    notifyListeners();
    _save();
  }
}
