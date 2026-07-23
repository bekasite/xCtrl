import '../constants.dart';

class SmsService {
  static bool isXctlCommand(String message) {
    return message.trim().toLowerCase().startsWith(AppConstants.commandPrefix);
  }

  static ParsedCommand? parseCommand(String message) {
    final trimmed = message.trim();
    if (!isXctlCommand(trimmed)) return null;

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final command = parts[1].toUpperCase();
    final args = parts.length > 2 ? parts.sublist(2) : <String>[];

    return ParsedCommand(
      type: command,
      arg: args.isNotEmpty ? args.first : null,
      args: args,
      raw: trimmed,
    );
  }

  static String formatCommand(String command, String? arg) {
    if (arg != null && arg.isNotEmpty) {
      return '${AppConstants.commandPrefix} $command $arg';
    }
    return '${AppConstants.commandPrefix} $command';
  }
}

class ParsedCommand {
  final String type;
  final String? arg;
  final List<String> args;
  final String raw;

  ParsedCommand({
    required this.type,
    this.arg,
    required this.args,
    required this.raw,
  });
}
