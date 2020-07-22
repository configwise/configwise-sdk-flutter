import 'package:cwflutter/domain/component_entity.dart';
import 'package:flutter/material.dart';

import 'package:cwflutter/widget/ar_scene_view.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ArPage extends StatefulWidget {

  final ComponentEntity component;

  const ArPage({Key key, this.component}) : super(key: key);

  @override
  _ArPageState createState() => _ArPageState();
}

class _ArPageState extends State<ArPage> {

  ArController arController;

  bool _isShowHelpMessagesAllowed = true;

  @override
  void dispose() {
    arController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('AR in Flutter'),
      ),
      body: Container(
        child: ArSceneView(onViewCreated: onViewCreated),
      ));

  void onViewCreated(ArController arController) {
    this.arController = arController;
    this.arController?.onError = _onError;
    this.arController?.onArSessionInterrupted = _onArSessionInterrupted;
    this.arController?.onArSessionInterruptionEnded = _onArSessionInterruptionEnded;
    this.arController?.onArSessionStarted = _onArSessionStarted;
    this.arController?.onArSessionPaused = _onArSessionPaused;
    this.arController?.onArShowHelpMessage = _onArShowHelpMessage;
    this.arController?.onArHideHelpMessage = _onArHideHelpMessage;
    this.arController?.onArModelAdded = _onArModelAdded;
    this.arController?.onModelDeleted = _onModelDeleted;
    this.arController?.onModelSelected = _onModelSelected;
    this.arController?.onSelectionReset = _onSelectionReset;
    this.arController?.onArPlaneDetected = _onArPlaneDetected;
  }

  Future<void> _showCriticalErrorDialog(String message) async {
    _isShowHelpMessagesAllowed = false;
    Fluttertoast.cancel();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ERROR'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                Fluttertoast.cancel();
                _isShowHelpMessagesAllowed = true;
              },
            ),
          ],
        );
      },
    );
  }

  void _showHelpMessage(String message) {
    if (_isShowHelpMessagesAllowed) {
      const Color helpMessageBackgroundColor = const Color.fromRGBO(
          0xf4, 0xf0, 0xe8, 0.6);
      const Color helpMessageTextColor = const Color.fromRGBO(
          0x00, 0x00, 0x00, 1.0);

      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: helpMessageBackgroundColor,
          textColor: helpMessageTextColor,
          fontSize: 16.0
      );
    }
  }

  void _onError(bool isCritical, String message) {
    if (isCritical) {
      _showCriticalErrorDialog(message);
      return;
    }

    _showHelpMessage('ERROR: $message');
  }

  void _hideHelpMessage() {
    if (!_isShowHelpMessagesAllowed) {
      Fluttertoast.cancel();
    }
  }

  void _onArSessionInterrupted(String message) {
    _showHelpMessage(message);
  }

  void _onArSessionInterruptionEnded(String message) {
    _showHelpMessage(message);
  }

  void _onArSessionStarted(bool restarted) {
    print('[DEBUG] _onArSessionStarted: restarted: $restarted');
  }

  void _onArSessionPaused() {
    print('[DEBUG] _onArSessionPaused');
  }

  void _onArShowHelpMessage(String message) {
    _showHelpMessage(message);
  }

  void _onArHideHelpMessage() {
    _hideHelpMessage();
  }

  void _onArModelAdded(String modelId, String componentId) {
    print('[DEBUG] _onArModelAdded: modelId: $modelId, componentId: $componentId');
  }

  void _onModelDeleted(String modelId, String componentId) {
    print('[DEBUG] _onModelDeleted: modelId: $modelId, componentId: $componentId');
  }

  void _onModelSelected(String modelId, String componentId) {
    print('[DEBUG] _onModelSelected: modelId: $modelId, componentId: $componentId');
  }

  void _onSelectionReset() {
    print('[DEBUG] _onSelectionReset');
  }

  void _onArPlaneDetected(Vector3 worldPosition) {
    arController?.addModel(widget.component, worldPosition)
      .then((_) {
      })
      .catchError((e) {
        _onError(false, '$e');
      });
  }

}