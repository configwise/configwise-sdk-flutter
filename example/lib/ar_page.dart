import 'package:cwflutter/cwflutter.dart';
import 'package:cwflutter/domain/component_entity.dart';
import 'package:flutter/material.dart';

import 'package:cwflutter/widget/ar_scene_view.dart';
import 'package:vector_math/vector_math_64.dart' as VectorMath64;
import 'package:fluttertoast/fluttertoast.dart';

class ArPage extends StatefulWidget {

  final ComponentEntity initialComponent;

  const ArPage({Key key, this.initialComponent}) : super(key: key);

  @override
  _ArPageState createState() => _ArPageState();
}

class _ArPageState extends State<ArPage> {

  ArController arController;

  bool _isShowHelpMessagesAllowed = true;

  int _modelLoadingProgress = 0;

  bool _firstArPlaneDetected = false;

  String _selectedModelId;

  String _selectedComponentId;

  bool _isAllowToAddOtherProducts = false;

  @override
  void initState() {
    super.initState();
    _initMyState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initMyState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  void dispose() {
    arController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_modelLoadingProgress <= 0 || _modelLoadingProgress >= 100
              ? 'AR in Flutter'
              : 'Loading: $_modelLoadingProgress%'),
        ),
        body: Container(
          child: ArSceneView(onViewCreated: onViewCreated),
        ),
        floatingActionButton: _showToolbar()
      );

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
    this.arController?.onModelLoadingProgress = _onModelLoadingProgress;
    this.arController?.onSelectionReset = _onSelectionReset;
    this.arController?.onArPlaneDetected = _onArPlaneDetected;
  }

  Widget _showToolbar() {
    if (_selectedModelId != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Spacer(),
          FloatingActionButton(
            onPressed: () {
              arController.resetSelection();
            },
            child: Icon(Icons.check),
            heroTag: null,
          ),
          Spacer(),
          FloatingActionButton(
            onPressed: () {
              arController.removeSelectedModel();

              // Here, you can see 2'nd way how to remove 3D models from AR scene.
              // An example of code to remove model from scene by id.
              // if (_selectedModelId != null) {
              //   arController.removeModel(_selectedModelId);
              // }
            },
            child: Icon(Icons.delete),
            heroTag: null,
          ),
        ],
      );
    } else {
      return FloatingActionButton(
        onPressed: !_isAllowToAddOtherProducts ? null : () {
          _showComponentsList(context);
        },
        child: Icon(Icons.add),
        heroTag: null,
        backgroundColor: _isAllowToAddOtherProducts ? Colors.blueAccent : Colors.grey,
        foregroundColor: _isAllowToAddOtherProducts ? Colors.white : Colors.black12,
      );
    }
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
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
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
    setState(() {
      _isAllowToAddOtherProducts = true;
    });
  }

  void _onModelDeleted(String modelId, String componentId) {
    print('[DEBUG] _onModelDeleted: modelId: $modelId, componentId: $componentId');
  }

  void _onModelSelected(String modelId, String componentId) {
    setState(() {
      _selectedModelId = modelId;
      _selectedComponentId = componentId;
    });
  }

  void _onModelLoadingProgress(String componentId, int progress) {
    setState(() {
      _modelLoadingProgress = progress;
    });
  }

  void _onSelectionReset() {
    setState(() {
      _selectedModelId = null;
      _selectedComponentId = null;
    });
  }

  void _onArPlaneDetected(VectorMath64.Vector3 worldPosition) {
    if (_firstArPlaneDetected) {
      return;
    }

    _firstArPlaneDetected = true;

    arController
        ?.addModel(widget.initialComponent, worldPosition: worldPosition)
        ?.catchError((e) => _onError(false, '$e'));
  }

  void _showComponentsList(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder<List<ComponentEntity>>(
            future: Cwflutter.obtainAllComponents(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'ERROR: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                );
              }

              if (snapshot.hasData) {
                final components = snapshot.data;

                return ConstrainedBox(
                  constraints: new BoxConstraints(
                    minHeight: 160.0,
                    maxHeight: 320.0,
                  ),
                  child: ListView(
                      shrinkWrap: true,
                      children: components.map((it) => ComponentCell(
                          component: it,
                          onTap: (component) {
                            Navigator.pop(context);
                            arController
                                ?.addModel(component)
                                ?.catchError((e) => _onError(false, '$e'));
                          },
                      )).toList()
                  ),
                );
              }

              return Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        }
    );
  }
}

typedef OnTapCallback = void Function(ComponentEntity component);

class ComponentCell extends StatelessWidget {
  const ComponentCell({Key key, this.component, this.onTap}) : super(key: key);
  final ComponentEntity component;
  final OnTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => onTap(component),
        child: ListTile(
          leading: Image.network(component.thumbnailFileUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(
            component.productNumber,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          subtitle: Text(
            component.genericName,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
      ),
    );
  }
}