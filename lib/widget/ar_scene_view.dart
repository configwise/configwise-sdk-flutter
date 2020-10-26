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

  /// This is called when a session is interrupted.
  /// A session will be interrupted and no longer able to track when
  /// it fails to receive required sensor data. This happens when video capture is interrupted,
  /// for example when the application is sent to the background or when there are
  /// multiple foreground applications (see AVCaptureSessionInterruptionReason).
  /// No additional frame updates will be delivered until the interruption has ended.
  void Function(String message) onArSessionInterrupted;

  /// This is called when a session interruption has ended.
  /// A session will continue running from the last known state once
  /// the interruption has ended. If the device has moved, anchors will be misaligned.
  void Function(String message) onArSessionInterruptionEnded;

  void Function(bool restarted) onArSessionStarted;

  void Function() onArSessionPaused;

  void Function(String message) onArShowHelpMessage;

  void Function() onArHideHelpMessage;

  void Function(String modelId, String componentId) onArModelAdded;

  void Function(String modelId, String componentId) onModelDeleted;

  void Function(String modelId, String componentId) onModelSelected;

  void Function(String componentId, int progress) onModelLoadingProgress;

  void Function() onSelectionReset;

  void Function(Vector3 worldPosition) onArPlaneDetected;

  void dispose() {
    _channel?.invokeMethod<void>('dispose');
  }

  Future<void> addModel(ComponentEntity component, Vector3 worldPosition) {
    final jsonWorldPosition = Vector3Converter().toJson(worldPosition);
    final Map<dynamic, dynamic> params = <String, dynamic>{
      'componentId': component.id,
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

  Future<void> _platformCallHandler(MethodCall call) {
    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            print("[ERROR] ${call.arguments}");
            onError(call.arguments['isCritical'], call.arguments['message']);
          }
          break;

        case 'onArSessionInterrupted':
          if (onArSessionInterrupted != null) {
            onArSessionInterrupted(call.arguments);
          }
          break;

        case 'onArSessionInterruptionEnded':
          if (onArSessionInterruptionEnded != null) {
            onArSessionInterruptionEnded(call.arguments);
          }
          break;

        case 'onArSessionStarted':
          if (onArSessionStarted != null) {
            onArSessionStarted(call.arguments);
          }
          break;

        case 'onArSessionPaused':
          if (onArSessionPaused != null) {
            onArSessionPaused();
          }
          break;

        case 'onArShowHelpMessage':
          if (onArShowHelpMessage != null) {
            onArShowHelpMessage(call.arguments);
          }
          break;

        case 'onArHideHelpMessage':
          if (onArHideHelpMessage != null) {
            onArHideHelpMessage();
          }
          break;

        case 'onArModelAdded':
          if (onArModelAdded != null) {
            onArModelAdded(call.arguments['modelId'], call.arguments['componentId']);
          }
          break;

        case 'onModelDeleted':
          if (onModelDeleted != null) {
            onModelDeleted(call.arguments['modelId'], call.arguments['componentId']);
          }
          break;

        case 'onModelSelected':
          if (onModelSelected != null) {
            onModelSelected(call.arguments['modelId'], call.arguments['componentId']);
          }
          break;

        case 'onModelLoadingProgress':
          if (onModelLoadingProgress != null) {
            onModelLoadingProgress(call.arguments['componentId'], call.arguments['progress']);
          }
          break;

        case 'onSelectionReset':
          if (onSelectionReset != null) {
            onSelectionReset();
          }
          break;

        case 'onArPlaneDetected':
          if (onArPlaneDetected != null) {
            onArPlaneDetected(
                const Vector3Converter().fromJson(call.arguments as List)
            );
          }
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