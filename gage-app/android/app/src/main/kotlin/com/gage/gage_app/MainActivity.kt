package com.gage.gage_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.gage/media_scanner"
    private val BT_CHANNEL = "com.gage/bluetooth"
    private var pendingAudioResult: MethodChannel.Result? = null
    private var btPendingResult: MethodChannel.Result? = null
    private var btSocket: BluetoothSocket? = null
    private var btOutputStream: OutputStream? = null
    private val REQUEST_CODE_PICK_AUDIO = 2001
    private val REQUEST_CODE_ENABLE_BT = 2002
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_BT) {
            val result = btPendingResult
            btPendingResult = null
            result?.success(resultCode == RESULT_OK)
        }
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    result.success(adapter?.isEnabled ?: false)
                }
                "requestBluetoothEnable" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) {
                        result.success(false)
                    } else if (!adapter.isEnabled) {
                        btPendingResult = result
                        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                        startActivityForResult(intent, REQUEST_CODE_ENABLE_BT)
                    } else {
                        result.success(true)
                    }
                }
                "openBluetoothSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "scanDevices" -> {
                    try {
                        val adapter = BluetoothAdapter.getDefaultAdapter()
                        if (adapter == null || !adapter.isEnabled) {
                            result.success(emptyList<Map<String, String>>())
                            return@setMethodCallHandler
                        }
                        val devices = mutableListOf<Map<String, String>>()
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                            == PackageManager.PERMISSION_GRANTED) {
                            for (d in adapter.bondedDevices) {
                                devices.add(mapOf(
                                    "name" to (d.name ?: "Printer"),
                                    "address" to (d.address ?: "")
                                ))
                            }
                        }
                        result.success(devices)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, String>>())
                    }
                }
                "connectDevice" -> {
                    val address = call.argument<String>("address") ?: ""
                    if (address.isEmpty()) {
                        result.error("INVALID_ADDRESS", "Address is empty", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val adapter = BluetoothAdapter.getDefaultAdapter()
                            if (adapter == null || !adapter.isEnabled) {
                                runOnUiThread { result.error("BT_OFF", "Bluetooth is off", null) }
                                return@Thread
                            }
                            try { btSocket?.close() } catch (_: Exception) {}
                            btSocket = null
                            btOutputStream = null

                            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                                != PackageManager.PERMISSION_GRANTED) {
                                runOnUiThread { result.error("NO_PERMISSION", "Bluetooth permission denied", null) }
                                return@Thread
                            }

                            val device: BluetoothDevice = adapter.getRemoteDevice(address)
                            btSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                            btSocket?.connect()
                            btOutputStream = btSocket?.outputStream
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            try { btSocket?.close() } catch (_: Exception) {}
                            btSocket = null
                            btOutputStream = null
                            runOnUiThread { result.error("CONNECT_FAILED", e.message, null) }
                        }
                    }.start()
                }
                "sendBytes" -> {
                    val data = call.argument<ByteArray>("data")
                    if (data == null || btOutputStream == null) {
                        result.error("NOT_CONNECTED", "No active connection", null)
                        return@setMethodCallHandler
                    }
                    try {
                        btOutputStream?.write(data)
                        btOutputStream?.flush()
                        result.success(true)
                    } catch (e: Exception) {
                        try { btSocket?.close() } catch (_: Exception) {}
                        btSocket = null
                        btOutputStream = null
                        result.error("SEND_FAILED", e.message, null)
                    }
                }
                "disconnectDevice" -> {
                    try { btSocket?.close() } catch (_: Exception) {}
                    btSocket = null
                    btOutputStream = null
                    result.success(true)
                }
                "isConnected" -> {
                    result.success(btSocket?.isConnected ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }
}
