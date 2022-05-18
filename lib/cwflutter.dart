import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cwflutter/domain/app_list_item_entity.dart';
import 'package:cwflutter/widget/ar_configuration.dart';
import 'package:flutter/services.dart';

import 'domain/component_entity.dart';

class Cwflutter {
  static const MethodChannel _channel = const MethodChannel('cwflutter');

  static AuthState authState = AuthState.unauthorized;

  Cwflutter._() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> checkConfiguration(ArConfiguration configuration) {
    return _channel.invokeMethod<bool>('checkConfiguration', {
      'configuration': configuration.index,
    });
  }

  static Future<bool> initialize(
      String authToken,
      int dbAccessPeriod,
      int androidLowMemoryThreshold,
      bool lightEstimateEnabled
  ) {
    if (defaultTargetPlatform == TargetPlatform.android) { // ConfigWiseSDK_1X
      return _channel.invokeMethod<bool>('initialize', {
        'companyAuthToken': authToken,
        'dbAccessPeriod': dbAccessPeriod,
        'androidLowMemoryThreshold': androidLowMemoryThreshold,
        'lightEstimateEnabled': lightEstimateEnabled
      });
    } else if (defaultTargetPlatform == TargetPlatform.iOS) { // ConfigWiseSDK_2X
      return _channel.invokeMethod<bool>('initialize', {
        'channelToken': authToken
      });
    } else {
      return Future.error("Unable to initialize ConfigWiseSDK due unsupported platform. iOS and Android platforms are supported only.");
    }
  }

  static Future<bool> signIn() async {
    authState = AuthState.inProgress;
    try {
      bool result = await _channel.invokeMethod<bool>('signIn');
      authState = result ? AuthState.authorised : AuthState.unauthorized;
      return Future.value(result);
    } on PlatformException catch (e) {
      authState = AuthState.unauthorized;
      return Future.error(e.message);
    }
  }

  static Future<String> obtainFile(String fileKey) async {
    return _channel.invokeMethod<String>('obtainFile', {
      'file_key': fileKey,
    }).then((value) {
      return value;
    });
  }

  static Future<List<ComponentEntity>> obtainAllComponents(int offset, int max) async {
    final invocationResult = await _channel.invokeMethod('obtainAllComponents', {
      'offset': offset,
      'max': max
    });
    if (invocationResult == null) {
      return [];
    }

    List<ComponentEntity> entities = List<ComponentEntity>();
    for (final it in invocationResult.toList()) {
      final json = Map<dynamic, dynamic>.from(it);
      entities.add(ComponentEntity.fromJson(json));
    }

    return entities;
  }

  static Future<ComponentEntity> obtainComponentById(String id) async {
    return _channel.invokeMethod<Map<dynamic, dynamic>>('obtainComponentById', {
      'id': id,
    }).then((value) {
      if (value == null) {
        return null;
      }

      return ComponentEntity.fromJson(value);
    });
  }

  static Future<List<AppListItemEntity>> obtainAllAppListItems(String parentId, int offset, int max) async {
    final invocationResult = await _channel.invokeMethod('obtainAllAppListItems', {
      'parent_id': parentId,
      'offset': offset,
      'max': max
    });
    if (invocationResult == null) {
      return [];
    }

    List<AppListItemEntity> entities = List<AppListItemEntity>();
    for (final it in invocationResult.toList()) {
      final json = Map<dynamic, dynamic>.from(it);
      entities.add(AppListItemEntity.fromJson(json));
    }

    return entities;
  }

  Future<void> _platformCallHandler(MethodCall call) {
    try {
      switch (call.method) {
        case 'onSignOut':
          authState = AuthState.unauthorized;
          break;
        default:
          print('[ERROR] Unknown method ${call.method}');
      }
    } catch (e) {
      print(e);
    }
    return Future.value();
  }
}

enum AuthState {
  unauthorized,
  inProgress,
  authorised,
}
