import 'package:cwflutter/domain/component_entity.dart';
import 'package:cwflutter/utils/json_converters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

/// A widget that wraps ARSCNView from ARKit.
class ArSceneView extends StatefulWidget {

  const ArSceneView({
    Key key,
    @required this.onViewCreated,
  }) : super(key: key);

  /// This function will be fired when ARKit view is created.
  final void Function(ArController controller) onViewCreated;

  @override
  _ArSceneViewState createState() => _ArSceneViewState();
}

class _ArSceneViewState extends State<ArSceneView> {

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'cwflutter_ar',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    else if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'cwflutter_ar',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Text('$defaultTargetPlatform is not supported by this plugin');
  }

  Future<void> onPlatformViewCreated(int id) async {
    if (widget.onViewCreated == null) {
      return;
    }

    widget.onViewCreated(ArController._init(id));
  }

}

/// Controls an [ArSceneView].
///
/// An [ArController] instance can be obtained by setting the [ArSceneView.onViewCreated]
/// callback for an [ArSceneView] widget.
class ArController {
  ArController._init(
      int id,
  ) {
    _channel = MethodChannel('cwflutter_ar_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
    _channel.invokeMethod<void>('init');
  }

  MethodChannel _channel;

  /// This is called when a session fails.
  /// On failure the session will be paused.
  void Function(bool isCritical, String message) onError;

  void Function(bool restarted) onArSessionStarted;

  void Function() onArSessionPaused;

  void Function(String message) onArShowHelpMessage;

  void Function() onArHideHelpMessage;

  void Function(String modelId, String componentId) onArModelAdded;

  void Function(String modelId, String componentId) onModelDeleted;

  void Function(String modelId, String componentId) onModelSelected;

  void Function(String componentId, int progress) onModelLoadingProgress;

  void Function() onSelectionReset;

  void Function(Vector3 worldPosition) onArFirstPlaneDetected;

  void dispose() {
    _channel?.invokeMethod<void>('dispose');
  }

  Future<bool> startArPlacement() {
    final params = <String, dynamic>{};
    return _channel.invokeMethod<bool>('startArPlacement', params);
  }

  Future<void> finishArPlacement() {
    final params = <String, dynamic>{};
    return _channel.invokeMethod<void>('finishArPlacement', params);
  }

  Future<void> addModel(String componentId, {Vector3 worldPosition}) {
    final jsonWorldPosition = Vector3Converter().toJson(worldPosition);
    final Map<dynamic, dynamic> params = <String, dynamic>{
      'componentId': componentId,
      'worldPosition': jsonWorldPosition
    };

    return _channel.invokeMethod<void>('addModel', params);
  }

  Future<void> removeModel(String modelId) {
    final Map<dynamic, dynamic> params = <String, dynamic>{
      'modelId': modelId
    };

    return _channel.invokeMethod<void>('removeModel', params);
  }

  Future<void> removeSelectedModel() {
    return _channel.invokeMethod<void>('removeSelectedModel');
  }

  Future<void> resetSelection() {
    return _channel.invokeMethod<void>('resetSelection');
  }

  Future<bool> setMeasurementShown(bool value) {
    final Map<dynamic, dynamic> params = <String, dynamic>{
      'value': value ?? false
    };
    return _channel.invokeMethod<bool>('setMeasurementShown', params);
  }

  Future<void> _platformCallHandler(MethodCall call) {
    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            print("[ERROR] ${call.arguments}");
            onError(call.arguments['isCritical'], call.arguments['message']);
          }
          break;

        case 'onArSessionStarted':
          onArSessionStarted?.call(call.arguments);
          break;

        case 'onArSessionPaused':
          onArSessionPaused?.call();
          break;

        case 'onArShowHelpMessage':
          onArShowHelpMessage?.call(call.arguments);
          break;

        case 'onArHideHelpMessage':
          onArHideHelpMessage?.call();
          break;

        case 'onArModelAdded':
          onArModelAdded?.call(call.arguments['modelId'], call.arguments['componentId']);
          break;

        case 'onModelDeleted':
          onModelDeleted?.call(call.arguments['modelId'], call.arguments['componentId']);
          break;

        case 'onModelSelected':
          onModelSelected?.call(call.arguments['modelId'], call.arguments['componentId']);
          break;

        case 'onModelLoadingProgress':
          onModelLoadingProgress?.call(call.arguments['componentId'], call.arguments['progress']);
          break;

        case 'onSelectionReset':
          onSelectionReset?.call();
          break;

        case 'onArFirstPlaneDetected':
          onArFirstPlaneDetected?.call(
              const Vector3Converter().fromJson(call.arguments as List)
          );
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