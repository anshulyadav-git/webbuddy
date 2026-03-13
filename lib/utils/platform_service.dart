import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformService {
  static const _channel = MethodChannel('com.webbuddy.webbuddy/platform');

  // ── Picture-in-Picture ─────────────────────────────────────────────────────
  static Future<bool> enterPip() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Add shortcut to home screen ────────────────────────────────────────────
  static Future<bool> addToHomeScreen(String title, String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('addToHomeScreen', {
        'title': title,
        'url': url,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Share URL via Android share sheet ───────────────────────────────────────
  static Future<void> shareUrl(String title, String url) async {
    try {
      await _channel.invokeMethod('shareUrl', {'title': title, 'url': url});
    } catch (_) {}
  }

  // ── Open video URL in external player ─────────────────────────────────────
  static Future<bool> openInExternalPlayer(String url) async {
    final uri = Uri.parse(url);
    // First try forcing an external app chooser
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  // ── Full-screen / immersive mode toggle ───────────────────────────────────
  static Future<void> enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ── Detect if a URL looks like a video resource ───────────────────────────
  static bool isVideoUrl(String url) {
    final lower = url.toLowerCase();
    final videoExtensions = [
      '.mp4',
      '.mkv',
      '.webm',
      '.avi',
      '.mov',
      '.flv',
      '.m4v',
      '.3gp',
    ];
    return videoExtensions.any((ext) => lower.contains(ext));
  }

  // ── Media notification controls ────────────────────────────────────
  static Future<void> showMediaNotification(
    String title, {
    bool playing = true,
  }) async {
    try {
      await _channel.invokeMethod('showMediaNotification', {
        'title': title,
        'playing': playing,
      });
    } catch (_) {}
  }

  static Future<void> updateMediaNotification({required bool playing}) async {
    try {
      await _channel.invokeMethod('updateMediaNotification', {
        'playing': playing,
      });
    } catch (_) {}
  }

  static Future<void> dismissMediaNotification() async {
    try {
      await _channel.invokeMethod('dismissMediaNotification');
    } catch (_) {}
  }

  // ── Update media playback progress ────────────────────────────────────
  static Future<void> updateMediaProgress(
    int positionSec,
    int durationSec,
  ) async {
    try {
      await _channel.invokeMethod('updateMediaProgress', {
        'position': positionSec,
        'duration': durationSec,
      });
    } catch (_) {}
  }

  static Future<void> seekMedia(int seconds) async {
    try {
      await _channel.invokeMethod('seekMedia', {'seconds': seconds});
    } catch (_) {}
  }

  // ── Download a file via Android DownloadManager ───────────────────────────
  static Future<bool> downloadFile(String url, {String? filename}) async {
    try {
      // Derive a filename from the URL if not provided.
      final name = filename ??
          Uri.parse(url).pathSegments.lastWhere(
                (s) => s.isNotEmpty,
                orElse: () => 'download',
              );
      final result = await _channel.invokeMethod<bool>('downloadFile', {
        'url': url,
        'filename': name,
        'mime': 'application/octet-stream',
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
