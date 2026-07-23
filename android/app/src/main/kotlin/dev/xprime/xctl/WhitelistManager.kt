package dev.xprime.xctl

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class WhitelistManager(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("xctl_whitelist", Context.MODE_PRIVATE)

    fun isAuthorized(number: String): Boolean {
        val normalized = normalizeNumber(number)
        val stored = prefs.getStringSet("whitelist", emptySet()) ?: emptySet()
        val result = stored.any { normalizeNumber(it) == normalized }
        Log.d("WhitelistManager", "Checking $normalized (normalized from $number): $result")
        return result
    }

    fun getAll(): List<String> {
        return (prefs.getStringSet("whitelist", emptySet()) ?: emptySet()).toList()
    }

    fun add(number: String): Boolean {
        val normalized = normalizeNumber(number)
        val set = (prefs.getStringSet("whitelist", emptySet()) ?: emptySet()).toMutableSet()
        val added = set.add(normalized)
        if (added) {
            prefs.edit().putStringSet("whitelist", set).apply()
            Log.d("WhitelistManager", "Added $normalized to whitelist")
        }
        return added
    }

    fun remove(number: String): Boolean {
        val normalized = normalizeNumber(number)
        val set = (prefs.getStringSet("whitelist", emptySet()) ?: emptySet()).toMutableSet()
        val removed = set.remove(normalized)
        if (removed) {
            prefs.edit().putStringSet("whitelist", set).apply()
            Log.d("WhitelistManager", "Removed $normalized from whitelist")
        }
        return removed
    }

    fun clear() {
        prefs.edit().remove("whitelist").apply()
    }

    fun count(): Int {
        return (prefs.getStringSet("whitelist", emptySet()) ?: emptySet()).size
    }

    private fun normalizeNumber(number: String): String {
        return number.replace(Regex("[^\\d+]"), "")
            .let { if (it.startsWith("+")) it else if (it.startsWith("00")) " +${it.substring(2)}" else it }
    }
}
