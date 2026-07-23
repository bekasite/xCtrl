class CommandLog {
  final String command;
  final String sender;
  final String result;
  final bool success;
  final DateTime timestamp;

  CommandLog({
    required this.command,
    required this.sender,
    required this.result,
    required this.success,
    required this.timestamp,
  });

  factory CommandLog.fromMap(Map<String, dynamic> map) {
    return CommandLog(
      command: map['command'] as String? ?? '',
      sender: map['sender'] as String? ?? '',
      result: map['result'] as String? ?? '',
      success: (map['success'] as String? ?? 'false').toString() == 'true',
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
