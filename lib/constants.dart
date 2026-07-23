import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'xCtl';
  static const String domain = 'x-prime.dev';
  static const String version = '1.0.0';
  static const String commandPrefix = 'xctl';
  static const String packageName = 'dev.xprime.xctl';
  static const String telegramBotServerUrl = 'https://xctl-bot.onrender.com';

  static const Color accentColor = Color(0xFF00B4E6);
  static const Color accentDark = Color(0xFF0088CC);
  static const Color lightBg = Color(0xFFF5F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E4);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B78);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFFF5252);

  static const Gradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F5F8), Color(0xFFEEEEF2), Color(0xFFF8F8FC)],
  );

  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00B4E6), Color(0xFF0088CC)],
  );

  static const List<String> allCommands = [
    'LOCK', 'LOCATION', 'STATUS', 'SMS', 'CALL', 'WIPE',
    'PASSWORD', 'CLEARPASSWORD', 'MESSAGE', 'WIFI', 'BLUETOOTH',
    'DATA', 'HOTSPOT', 'BRIGHTNESS', 'TIMEOUT', 'SCREEN',
    'VOLUME', 'MUTE', 'AIRPLANE', 'REBOOT', 'SHUTDOWN',
    'CAMERA', 'AUDIO', 'VIDEO', 'CONTACTS', 'CALLS',
    'SMSREAD', 'SMSDELETE', 'FILES', 'READ', 'DELETE',
    'LISTAPPS', 'LAUNCH', 'STOP', 'UNINSTALL', 'INSTALL',
    'SCREENSHOT', 'CLIPBOARD', 'NOTIFICATION', 'FLASH',
    'SHELL', 'RING', 'STORAGE', 'IP', 'SIM', 'BATTERY', 'DND', 'RUNNING',
  ];

  static const Map<String, String> commandDescriptions = {
    'LOCK': 'Lock device screen',
    'LOCATION': 'Get GPS location',
    'STATUS': 'Device status info',
    'SMS': 'Send SMS: xctl SMS +1234567890 message',
    'CALL': 'Make call: xctl CALL +1234567890',
    'WIPE': 'Factory reset (needs Device Admin)',
    'PASSWORD': 'Set lock password: xctl PASSWORD 1234',
    'CLEARPASSWORD': 'Remove device password',
    'MESSAGE': 'Show notification: xctl MESSAGE text',
    'WIFI': 'WiFi on/off/toggle',
    'BLUETOOTH': 'Bluetooth on/off/toggle',
    'DATA': 'Mobile data on/off/toggle',
    'HOTSPOT': 'Hotspot on/off/toggle',
    'BRIGHTNESS': 'Set brightness 0-255',
    'TIMEOUT': 'Set screen timeout seconds',
    'SCREEN': 'Screen on/off',
    'VOLUME': 'Set volume 0-15',
    'MUTE': 'Silence device',
    'AIRPLANE': 'Airplane mode on/off/toggle',
    'REBOOT': 'Reboot device',
    'SHUTDOWN': 'Shutdown device',
    'CAMERA': 'Take photo front/back',
    'AUDIO': 'Record audio: xctl AUDIO seconds',
    'VIDEO': 'Record video: xctl VIDEO seconds',
    'CONTACTS': 'List contacts',
    'CALLS': 'Recent call log',
    'SMSREAD': 'Read SMS: xctl SMSREAD count',
    'SMSDELETE': 'Delete SMS by index',
    'FILES': 'List files: xctl FILES /path',
    'READ': 'Read file: xctl READ /path/to/file',
    'DELETE': 'Delete file: xctl DELETE /path',
    'LISTAPPS': 'List installed apps',
    'LAUNCH': 'Launch app: xctl LAUNCH pkg.name',
    'STOP': 'Stop app: xctl STOP pkg.name',
    'UNINSTALL': 'Uninstall app: xctl UNINSTALL pkg',
    'INSTALL': 'Install from URL: xctl INSTALL url',
    'SCREENSHOT': 'Take screenshot',
    'CLIPBOARD': 'Clipboard get/set',
    'NOTIFICATION': 'Send notification',
    'FLASH': 'Flashlight on/off/toggle',
    'SHELL': 'Execute shell command',
    'RING': 'Ring mode normal/silent/vibrate',
    'STORAGE': 'Storage usage info',
    'IP': 'Network IP and WiFi info',
    'SIM': 'SIM and network operator info',
    'BATTERY': 'Battery health and details',
    'DND': 'Do Not Disturb on/off',
    'RUNNING': 'Running processes list',
  };

  static BoxDecoration cardBox({double radius = 16}) {
    return BoxDecoration(
      color: lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: lightBorder.withValues(alpha: 0.5)),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: lightSurface,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      iconTheme: const IconThemeData(color: accentColor),
      dividerColor: lightBorder.withValues(alpha: 0.5),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
