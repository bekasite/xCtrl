package dev.xprime.xctl

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.concurrent.ConcurrentLinkedQueue

data class CommandTask(
    val sender: String,
    val message: String,
    val timestamp: Long = System.currentTimeMillis()
)

class CommandService : Service() {
    companion object {
        const val CHANNEL_ID = "xctl_service_channel"
        const val CHANNEL_NAME = "xCtl Service"
        private const val NOTIFICATION_ID = 1001
        const val MAX_LOG_ENTRIES = 500

        private val commandQueue = ConcurrentLinkedQueue<CommandTask>()
        private var isProcessing = false
        private var lastCommandResult = "xCtl running"

        fun enqueueCommand(context: Context, sender: String, message: String) {
            commandQueue.add(CommandTask(sender, message))
            val intent = Intent(context, CommandService::class.java).apply {
                action = "PROCESS_QUEUE"
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun getLastCommandResult(): String = lastCommandResult
    }

    private lateinit var whitelistManager: WhitelistManager
    private lateinit var commandExecutor: CommandExecutor
    private lateinit var logManager: LogManager
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        whitelistManager = WhitelistManager(this)
        commandExecutor = CommandExecutor(this)
        logManager = LogManager(this)
        notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        val notification = buildNotification("xCtl running")
        startForeground(NOTIFICATION_ID, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "EXECUTE_COMMAND" -> {
                val sender = intent.getStringExtra("sender")
                val message = intent.getStringExtra("message")
                if (sender != null && message != null) {
                    commandQueue.add(CommandTask(sender, message))
                }
                processQueue()
            }
            "PROCESS_QUEUE" -> {
                processQueue()
            }
            "RECORD_AUDIO" -> {
                val filePath = intent.getStringExtra("file_path")
                val duration = intent.getIntExtra("duration", 10)
                if (filePath != null) {
                    Thread {
                        try {
                            val recorder = android.media.MediaRecorder().apply {
                                setAudioSource(android.media.MediaRecorder.AudioSource.MIC)
                                setOutputFormat(android.media.MediaRecorder.OutputFormat.THREE_GPP)
                                setAudioEncoder(android.media.MediaRecorder.AudioEncoder.AMR_NB)
                                setOutputFile(filePath)
                                prepare()
                                start()
                            }
                            Thread.sleep(duration * 1000L)
                            recorder.stop()
                            recorder.release()
                            Log.d("CommandService", "Audio recorded to $filePath")
                        } catch (e: Exception) {
                            Log.e("CommandService", "Audio recording failed", e)
                        }
                    }.start()
                }
            }
            "RECORD_VIDEO" -> {
                val filePath = intent.getStringExtra("file_path")
                if (filePath != null) {
                    val captureIntent = android.content.Intent(android.provider.MediaStore.ACTION_VIDEO_CAPTURE)
                    captureIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    captureIntent.addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    val fileUri = androidx.core.content.FileProvider.getUriForFile(
                        this, "${packageName}.fileprovider", java.io.File(filePath))
                    captureIntent.putExtra(android.provider.MediaStore.EXTRA_OUTPUT, fileUri)
                    try {
                        startActivity(captureIntent)
                    } catch (e: Exception) {
                        Log.e("CommandService", "Video capture failed", e)
                    }
                }
            }
            "STOP" -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        return START_STICKY
    }

    private fun processQueue() {
        if (isProcessing) return
        isProcessing = true

        Thread {
            try {
                while (commandQueue.isNotEmpty()) {
                    val task = commandQueue.poll() ?: break
                    executeTask(task)
                }
            } catch (e: Exception) {
                Log.e("CommandService", "Queue processing error", e)
            } finally {
                isProcessing = false
            }
        }.start()
    }

    private fun executeTask(task: CommandTask) {
        val parsed = CommandParser.parse(task.message)
        if (parsed == null) {
            sendResponse(task.sender, "Invalid command format. Use: xctl COMMAND [params]")
            return
        }

        val result = commandExecutor.execute(parsed)
        lastCommandResult = "Last: ${parsed.type} - $result"

        val isSuccess = !result.startsWith("Error") && !result.contains("not found") && !result.contains("Usage:")
        logManager.addLog(parsed.type, task.sender, result, isSuccess)

        sendResponse(task.sender, result)
        updateNotification(lastCommandResult)
    }

    private fun sendResponse(recipient: String, message: String) {
        try {
            val smsManager = SmsManager.getDefault()
            if (message.length > 160) {
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(recipient, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(recipient, null, message, null, null)
            }
            Log.d("CommandService", "Response sent to $recipient: ${message.take(80)}")
        } catch (e: Exception) {
            Log.e("CommandService", "Failed to send SMS response", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "xCtl background service notification"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("xCtl")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(text: String) {
        val notification = buildNotification(text)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

class LogManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("xctl_logs", Context.MODE_PRIVATE)

    fun addLog(command: String, sender: String, result: String, success: Boolean) {
        val logs = getLogs().toMutableList()
        val entry = "$command|$sender|$result|$success|${System.currentTimeMillis()}"
        logs.add(0, entry)
        if (logs.size > CommandService.MAX_LOG_ENTRIES) {
            logs.removeAt(logs.size - 1)
        }
        val jsonLogs = logs.joinToString("|||")
        prefs.edit().putString("logs", jsonLogs).apply()
    }

    fun getLogs(): List<String> {
        val raw = prefs.getString("logs", "") ?: ""
        if (raw.isEmpty()) return emptyList()
        return raw.split("|||").filter { it.isNotEmpty() }
    }

    fun clearLogs() {
        prefs.edit().remove("logs").apply()
    }

    fun getRecent(limit: Int = 20): List<Map<String, Any>> {
        return getLogs().take(limit).map { entry ->
            val parts = entry.split("|", limit = 5)
            mapOf(
                "command" to (parts.getOrElse(0) { "" }),
                "sender" to (parts.getOrElse(1) { "" }),
                "result" to (parts.getOrElse(2) { "" }),
                "success" to (parts.getOrElse(3) { "false" }),
                "timestamp" to (parts.getOrElse(4) { "0" })
            )
        }
    }
}
