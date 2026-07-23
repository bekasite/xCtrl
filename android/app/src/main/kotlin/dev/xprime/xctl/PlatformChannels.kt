package dev.xprime.xctl

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object PlatformChannels {
    private const val WHITELIST_CHANNEL = "dev.xprime.xctl/whitelist"
    private const val LOGS_CHANNEL = "dev.xprime.xctl/logs"
    private const val SERVICE_CHANNEL = "dev.xprime.xctl/service"
    private const val COMMAND_CHANNEL = "dev.xprime.xctl/command"
    private const val PERMISSION_CHANNEL = "dev.xprime.xctl/permissions"
    private const val SETTINGS_CHANNEL = "dev.xprime.xctl/settings"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        val whitelistManager = WhitelistManager(context)
        val logManager = LogManager(context)
        val deviceAdminManager = DeviceAdminManager(context)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHITELIST_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWhitelist" -> {
                        result.success(whitelistManager.getAll())
                    }
                    "addWhitelist" -> {
                        val number = call.argument<String>("number") ?: ""
                        val added = whitelistManager.add(number)
                        result.success(added)
                    }
                    "removeWhitelist" -> {
                        val number = call.argument<String>("number") ?: ""
                        val removed = whitelistManager.remove(number)
                        result.success(removed)
                    }
                    "isAuthorized" -> {
                        val number = call.argument<String>("number") ?: ""
                        result.success(whitelistManager.isAuthorized(number))
                    }
                    "whitelistCount" -> {
                        result.success(whitelistManager.count())
                    }
                    "clearWhitelist" -> {
                        whitelistManager.clear()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOGS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLogs" -> {
                        val limit = call.argument<Int>("limit") ?: 50
                        result.success(logManager.getRecent(limit))
                    }
                    "clearLogs" -> {
                        logManager.clearLogs()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isRunning" -> {
                        result.success(true)
                    }
                    "getStatus" -> {
                        result.success(mapOf(
                            "running" to true,
                            "lastResult" to CommandService.getLastCommandResult(),
                            "adminEnabled" to deviceAdminManager.isAdminActive(),
                            "whitelistCount" to whitelistManager.count()
                        ))
                    }
                    "startService" -> {
                        val intent = Intent(context, CommandService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(intent)
                        } else {
                            context.startService(intent)
                        }
                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(context, CommandService::class.java).apply {
                            action = "STOP"
                        }
                        context.startService(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMAND_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "execute" -> {
                        val command = call.argument<String>("command") ?: ""
                        val parsed = CommandParser.parse(command)
                        if (parsed != null) {
                            val executor = CommandExecutor(context)
                            val cmdResult = executor.execute(parsed)
                            logManager.addLog(parsed.type, "local", cmdResult, !cmdResult.startsWith("Error"))
                            result.success(cmdResult)
                        } else {
                            result.success("Invalid command format. Use: xctl COMMAND [params]")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestDeviceAdmin" -> {
                        val intent = deviceAdminManager.getAdminIntent()
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                        result.success(true)
                    }
                    "isDeviceAdmin" -> {
                        result.success(deviceAdminManager.isAdminActive())
                    }
                    "requestWriteSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS
                            val uri = android.net.Uri.parse("package:${context.packageName}")
                            context.startActivity(Intent(intent).apply {
                                data = uri
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> {
                        result.success(mapOf(
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "version" to Build.VERSION.RELEASE,
                            "sdk" to Build.VERSION.SDK_INT,
                            "board" to Build.BOARD,
                            "brand" to Build.BRAND,
                            "device" to Build.DEVICE
                        ))
                    }
                    "getTelegramConfig" -> {
                        TelegramUploader.loadConfig(context)
                        result.success(mapOf(
                            "token" to TelegramUploader.token,
                            "chatId" to TelegramUploader.chatId,
                            "enabled" to TelegramUploader.enabled,
                            "linkedInfo" to TelegramUploader.linkedInfo
                        ))
                    }
                    "setTelegramConfig" -> {
                        val t = call.argument<String>("token") ?: ""
                        val c = call.argument<String>("chatId") ?: ""
                        val e = call.argument<Boolean>("enabled") ?: false
                        TelegramUploader.saveConfig(context, t, c, e)
                        result.success(true)
                    }
                    "testTelegram" -> {
                        Thread {
                            TelegramUploader.loadConfig(context)
                            val res = TelegramUploader.testConnection()
                            Handler(Looper.getMainLooper()).post { result.success(res) }
                        }.start()
                    }
                    "linkWithCode" -> {
                        val code = call.argument<String>("code") ?: ""
                        val serverUrl = call.argument<String>("serverUrl") ?: ""
                        Thread {
                            val res = TelegramUploader.linkWithCode(context, code, serverUrl)
                            Handler(Looper.getMainLooper()).post { result.success(res) }
                        }.start()
                    }
                    "getTelegramLinkedInfo" -> {
                        TelegramUploader.loadConfig(context)
                        result.success(TelegramUploader.linkedInfo)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
