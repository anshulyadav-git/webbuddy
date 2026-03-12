package com.webbuddy.webbuddy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Rational
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL         = "com.webbuddy.webbuddy/platform"
    private val PIP_CHANNEL     = "com.webbuddy.webbuddy/pip_events"
    private val MEDIA_CTRL_CH   = "com.webbuddy.webbuddy/media_controls"

    private val MEDIA_NOTIF_ID  = 1001
    private val MEDIA_NOTIF_CH  = "webbuddy_media"
    private val ACTION_PLAY     = "com.webbuddy.webbuddy.MEDIA_PLAY"
    private val ACTION_PAUSE    = "com.webbuddy.webbuddy.MEDIA_PAUSE"
    private val ACTION_STOP     = "com.webbuddy.webbuddy.MEDIA_STOP"

    private var pipEventSink: EventChannel.EventSink? = null
    private var mediaCtrlSink: EventChannel.EventSink? = null
    private var mediaTitle   = "WebBuddy"
    private var mediaPlaying = false

    private val mediaReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_PLAY  -> { mediaPlaying = true;  showMediaNotification(); mediaCtrlSink?.success("play")  }
                ACTION_PAUSE -> { mediaPlaying = false; showMediaNotification(); mediaCtrlSink?.success("pause") }
                ACTION_STOP  -> { mediaPlaying = false; dismissMediaNotification(); mediaCtrlSink?.success("stop") }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createMediaNotificationChannel()

        val filter = IntentFilter().apply {
            addAction(ACTION_PLAY); addAction(ACTION_PAUSE); addAction(ACTION_STOP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(mediaReceiver, filter)
        }

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
                    "showMediaNotification" -> {
                        mediaTitle   = call.argument<String>("title")   ?: "Playing media"
                        mediaPlaying = call.argument<Boolean>("playing") ?: true
                        showMediaNotification()
                        result.success(true)
                    }
                    "updateMediaNotification" -> {
                        mediaPlaying = call.argument<Boolean>("playing") ?: true
                        showMediaNotification()
                        result.success(true)
                    }
                    "dismissMediaNotification" -> {
                        dismissMediaNotification()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { pipEventSink = sink }
                override fun onCancel(args: Any?) { pipEventSink = null }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CTRL_CH)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { mediaCtrlSink = sink }
                override fun onCancel(args: Any?) { mediaCtrlSink = null }
            })
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(mediaReceiver) } catch (_: Exception) {}
        dismissMediaNotification()
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipEventSink?.success(isInPictureInPictureMode)
    }

    // ── Media notification ────────────────────────────────────────────────────

    private fun createMediaNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                MEDIA_NOTIF_CH, "Media Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Browser media controls"; setShowBadge(false) }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(ch)
        }
    }

    private fun pi(action: String): PendingIntent {
        val i = Intent(action).setPackage(packageName)
        return PendingIntent.getBroadcast(
            this, action.hashCode(), i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun showMediaNotification() {
        val nm = getSystemService(NotificationManager::class.java) ?: return
        val openPi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val b = NotificationCompat.Builder(this, MEDIA_NOTIF_CH)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(mediaTitle)
            .setContentText("WebBuddy Browser")
            .setContentIntent(openPi)
            .setOngoing(mediaPlaying)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSilent(true)
        if (mediaPlaying) {
            b.addAction(android.R.drawable.ic_media_pause, "Pause", pi(ACTION_PAUSE))
        } else {
            b.addAction(android.R.drawable.ic_media_play,  "Play",  pi(ACTION_PLAY))
        }
        b.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", pi(ACTION_STOP))
        nm.notify(MEDIA_NOTIF_ID, b.build())
    }

    private fun dismissMediaNotification() {
        getSystemService(NotificationManager::class.java)?.cancel(MEDIA_NOTIF_ID)
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

