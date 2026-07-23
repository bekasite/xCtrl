import 'package:flutter/services.dart';

class PermissionService {
  static const _permissionChannel =
      MethodChannel('dev.xprime.xctl/permissions');

  static Future<bool> isDeviceAdmin() async {
    try {
      final result =
          await _permissionChannel.invokeMethod<bool>('isDeviceAdmin');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestDeviceAdmin() async {
    try {
      await _permissionChannel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      // ignore
    }
  }

  static Future<void> requestWriteSettings() async {
    try {
      await _permissionChannel.invokeMethod('requestWriteSettings');
    } catch (e) {
      // ignore
    }
  }
}
