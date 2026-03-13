import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/protect_provider.dart';
import '../providers/settings_provider.dart';

/// Full-screen modal showing WebBuddy Protect stats, level control,
/// and per-site disable toggle.
class ProtectScreen extends StatelessWidget {
  /// The URL of the current page, used for per-site exemption.
  final String? currentUrl;

  const ProtectScreen({super.key, this.currentUrl});

  static Future<void> show(BuildContext context, {String? currentUrl}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProtectScreen(currentUrl: currentUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final protect = context.watch<ProtectProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final siteExempt =
        currentUrl != null && protect.isExempt(currentUrl!);
    final isBlankPage = currentUrl == null ||
        currentUrl == 'about:blank' ||
        currentUrl!.isEmpty;

    final String? displayHost = _extractHost(currentUrl);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────────
            _ProtectHeader(
              siteExempt: siteExempt,
              isBlankPage: isBlankPage,
              adBlockEnabled: settings.adBlockEnabled,
              fpEnabled: settings.fingerprintProtectionEnabled,
            ),

            const SizedBox(height: 20),

            // ── Stats row ────────────────────────────────────────────────────
            _StatsRow(stats: protect.stats),

            const SizedBox(height: 20),

            // ── Per-site toggle ──────────────────────────────────────────────
            if (!isBlankPage && displayHost != null) ...[
              _SectionTitle('This Site'),
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    siteExempt
                        ? Icons.shield_outlined
                        : Icons.shield_rounded,
                    color: siteExempt
                        ? Colors.grey
                        : const Color(0xFFFF5733),
                  ),
                  title: Text(
                    siteExempt
                        ? 'Protection disabled for $displayHost'
                        : 'Protection active for $displayHost',
                  ),
                  subtitle: Text(
                    siteExempt
                        ? 'Tap to re-enable WebBuddy Protect on this site'
                        : 'Tap to disable WebBuddy Protect on this site',
                  ),
                  value: !siteExempt,
                  activeThumbColor: const Color(0xFFFF5733),
                  onChanged: (val) {
                    if (val) {
                      protect.removeExemption(currentUrl!);
                    } else {
                      protect.exemptSite(currentUrl!);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Protection Level ─────────────────────────────────────────────
            _SectionTitle('Protection Level'),
            Card(
              child: RadioGroup<ProtectionLevel>(
                groupValue: settings.protectionLevel,
                onChanged: (v) {
                  if (v != null) settings.setProtectionLevel(v);
                },
                child: Column(
                  children: ProtectionLevel.values.map((level) {
                    final selected = settings.protectionLevel == level;
                    return RadioListTile<ProtectionLevel>(
                      value: level,
                      title: Text(
                        _levelLabel(level),
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(_levelDescription(level)),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick toggles (mirrors Settings) ────────────────────────────
            _SectionTitle('Quick Controls'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.block),
                    title: const Text('Ad Blocking'),
                    value: settings.adBlockEnabled,
                    activeThumbColor: const Color(0xFFFF5733),
                    onChanged: settings.setAdBlock,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.track_changes),
                    title: const Text('Tracker Blocking'),
                    value: settings.trackerBlockEnabled,
                    activeThumbColor: const Color(0xFFFF5733),
                    onChanged: settings.setTrackerBlock,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Fingerprint Defense'),
                    value: settings.fingerprintProtectionEnabled,
                    activeThumbColor: const Color(0xFFFF5733),
                    onChanged: settings.setFingerprintProtection,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline),
                    title: const Text('HTTPS Upgrade'),
                    value: settings.httpsUpgradeEnabled,
                    activeThumbColor: const Color(0xFFFF5733),
                    onChanged: settings.setHttpsUpgrade,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Reset stats / clear exemptions ───────────────────────────────
            _SectionTitle('Manage'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded),
                    title: const Text('Reset Block Counters'),
                    onTap: () {
                      protect.resetStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Counters reset')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.playlist_remove_rounded),
                    title: const Text('Clear Site Exceptions'),
                    subtitle: Text(
                      '${protect.exemptDomains.length} site(s) exempted',
                    ),
                    onTap: protect.exemptDomains.isEmpty
                        ? null
                        : () {
                            protect.clearExemptions();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exceptions cleared')),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _levelLabel(ProtectionLevel level) => switch (level) {
        ProtectionLevel.basic => 'Basic',
        ProtectionLevel.standard => 'Standard (Recommended)',
        ProtectionLevel.strict => 'Strict',
      };

  String _levelDescription(ProtectionLevel level) => switch (level) {
        ProtectionLevel.basic => 'Ad blocking + HTTPS upgrade only',
        ProtectionLevel.standard =>
          'Ads, trackers, canvas/WebGL/navigator/WebRTC fingerprinting',
        ProtectionLevel.strict =>
          'Standard + AudioContext, Battery, Font & Screen spoofing',
      };

  String? _extractHost(String? url) {
    if (url == null || url.isEmpty || url == 'about:blank') return null;
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProtectHeader extends StatelessWidget {
  final bool siteExempt;
  final bool isBlankPage;
  final bool adBlockEnabled;
  final bool fpEnabled;

  const _ProtectHeader({
    required this.siteExempt,
    required this.isBlankPage,
    required this.adBlockEnabled,
    required this.fpEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = (adBlockEnabled || fpEnabled) && !siteExempt;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: active
                  ? [
                      const Color(0xFFFF5733).withValues(alpha: 0.25),
                      Colors.transparent,
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
            ),
          ),
          child: Icon(
            Icons.shield_rounded,
            size: 40,
            color: active ? const Color(0xFFFF5733) : Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isBlankPage
              ? 'WebBuddy Protect'
              : siteExempt
                  ? 'Protection Paused'
                  : active
                      ? 'You\'re Protected'
                      : 'Protection Disabled',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          isBlankPage
              ? 'Privacy protection for every site you visit'
              : siteExempt
                  ? 'WebBuddy Protect is off for this site'
                  : active
                      ? 'Ads, trackers and fingerprinters are being blocked'
                      : 'Enable protection in the controls below',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic stats; // ProtectStats

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Ads\nBlocked',
          value: stats.adsBlocked,
          icon: Icons.block,
          color: const Color(0xFFFF5733),
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Trackers\nBlocked',
          value: stats.trackersBlocked,
          icon: Icons.track_changes,
          color: const Color(0xFFE94560),
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Fingerprints\nDefended',
          value: stats.fingerprintsBlocked,
          icon: Icons.fingerprint,
          color: Colors.deepPurpleAccent,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'HTTPS\nUpgrades',
          value: stats.httpsUpgrades,
          icon: Icons.lock_outline,
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
    );
  }
}
