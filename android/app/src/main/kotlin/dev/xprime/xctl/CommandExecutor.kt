package dev.xprime.xctl

import android.content.Context

class CommandExecutor(private val context: Context) {
    private val systemManager = SystemManager(context)
    private val deviceAdminManager = DeviceAdminManager(context)

    fun execute(command: ParsedCommand): String {
        return try {
            when (command.type) {
                "LOCK" -> deviceAdminManager.lock()
                "LOCATION" -> systemManager.getLocation()
                "STATUS" -> systemManager.getDeviceStatus()
                "WIPE" -> deviceAdminManager.wipe()
                "PASSWORD" -> deviceAdminManager.setPassword(command.arg ?: "1234")
                "CLEARPASSWORD" -> deviceAdminManager.clearPassword()
                "MESSAGE" -> systemManager.sendNotification(command.arg ?: "xctl alert")
                "NOTIFICATION" -> systemManager.sendNotification(command.arg ?: "xctl alert")
                "SCREENSHOT" -> systemManager.takeScreenshot()
                "FLASH" -> systemManager.setFlashlight(command.arg ?: "toggle")
                "REBOOT" -> systemManager.reboot()
                "SHUTDOWN" -> systemManager.shutdown()
                "MUTE" -> systemManager.mute()
                "CONTACTS" -> systemManager.getContacts()
                "CALLS" -> systemManager.getCallLog()
                "LISTAPPS" -> systemManager.listApps()
                "SMS" -> handleSms(command)
                "CALL" -> handleCall(command)
                "WIFI" -> systemManager.setWifi(command.arg ?: "toggle")
                "BLUETOOTH" -> systemManager.setBluetooth(command.arg ?: "toggle")
                "DATA" -> systemManager.setMobileData(command.arg ?: "toggle")
                "HOTSPOT" -> systemManager.setHotspot(command.arg ?: "toggle")
                "BRIGHTNESS" -> systemManager.setBrightness(command.arg ?: "128")
                "TIMEOUT" -> systemManager.setScreenTimeout(command.arg ?: "30")
                "SCREEN" -> {
                    if (command.arg == null) "Usage: xctl SCREEN [on/off]"
                    else systemManager.setScreenState(command.arg)
                }
                "VOLUME" -> {
                    if (command.arg == null) "Usage: xctl VOLUME <0-${getMaxVolume()}>"
                    else systemManager.setVolume(command.arg)
                }
                "AIRPLANE" -> systemManager.setAirplaneMode(command.arg ?: "toggle")
                "CAMERA" -> systemManager.takePhoto(command.arg ?: "back")
                "AUDIO" -> systemManager.recordAudio(command.arg ?: "10")
                "VIDEO" -> systemManager.recordVideo(command.arg ?: "10")
                "SMSREAD" -> systemManager.readSms(command.arg ?: "10")
                "SMSDELETE" -> systemManager.deleteSms(command.arg ?: "0")
                "FILES" -> systemManager.listFiles(command.arg ?: "/storage/emulated/0")
                "READ" -> systemManager.readFile(command.arg ?: "")
                "DELETE" -> systemManager.deleteFile(command.arg ?: "")
                "LAUNCH" -> systemManager.launchApp(command.arg ?: "")
                "STOP" -> systemManager.stopApp(command.arg ?: "")
                "UNINSTALL" -> systemManager.uninstallApp(command.arg ?: "")
                "INSTALL" -> systemManager.installApp(command.arg ?: "")
                "CLIPBOARD" -> systemManager.handleClipboard(
                    command.arg ?: "get",
                    command.args.getOrNull(1)
                )
                "SHELL" -> {
                    val cmd = command.args.joinToString(" ")
                    if (cmd.isBlank()) "Usage: xctl SHELL <command>"
                    else systemManager.execShell(cmd)
                }
                "RING" -> systemManager.setRingMode(command.arg ?: "normal")
                "STORAGE" -> systemManager.getStorage()
                "IP" -> systemManager.getNetworkIp()
                "SIM" -> systemManager.getSimInfo()
                "BATTERY" -> systemManager.getBatteryDetail()
                "DND" -> systemManager.setDnd(command.arg ?: "off")
                "RUNNING" -> systemManager.getRunningProcesses()
                else -> "Unknown: ${command.type}. Commands: ${getSupportedCommands()}"
            }
        } catch (e: Exception) {
            "Error executing ${command.type}: ${e.message}"
        }
    }

    private fun getMaxVolume(): Int {
        return try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            am.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
        } catch (e: Exception) { 15 }
    }

    private fun handleSms(cmd: ParsedCommand): String {
        val number = cmd.arg ?: return "Usage: xctl SMS +1234567890 message"
        val message = if (cmd.args.size > 1) {
            cmd.args.drop(1).joinToString(" ")
        } else {
            "Sent from xCtl"
        }
        return systemManager.sendSms(number, message)
    }

    private fun handleCall(cmd: ParsedCommand): String {
        val number = cmd.arg ?: return "Usage: xctl CALL +1234567890"
        return systemManager.makeCall(number)
    }

    private fun getSupportedCommands(): String {
        return "LOCK,LOCATION,STATUS,SMS,CALL,WIPE,PASSWORD,CLEARPASSWORD," +
            "MESSAGE,NOTIFICATION,WIFI,BLUETOOTH,DATA,HOTSPOT," +
            "BRIGHTNESS,TIMEOUT,SCREEN,VOLUME,MUTE,RING," +
            "AIRPLANE,REBOOT,SHUTDOWN,CAMERA,AUDIO,VIDEO," +
            "CONTACTS,CALLS,SMSREAD,SMSDELETE,FILES,READ,DELETE," +
            "LISTAPPS,LAUNCH,STOP,UNINSTALL,INSTALL,SCREENSHOT," +
            "CLIPBOARD,FLASH,SHELL,STORAGE,IP,SIM,BATTERY,DND,RUNNING"
    }
}
