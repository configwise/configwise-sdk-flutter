import 'dart:collection';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cwflutter/cwflutter.dart';
import 'package:cwflutter/widget/ar_configuration.dart';
import 'package:cwflutter/domain/app_list_item_entity.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'ar_page.dart';

void main() {
  // See: https://flutter.dev/docs/testing/errors
  // FlutterError.onError = (FlutterErrorDetails details) {
  //   FlutterError.dumpErrorToConsole(details);
  //   if (kReleaseMode) {
  //     exit(1);
  //   }
  // };

  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _isConfigWiseSdkInitialized = false;
  Object _error;
  AppListItemEntity _currentCategory;
  List<AppListItemEntity> _currentAppContent = List();
  final Queue<AppListItemEntity> _goBackStack = Queue();

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

    _retrievePlatformVersion();
    _initConfigWiseSdk();
  }

  Future<void> _retrievePlatformVersion() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Cwflutter.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _initConfigWiseSdk() async {
    Cwflutter.initialize("YOUR_COMPANY_AUTH_TOKEN")
        .then((isInitialized) {
          if (!isInitialized) {
            return Future.value(false);
          }

          // Let's skip authorization step if we already authorized.
          if (Cwflutter.authState == AuthState.authorised) {
            return Future.value(true);
          }

          return Cwflutter.signIn();
        })
        .then((isInitialized) {
          setState(() {
            _isConfigWiseSdkInitialized = isInitialized;
            _error = null;
          });

          _retrieveAppContent(_currentCategory);
        })
        .catchError((error) {
          setState(() {
            _isConfigWiseSdkInitialized = false;
            _error = error;
          });
        });
  }

  Future<void> _retrieveAppContent(AppListItemEntity category) async {
    Cwflutter.obtainAllAppListItems(category?.id)
        .then((appListItems) {
          setState(() {
            _currentAppContent = appListItems;
          });
        })
        .catchError((error) {
          setState(() {
            _error = error;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConfigWise SDK Demo'),
      ),
      body: Container(
        margin: EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ArConfiguration.values.map((configuration) => _showSupportedArConfiguration(context, configuration)).toList(),
              ),

              Text(""),

              Row(
                  children: [
                    Text('Running on:'),
                    Spacer(),
                    Text(' $_platformVersion'),
                  ]
              ),

              Text(""),

              _showConfigWiseSdkInfo(context),

              Text(""),

              _showAppContent(context),

              Spacer(),
            ]
        ),
      ),
    );
  }

  Widget _showSupportedArConfiguration(BuildContext context, ArConfiguration configuration) {
    return Row(children: [
      Text('$configuration:'),
      Spacer(),
      FutureBuilder<bool>(
          future: Cwflutter.checkConfiguration(configuration),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text(' loading');
            }
            return Text(snapshot.data ? ' supported' : ' not supported');
          })
    ]);
  }

  Widget _showConfigWiseSdkInfo(BuildContext context) {
    if (_error != null) {
      return Text(
        'ERROR: ${_error}',
        style: TextStyle(color: Colors.red),
      );
    }

    if (!_isConfigWiseSdkInitialized) {
      return CircularProgressIndicator();
    }

    return Text("ConfigWise SDK initialized.");
  }

  Widget _showAppContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                iconSize: 36,
                color: _currentCategory == null ? Colors.grey : Colors.black,
                onPressed: () {
                  if (_currentCategory == null) { return; }
                  if (_goBackStack.isNotEmpty) {
                    final AppListItemEntity goBackCategory = _goBackStack.removeLast();
                    setState(() {
                      _currentCategory = goBackCategory;
                      _currentAppContent = List();
                    });
                    _retrieveAppContent(goBackCategory);
                  }
                },
              ),
              Spacer(),
              Text(
                  _currentCategory?.label ?? "App Content",
                style: Theme.of(context).textTheme.headline5,
              ),
              Spacer(),
            ]
        ),

        ConstrainedBox(
          constraints: new BoxConstraints(
            minHeight: 160.0,
            maxHeight: 320.0,
          ),
          child: ListView.builder(
            itemCount: _currentAppContent.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final appListItem = _currentAppContent[index];

              if (appListItem.type == 'MAIN_PRODUCT') {
                return AppListItemCellProduct(
                  appListItem: appListItem,
                  onTap: (appListItem) {
                    Cwflutter.obtainComponentById(appListItem.component_id)
                        .then((component) {
                          Navigator.of(context).push<void>(
                              MaterialPageRoute(builder: (c) => ArPage(initialComponent: component))
                          );
                        })
                        .catchError((error) {
                          Fluttertoast.showToast(
                              msg: 'ERROR: $error',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 2
                          );
                        });
                  },
                );
              } else if (appListItem.type == 'NAVIGATION_ITEM') {
                return AppListItemCellCategory(
                  appListItem: appListItem,
                  onTap: (appListItem) {
                    _goBackStack.addLast(_currentCategory);
                    setState(() {
                      _currentCategory = appListItem;
                      _currentAppContent = List();
                    });
                    _retrieveAppContent(appListItem);
                  }
                );
              } else if (appListItem.type == 'OVERLAY_IMAGE') {
                return Image.network(
                  appListItem.imageFileKey,
                  height: 100,
                  fit: BoxFit.fitWidth,
                );
              }

              return ListTile(title: null, subtitle: null);
            },
          ),
        )
      ],
    );
  }
}

typedef OnTapCallback = void Function(AppListItemEntity appListItem);

class AppListItemCellProduct extends StatelessWidget {
  const AppListItemCellProduct({Key key, this.appListItem, this.onTap}) : super(key: key);
  final AppListItemEntity appListItem;
  final OnTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          onTap(appListItem);
        },
        child: ListTile(
          leading: Image.network(appListItem.imageFileKey,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(
            appListItem.label,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          subtitle: Text(
            appListItem.description,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
      ),
    );
  }
}

class AppListItemCellCategory extends StatelessWidget {
  const AppListItemCellCategory({Key key, this.appListItem, this.onTap}) : super(key: key);
  final AppListItemEntity appListItem;
  final OnTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          onTap(appListItem);
        },
        child: ListTile(
          leading: Image.network(appListItem.imageFileKey,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          trailing: Icon(Icons.arrow_right),
          title: Text(
            appListItem.label,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          subtitle: null,
        ),
      ),
    );
  }
}