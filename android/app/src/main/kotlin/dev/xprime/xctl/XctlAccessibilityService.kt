package dev.xprime.xctl

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class XctlAccessibilityService : AccessibilityService() {

    companion object {
        var pendingAction: String? = null
        var toggleComplete: Boolean = false

        const val ACTION_TOGGLE_DATA = "toggle_mobile_data"
        const val ACTION_TOGGLE_BT = "toggle_bluetooth"

        fun isEnabled(): Boolean = pendingAction != null || toggleComplete

        fun requestToggleMobileData(context: android.content.Context, targetOn: Boolean) {
            toggleComplete = false
            pendingAction = ACTION_TOGGLE_DATA
            context.startService(Intent(context, XctlAccessibilityService::class.java).apply {
                action = ACTION_TOGGLE_DATA
                putExtra("target", targetOn)
            })
        }

        fun requestToggleBluetooth(context: android.content.Context, targetOn: Boolean) {
            toggleComplete = false
            pendingAction = ACTION_TOGGLE_BT
            context.startService(Intent(context, XctlAccessibilityService::class.java).apply {
                action = ACTION_TOGGLE_BT
                putExtra("target", targetOn)
            })
        }
    }

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 500
        }
        serviceInfo = info
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null && (intent.action == ACTION_TOGGLE_DATA || intent.action == ACTION_TOGGLE_BT)) {
            performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        }
        return START_NOT_STICKY
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val action = pendingAction ?: return

        android.os.Handler(mainLooper).postDelayed({
            pendingAction = null
            rootInActiveWindow?.let { root ->
                try {
                    val found = findAndClickTile(root, action)
                    if (found) toggleComplete = true
                } finally {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        root.recycle()
                    }
                }
            }
        }, 600)
    }

    override fun onInterrupt() {}

    private fun findAndClickTile(node: AccessibilityNodeInfo?, action: String): Boolean {
        if (node == null) return false

        val text = node.text?.toString()?.lowercase() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase() ?: ""
        val combined = "$text $desc"

        val matches = when (action) {
            ACTION_TOGGLE_DATA -> combined.contains("mobile") || combined.contains("data") ||
                    combined.contains("internet") || combined.contains("cellular")
            ACTION_TOGGLE_BT -> combined.contains("bluetooth") || combined.contains("bt")
            else -> false
        }

        if (matches) {
            if (node.isClickable) {
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return true
            }
            val parent = node.parent
            if (parent != null && parent.isClickable) {
                parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return true
            }
        }

        for (i in 0 until node.childCount) {
            if (findAndClickTile(node.getChild(i), action)) return true
        }
        return false
    }
}
