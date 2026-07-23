package dev.xprime.xctl

data class ParsedCommand(
    val type: String,
    val arg: String?,
    val args: List<String>,
    val raw: String
)

object CommandParser {
    fun parse(message: String): ParsedCommand? {
        val trimmed = message.trim()
        if (!trimmed.startsWith("xctl", ignoreCase = true)) return null

        val parts = trimmed.split(Regex("\\s+"))
        if (parts.size < 2) return null

        val command = parts[1].uppercase()
        val rest = if (parts.size > 2) parts.drop(2) else emptyList()

        return ParsedCommand(
            type = command,
            arg = rest.firstOrNull(),
            args = rest,
            raw = trimmed
        )
    }
}
