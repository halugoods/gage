package com.gage.gage_app

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.gage/media_scanner"
    private var pendingAudioResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_AUDIO = 2001

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_AUDIO) {
            val result = pendingAudioResult
            pendingAudioResult = null
            if (resultCode == RESULT_OK && data?.data != null) {
                try {
                    val uri = data.data!!
                    var fileName = "audio_${System.currentTimeMillis()}.mp3"
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            if (nameIndex != -1) {
                                val resolvedName = it.getString(nameIndex)
                                if (!resolvedName.isNullOrEmpty()) {
                                    fileName = resolvedName
                                }
                            }
                        }
                    }
                    val outputFile = File(cacheDir, fileName)
                    contentResolver.openInputStream(uri)?.use { input ->
                        FileOutputStream(outputFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    val map = HashMap<String, Any>()
                    map["path"] = outputFile.absolutePath
                    map["title"] = fileName
                    result?.success(map)
                } catch (e: Exception) {
                    result?.error("PICK_ERROR", e.message, null)
                }
            } else {
                result?.success(null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
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
                }
                "saveImageToGallery" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "struk_gage_${System.currentTimeMillis()}.png"
                    val albumName = "Gage by Halu Goods Indonesia"

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_DATA", "Byte array is empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/$albumName")
                                put(MediaStore.Images.Media.IS_PENDING, 1)
                            }

                            val resolver = applicationContext.contentResolver
                            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                            if (uri != null) {
                                resolver.openOutputStream(uri)?.use { outputStream ->
                                    outputStream.write(bytes)
                                    outputStream.flush()
                                }
                                values.clear()
                                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                                resolver.update(uri, values, null, null)
                                result.success(true)
                            } else {
                                result.error("INSERT_FAILED", "Failed to insert into MediaStore", null)
                            }
                        } else {
                            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                            val albumDir = File(picturesDir, albumName)
                            if (!albumDir.exists()) {
                                albumDir.mkdirs()
                            }
                            val targetFile = File(albumDir, fileName)
                            FileOutputStream(targetFile).use { fos ->
                                fos.write(bytes)
                                fos.flush()
                            }
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(targetFile.absolutePath),
                                arrayOf("image/png")
                            ) { _, _ -> }
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                "pickAudio" -> {
                    pendingAudioResult = result
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "audio/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(Intent.createChooser(intent, "Pilih File Audio"), REQUEST_CODE_PICK_AUDIO)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
