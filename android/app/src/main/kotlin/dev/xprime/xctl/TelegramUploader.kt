package dev.xprime.xctl

import android.content.Context
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONArray
import org.json.JSONObject

object TelegramUploader {
    private const val API_BASE = "https://api.telegram.org/bot"

    private const val DEFAULT_TOKEN = ""

    fun loadConfig(context: Context) {
        val prefs = context.getSharedPreferences("xctl_telegram", Context.MODE_PRIVATE)
        token = prefs.getString("token", DEFAULT_TOKEN) ?: DEFAULT_TOKEN
        chatId = prefs.getString("chatId", "") ?: ""
        enabled = prefs.getBoolean("enabled", false)
        linkedInfo = prefs.getString("linkedInfo", "") ?: ""
    }

    fun saveConfig(context: Context, t: String, c: String, e: Boolean, li: String = linkedInfo) {
        token = t; chatId = c; enabled = e; linkedInfo = li
        context.getSharedPreferences("xctl_telegram", Context.MODE_PRIVATE).edit().apply {
            putString("token", t); putString("chatId", c); putBoolean("enabled", e)
            putString("linkedInfo", li); apply()
        }
    }

    var token: String = ""
    var chatId: String = ""
    var enabled: Boolean = false
    var linkedInfo: String = ""

    fun upload(filePath: String): String {
        if (!enabled || token.isBlank()) return "disabled"
        if (chatId.isBlank()) return "no_chat_id"
        val file = File(filePath)
        if (!file.exists()) return "file_not_found"

        return try {
            val boundary = "xctlBouNdary_${System.currentTimeMillis()}"
            val url = URL("$API_BASE$token/sendPhoto")
            val conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", "xCtl/1.0")
            conn.requestMethod = "POST"
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            conn.connectTimeout = 15000
            conn.readTimeout = 15000

            val body = buildMultipartBody(file, boundary)
            conn.outputStream.use { it.write(body) }

            val code = conn.responseCode
            val response = readStream(if (code in 200..299) conn.inputStream else conn.errorStream)
            conn.disconnect()
            if (code != 200) return "http_$code"
            if (response.startsWith("read_err:")) return response

            val json = JSONObject(response)
            if (!json.optBoolean("ok", false)) return "api_error"

            val photoArray = json.optJSONObject("result")?.optJSONArray("photo")
                ?: return "OK_no_photo_id"
            val largest = photoArray.optJSONObject(photoArray.length() - 1) ?: return "OK_no_photo_data"
            val fileId = largest.optString("file_id", "") ?: ""
            if (fileId.isBlank()) return "OK_no_file_id"

            val fileUrl = resolveFileUrl(fileId)
            if (fileUrl.startsWith("http")) "OK:$fileUrl"
            else "OK_no_url" 
        } catch (e: Exception) {
            Log.e("TelegramUploader", "Upload failed", e)
            "err: ${e::class.simpleName ?: "?"}: ${e.message?.take(50) ?: "no_message"}"
        }
    }

    private fun resolveFileUrl(fileId: String): String {
        return try {
            val url = URL("$API_BASE$token/getFile?file_id=$fileId")
            val conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", "xCtl/1.0")
            conn.connectTimeout = 10000
            conn.readTimeout = 10000
            val code = conn.responseCode
            val body = readStream(if (code == 200) conn.inputStream else conn.errorStream)
            conn.disconnect()
            if (code != 200 || body.startsWith("read_err:")) return ""

            val json = JSONObject(body)
            if (!json.optBoolean("ok", false)) return ""
            val filePath = json.optJSONObject("result")?.optString("file_path", "") ?: ""
            if (filePath.isBlank()) return ""
            "https://api.telegram.org/file/bot$token/$filePath"
        } catch (e: Exception) {
            Log.e("TelegramUploader", "ResolveFileUrl failed", e)
            ""
        }
    }

    fun testConnection(): String {
        if (token.isBlank()) return "no_token"
        if (chatId.isBlank()) return "no_chat_id"
        return try {
            val url = URL("$API_BASE$token/sendMessage")
            val conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", "xCtl/1.0")
            conn.requestMethod = "POST"
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/json")
            conn.connectTimeout = 10000
            val json = """{"chat_id":"$chatId","text":"xCtl test - Telegram connected!"}"""
            conn.outputStream.use { it.write(json.toByteArray()) }
            val code = conn.responseCode
            conn.disconnect()
            if (code == 200) "OK" else "err_$code"
        } catch (e: Exception) { "err: ${e::class.simpleName ?: "?"}: ${e.message?.take(50) ?: "no_message"}" }
    }

    private fun readStream(stream: java.io.InputStream?): String {
        if (stream == null) return "read_err:null_stream"
        return try {
            stream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            "read_err:${e::class.simpleName ?: "?"}"
        }
    }

    fun linkWithCode(context: Context, code: String, serverUrl: String): String {
        loadConfig(context)
        return try {
            val url = URL("$serverUrl/api/link")
            val conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", "xCtl/1.0")
            conn.setRequestProperty("Content-Type", "application/json")
            conn.requestMethod = "POST"
            conn.doOutput = true
            conn.connectTimeout = 15000
            conn.readTimeout = 15000

            val jsonBody = """{"code":"$code"}"""
            conn.outputStream.use { os ->
                os.write(jsonBody.toByteArray())
            }

            val responseCode = conn.responseCode
            val body = readStream(if (responseCode in 200..299) conn.inputStream else conn.errorStream)
            conn.disconnect()
            if (body.startsWith("read_err:")) return body

            val json = JSONObject(body)
            if (!json.optBoolean("ok", false)) {
                return json.optString("error", "link_failed")
            }

            val chatId = json.optLong("chatId", 0)
            val linkedInfo = json.optString("linkedInfo", "")
            if (chatId == 0L) return "no_chat_id"

            this.linkedInfo = linkedInfo
            saveConfig(context, token, chatId.toString(), enabled, linkedInfo)
            "$chatId|$linkedInfo"
        } catch (e: Exception) {
            Log.e("TelegramUploader", "LinkWithCode failed", e)
            "err: ${e::class.simpleName ?: "?"}: ${e.message?.take(50) ?: "no_message"}"
        }
    }

    private fun buildMultipartBody(file: File, boundary: String): ByteArray {
        val lineEnd = "\r\n"
        val builder = StringBuilder()
        builder.append("--$boundary$lineEnd")
        builder.append("Content-Disposition: form-data; name=\"chat_id\"$lineEnd$lineEnd")
        builder.append("$chatId$lineEnd")
        builder.append("--$boundary$lineEnd")
        builder.append("Content-Disposition: form-data; name=\"photo\"; filename=\"${file.name}\"$lineEnd")
        builder.append("Content-Type: image/jpeg$lineEnd$lineEnd")
        val header = builder.toString().toByteArray()
        val fileBytes = file.readBytes()
        val footer = "$lineEnd--$boundary--$lineEnd".toByteArray()
        return header + fileBytes + footer
    }
}
