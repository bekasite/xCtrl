import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'command_model.dart';
import 'whitelist_model.dart';

class AppState extends ChangeNotifier {
  static const _whitelistChannel = MethodChannel('dev.xprime.xctl/whitelist');
  static const _logsChannel = MethodChannel('dev.xprime.xctl/logs');
  static const _serviceChannel = MethodChannel('dev.xprime.xctl/service');
  static const _commandChannel = MethodChannel('dev.xprime.xctl/command');
  static const _permissionChannel = MethodChannel('dev.xprime.xctl/permissions');
  static const _settingsChannel = MethodChannel('dev.xprime.xctl/settings');

  List<WhitelistEntry> _whitelist = [];
  List<CommandLog> _logs = [];
  bool _loading = false;
  String _lastResult = 'xCtl running';
  bool _deviceAdminEnabled = false;
  int _whitelistCount = 0;
  Map<String, String> _deviceInfo = {};
  String _tgToken = '';
  String _tgChatId = '';
  bool _tgEnabled = false;
  String _tgLinkedInfo = '';
  List<String> _favorites = ['LOCATION', 'STATUS', 'CAMERA', 'LOCK'];

  List<WhitelistEntry> get whitelist => _whitelist;
  List<CommandLog> get logs => _logs;
  bool get loading => _loading;
  String get lastResult => _lastResult;
  bool get deviceAdminEnabled => _deviceAdminEnabled;
  int get whitelistCount => _whitelistCount;
  Map<String, String> get deviceInfo => _deviceInfo;
  String get tgToken => _tgToken;
  String get tgChatId => _tgChatId;
  bool get tgEnabled => _tgEnabled;
  String get tgLinkedInfo => _tgLinkedInfo;
  List<String> get favorites => _favorites;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('xctl_favorites') ?? ['LOCATION', 'STATUS', 'CAMERA', 'LOCK'];
    notifyListeners();
  }

  Future<void> saveFavorites(List<String> favs) async {
    _favorites = favs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('xctl_favorites', favs);
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([
      loadWhitelist(),
      loadLogs(),
      loadStatus(),
      loadDeviceInfo(),
      loadTelegramConfig(),
      loadFavorites(),
    ]);
  }

  Future<void> loadTelegramConfig() async {
    try {
      final cfg = await _settingsChannel.invokeMethod<Map>('getTelegramConfig');
      if (cfg != null) {
        _tgToken = cfg['token'] as String? ?? '';
        _tgChatId = cfg['chatId'] as String? ?? '';
        _tgEnabled = cfg['enabled'] as bool? ?? false;
        _tgLinkedInfo = cfg['linkedInfo'] as String? ?? '';
        notifyListeners();
      }
    } catch (e) { debugPrint('loadTelegramConfig error: $e'); }
  }

  Future<void> saveTelegramConfig(
      {required String token, required String chatId, required bool enabled}) async {
    try {
      await _settingsChannel.invokeMethod('setTelegramConfig', {
        'token': token, 'chatId': chatId, 'enabled': enabled,
      });
      _tgToken = token;
      _tgChatId = chatId;
      _tgEnabled = enabled;
      notifyListeners();
    } catch (e) { debugPrint('saveTelegramConfig error: $e'); }
  }

  Future<String> testTelegram() async {
    try {
      final result = await _settingsChannel.invokeMethod<String>('testTelegram');
      return result ?? 'no_result';
    } catch (e) { return 'Error: $e'; }
  }

  Future<String> linkWithCode(String code) async {
    try {
      final result = await _settingsChannel.invokeMethod<String>('linkWithCode', {
        'code': code,
        'serverUrl': AppConstants.telegramBotServerUrl,
      });
      if (result != null && result.contains('|')) {
        await loadTelegramConfig();
      }
      return result ?? 'no_result';
    } catch (e) { return 'Error: $e'; }
  }

  Future<void> loadWhitelist() async {
    try {
      final list = await _whitelistChannel.invokeMethod<List>('getWhitelist');
      if (list != null) {
        _whitelist = list
            .map((e) => WhitelistEntry.fromNumber(e.toString()))
            .toList();
        _whitelistCount = _whitelist.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadWhitelist error: $e');
    }
  }

  Future<bool> addToWhitelist(String number) async {
    try {
      final result =
          await _whitelistChannel.invokeMethod<bool>('addWhitelist', {
        'number': number,
      });
      if (result == true) {
        await loadWhitelist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('addToWhitelist error: $e');
      return false;
    }
  }

  Future<bool> removeFromWhitelist(String number) async {
    try {
      final result =
          await _whitelistChannel.invokeMethod<bool>('removeWhitelist', {
        'number': number,
      });
      if (result == true) {
        await loadWhitelist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('removeFromWhitelist error: $e');
      return false;
    }
  }

  Future<void> clearWhitelist() async {
    try {
      await _whitelistChannel.invokeMethod('clearWhitelist');
      _whitelist.clear();
      _whitelistCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('clearWhitelist error: $e');
    }
  }

  Future<void> loadLogs() async {
    try {
      final list = await _logsChannel.invokeMethod<List>('getLogs', {
        'limit': 100,
      });
      if (list != null) {
        _logs = list
            .map((e) => CommandLog.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (_logs.isNotEmpty) {
          _lastResult =
              '${_logs.first.command}: ${_logs.first.result.split('\n').first}';
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadLogs error: $e');
    }
  }

  Future<void> clearLogs() async {
    try {
      await _logsChannel.invokeMethod('clearLogs');
      _logs.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('clearLogs error: $e');
    }
  }

  Future<void> loadStatus() async {
    try {
      final status =
          await _serviceChannel.invokeMethod<Map>('getStatus');
      if (status != null) {
        _deviceAdminEnabled = status['adminEnabled'] as bool? ?? false;
        _lastResult = status['lastResult'] as String? ?? _lastResult;
        _whitelistCount = status['whitelistCount'] as int? ?? _whitelistCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadStatus error: $e');
    }
  }

  Future<void> loadDeviceInfo() async {
    try {
      final info =
          await _settingsChannel.invokeMethod<Map>('getDeviceInfo');
      if (info != null) {
        _deviceInfo = info.map((k, v) => MapEntry(k.toString(), v.toString()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadDeviceInfo error: $e');
    }
  }

  Future<String> executeCommand(String command) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _commandChannel
          .invokeMethod<String>('execute', {'command': command});
      _lastResult = result ?? 'No result';
      await loadLogs();
      return _lastResult;
    } catch (e) {
      _lastResult = 'Error: ${e.toString()}';
      return _lastResult;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> requestDeviceAdmin() async {
    try {
      await _permissionChannel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      debugPrint('requestDeviceAdmin error: $e');
    }
  }

  Future<bool> isDeviceAdmin() async {
    try {
      final result =
          await _permissionChannel.invokeMethod<bool>('isDeviceAdmin');
      _deviceAdminEnabled = result ?? false;
      notifyListeners();
      return _deviceAdminEnabled;
    } catch (e) {
      debugPrint('isDeviceAdmin error: $e');
      return false;
    }
  }

  Future<void> requestWriteSettings() async {
    try {
      await _permissionChannel.invokeMethod('requestWriteSettings');
    } catch (e) {
      debugPrint('requestWriteSettings error: $e');
    }
  }
}
