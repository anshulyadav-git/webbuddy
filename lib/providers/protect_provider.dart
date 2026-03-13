import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/protect_stats_model.dart';

class ProtectProvider extends ChangeNotifier {
  ProtectStats _stats = const ProtectStats();

  /// Domains where WebBuddy Protect is disabled (user opted out per-site).
  final Set<String> _exemptDomains = {};

  ProtectStats get stats => _stats;
  Set<String> get exemptDomains => Set.unmodifiable(_exemptDomains);

  // ── Stat recording ──────────────────────────────────────────────────────────

  void recordAdBlock() {
    _stats = _stats.copyWith(adsBlocked: _stats.adsBlocked + 1);
    notifyListeners();
  }

  void recordTrackerBlock() {
    _stats = _stats.copyWith(trackersBlocked: _stats.trackersBlocked + 1);
    notifyListeners();
  }

  void recordFingerprintBlock() {
    _stats = _stats.copyWith(
      fingerprintsBlocked: _stats.fingerprintsBlocked + 1,
    );
    notifyListeners();
  }

  void recordHttpsUpgrade() {
    _stats = _stats.copyWith(httpsUpgrades: _stats.httpsUpgrades + 1);
    notifyListeners();
  }

  void resetStats() {
    _stats = const ProtectStats();
    notifyListeners();
  }

  // ── Per-site exceptions ─────────────────────────────────────────────────────

  bool isExempt(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return _exemptDomains.any((d) => host == d || host.endsWith('.$d'));
    } catch (_) {
      return false;
    }
  }

  void exemptSite(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      if (host.isNotEmpty) {
        _exemptDomains.add(host);
        notifyListeners();
        _save();
      }
    } catch (_) {}
  }

  void removeExemption(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      _exemptDomains.remove(host);
      notifyListeners();
      _save();
    } catch (_) {}
  }

  void clearExemptions() {
    _exemptDomains.clear();
    notifyListeners();
    _save();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('protect_exempt_domains');
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _exemptDomains.addAll(list);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'protect_exempt_domains',
      jsonEncode(_exemptDomains.toList()),
    );
  }
}
