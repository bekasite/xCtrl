package dev.xprime.xctl

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class XctlDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        Log.d("XctlDeviceAdmin", "Device admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Log.d("XctlDeviceAdmin", "Device admin disabled")
    }

    override fun onPasswordChanged(context: Context, intent: Intent) {
        Log.d("XctlDeviceAdmin", "Password changed")
    }

    override fun onPasswordFailed(context: Context, intent: Intent) {
        Log.d("XctlDeviceAdmin", "Password failed")
    }

    override fun onPasswordSucceeded(context: Context, intent: Intent) {
        Log.d("XctlDeviceAdmin", "Password succeeded")
    }
}
