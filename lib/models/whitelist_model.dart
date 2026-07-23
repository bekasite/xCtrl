class WhitelistEntry {
  final String number;
  final String label;

  WhitelistEntry({
    required this.number,
    this.label = '',
  });

  String get displayName => label.isNotEmpty ? '$label ($number)' : number;

  String get normalizedNumber {
    return number.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'label': label,
      };

  factory WhitelistEntry.fromNumber(String number) {
    return WhitelistEntry(number: number);
  }
}
