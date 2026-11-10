package com.gage.gage_app

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.gage/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val filePath = call.argument<String>("path")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(file.absolutePath),
                            arrayOf("video/mp4")
                        ) { path, uri ->
                            // MediaStore indexed successfully
                        }

                        // Broadcast scan intent for broader Samsung Gallery indexation
                        val scanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                        scanIntent.data = Uri.fromFile(file)
                        applicationContext.sendBroadcast(scanIntent)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
