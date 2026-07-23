package dev.xprime.xctl

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "android.provider.Telephony.SMS_RECEIVED") return

        val bundle = intent.extras ?: return
        val pdus = bundle.get("pdus") as? Array<*> ?: return

        val messages = pdus.mapNotNull { pdu ->
            val format = bundle.getString("format") ?: "3gpp"
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    SmsMessage.createFromPdu(pdu as ByteArray, format)
                } else {
                    SmsMessage.createFromPdu(pdu as ByteArray)
                }
            } catch (e: Exception) {
                Log.e("SmsReceiver", "Error parsing PDU", e)
                null
            }
        }

        if (messages.isEmpty()) return

        val fullMessage = messages.joinToString("") { it.messageBody ?: "" }
        val sender = messages.first().originatingAddress ?: return

        Log.d("SmsReceiver", "SMS from $sender: $fullMessage")

        if (!fullMessage.trimStart().startsWith("xctl", ignoreCase = true)) return

        val whitelistManager = WhitelistManager(context)
        if (!whitelistManager.isAuthorized(sender)) {
            Log.d("SmsReceiver", "Blocked unauthorized sender: $sender")
            return
        }

        try {
            abortBroadcast()
        } catch (_: SecurityException) {
            // Only default SMS app can abort broadcasts on Android 4.4+
        }

        CommandService.enqueueCommand(context, sender, fullMessage.trim())
    }
}
