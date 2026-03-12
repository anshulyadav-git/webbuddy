package com.webbuddy.webbuddy

import android.app.PictureInPictureParams
import android.content.Intent
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL     = "com.webbuddy.webbuddy/platform"
    private val PIP_CHANNEL = "com.webbuddy.webbuddy/pip_events"

    private var pipEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel – imperative calls from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            enterPictureInPictureMode(params)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "addToHomeScreen" -> {
                        val title = call.argument<String>("title") ?: "WebBuddy"
                        val url   = call.argument<String>("url")   ?: ""
                        addShortcutToHomeScreen(title, url)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel – push PiP state changes to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    pipEventSink = sink
                }
                override fun onCancel(args: Any?) {
                    pipEventSink = null
                }
            })
    }

    // Auto-enter PiP when user presses Home (if a page is loaded)
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        }
    }

    // Notify Flutter whenever PiP mode changes
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipEventSink?.success(isInPictureInPictureMode)
    }

    private fun addShortcutToHomeScreen(title: String, url: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val shortcutManager = getSystemService(android.content.pm.ShortcutManager::class.java)
            if (shortcutManager != null && shortcutManager.isRequestPinShortcutSupported) {
                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = android.net.Uri.parse(url)
                    putExtra("shortcut_url", url)
                }
                val shortcutInfo = android.content.pm.ShortcutInfo.Builder(this, "shortcut_$url")
                    .setShortLabel(title.take(10))
                    .setLongLabel(title)
                    .setIcon(android.graphics.drawable.Icon.createWithResource(this, R.mipmap.ic_launcher))
                    .setIntent(launchIntent)
                    .build()
                shortcutManager.requestPinShortcut(shortcutInfo, null)
            }
        } else {
            @Suppress("DEPRECATION")
            val addIntent = Intent("com.android.launcher.action.INSTALL_SHORTCUT").apply {
                putExtra(Intent.EXTRA_SHORTCUT_NAME, title)
                val launchIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                putExtra(Intent.EXTRA_SHORTCUT_INTENT, launchIntent)
            }
            sendBroadcast(addIntent)
        }
    }
}

