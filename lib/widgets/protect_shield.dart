import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/protect_provider.dart';
import '../providers/settings_provider.dart';

/// Animated shield icon shown in the address bar.
/// Tapping it opens the WebBuddy Protect dashboard.
class ProtectShield extends StatefulWidget {
  /// The current URL — used to check if this site is exempted.
  final String? currentUrl;
  final VoidCallback? onTap;

  const ProtectShield({super.key, this.currentUrl, this.onTap});

  @override
  State<ProtectShield> createState() => _ProtectShieldState();
}

class _ProtectShieldState extends State<ProtectShield>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final protect = context.watch<ProtectProvider>();
    final settings = context.watch<SettingsProvider>();

    final bool protectOn =
        settings.adBlockEnabled || settings.fingerprintProtectionEnabled;
    final bool siteExempt =
        widget.currentUrl != null && protect.isExempt(widget.currentUrl!);
    final bool isBlank = widget.currentUrl == null ||
        widget.currentUrl == 'about:blank' ||
        widget.currentUrl!.isEmpty;

    final _ShieldState state;
    if (isBlank || !protectOn) {
      state = _ShieldState.disabled;
    } else if (siteExempt) {
      state = _ShieldState.partial;
    } else {
      state = _ShieldState.protected;
    }

    final int blockCount = protect.stats.totalBlocked;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing glow for protected state
            if (state == _ShieldState.protected)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Container(
                  width: 26 + _pulse.value * 4,
                  height: 26 + _pulse.value * 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5733)
                        .withValues(alpha: 0.15 * _pulse.value),
                  ),
                ),
              ),
            // Shield icon
            Icon(
              state == _ShieldState.disabled
                  ? Icons.shield_outlined
                  : state == _ShieldState.partial
                      ? Icons.shield_rounded
                      : Icons.shield_rounded,
              size: 20,
              color: _shieldColor(state),
            ),
            // Small counter badge
            if (blockCount > 0 && state == _ShieldState.protected)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5733),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    blockCount > 99 ? '99+' : '$blockCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _shieldColor(_ShieldState state) {
    return switch (state) {
      _ShieldState.protected => const Color(0xFFFF5733),
      _ShieldState.partial => Colors.amber,
      _ShieldState.disabled => Colors.grey,
    };
  }
}

enum _ShieldState { protected, partial, disabled }
