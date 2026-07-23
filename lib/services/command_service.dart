import 'package:flutter/services.dart';
import '../models/command_model.dart';

class CommandService {
  static const _commandChannel = MethodChannel('dev.xprime.xctl/command');
  static const _serviceChannel = MethodChannel('dev.xprime.xctl/service');
  static const _logsChannel = MethodChannel('dev.xprime.xctl/logs');

  static Future<String> execute(String command) async {
    try {
      final result = await _commandChannel
          .invokeMethod<String>('execute', {'command': command});
      return result ?? 'No result returned';
    } on MissingPluginException {
      return 'Error: Native plugin not available';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final status =
          await _serviceChannel.invokeMethod<Map>('getStatus');
      if (status != null) {
        return Map<String, dynamic>.from(status);
      }
      return {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<bool> startService() async {
    try {
      await _serviceChannel.invokeMethod('startService');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stopService() async {
    try {
      await _serviceChannel.invokeMethod('stopService');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<CommandLog>> getLogs({int limit = 50}) async {
    try {
      final list = await _logsChannel.invokeMethod<List>('getLogs', {
        'limit': limit,
      });
      if (list != null) {
        return list
            .map((e) => CommandLog.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearLogs() async {
    try {
      await _logsChannel.invokeMethod('clearLogs');
    } catch (e) {
      // ignore
    }
  }
}
