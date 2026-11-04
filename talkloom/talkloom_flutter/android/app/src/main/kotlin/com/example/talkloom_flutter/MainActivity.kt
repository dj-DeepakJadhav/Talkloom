package com.example.talkloom_flutter

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the app send users to its own settings page to re-grant the
        // microphone after a permanent denial.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "talkloom/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openAppSettings") {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
        // Share-target intake: Instagram, YouTube, browsers, etc. send
        // ACTION_SEND with text/plain here. Each share is delivered once.
        runCatching { collectSharedText(intent) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "talkloom/share")
            .setMethodCallHandler { call, result ->
                if (call.method == "takeSharedText") {
                    val text = pendingSharedText
                    pendingSharedText = null
                    result.success(text)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        runCatching { collectSharedText(intent) }
    }

    private fun collectSharedText(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type != "text/plain") return
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
            ?: intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!text.isNullOrBlank()) pendingSharedText = text
    }
}
