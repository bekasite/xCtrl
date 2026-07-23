package dev.xprime.xctl

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

class DeviceAdminManager(private val context: Context) {
    private val dpm: DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val componentName: ComponentName =
        ComponentName(context, XctlDeviceAdminReceiver::class.java)

    fun isAdminActive(): Boolean {
        return dpm.isAdminActive(componentName)
    }

    fun getAdminIntent(): Intent {
        return Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "xCtl requires Device Admin for lock and wipe commands"
            )
        }
    }

    fun lock(): String {
        return try {
            if (!isAdminActive()) return "Error: Device Admin not enabled"
            @Suppress("DEPRECATION")
            dpm.lockNow()
            "Device locked"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun wipe(): String {
        return try {
            if (!isAdminActive()) return "Error: Device Admin not enabled"
            @Suppress("DEPRECATION")
            dpm.wipeData(DevicePolicyManager.WIPE_EXTERNAL_STORAGE)
            "Wiping device..."
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun setPassword(password: String): String {
        return try {
            if (!isAdminActive()) return "Error: Device Admin not enabled"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                "Password change not available on Android 11+. Set via device Settings or use a device owner app."
            } else {
                @Suppress("DEPRECATION")
                val success = dpm.resetPassword(password, 0)
                if (success) {
                    @Suppress("DEPRECATION")
                    dpm.lockNow()
                    "Password set to: $password"
                } else {
                    "Failed to set password"
                }
            }
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun clearPassword(): String {
        return try {
            if (!isAdminActive()) return "Error: Device Admin not enabled"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                "Password clear not available on Android 11+. Clear via device Settings."
            } else {
                @Suppress("DEPRECATION")
                val success = dpm.resetPassword("", 0)
                if (success) {
                    "Password cleared"
                } else {
                    "Failed to clear password"
                }
            }
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }

    fun disableCamera(disable: Boolean): String {
        return try {
            if (!isAdminActive()) return "Error: Device Admin not enabled"
            dpm.setCameraDisabled(componentName, disable)
            if (disable) "Camera disabled" else "Camera enabled"
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }
}
