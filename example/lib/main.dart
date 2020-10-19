import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cwflutter/cwflutter.dart';
import 'package:cwflutter/widget/ar_configuration.dart';
import 'package:cwflutter/domain/component_entity.dart';
import 'package:cwflutter/domain/app_list_item_entity.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'ar_page.dart';

void main() {
  // See: https://flutter.dev/docs/testing/errors
//  FlutterError.onError = (FlutterErrorDetails details) {
//    FlutterError.dumpErrorToConsole(details);
//    if (kReleaseMode) {
//      // exit(1);
//    }
//  };

  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initMyState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initMyState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Cwflutter.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
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
                children: ArConfiguration.values.map((configuration) => _showSupport(configuration)).toList(),
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

              _showConfigWiseSDKInfo(),

              Spacer(),
            ]
        ),
      ),
    );
  }

  Widget _showSupport(ArConfiguration configuration) {
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

  Widget _showConfigWiseSDKInfo() {
    return FutureBuilder<bool>(
        future: Cwflutter.initialize("YOUR_COMPANY_AUTH_TOKEN"),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'ERROR: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            );
          }

          if (snapshot.hasData) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("ConfigWise SDK initialized."),

                Text(""),

                _showAuthorized()
              ],
            );
          }

          return CircularProgressIndicator();
        }
    );
  }

  Widget _showAuthorized() {
    return Center(
        child: FutureBuilder<bool>(
            future: Cwflutter.signIn(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'ERROR: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                );
              }

              if (snapshot.hasData) {
                // return showComponentsList();
                return _showAppListItemsList(null);
              }

              return CircularProgressIndicator();
            })
    );
  }

  Widget _showAppListItemsList(AppListItemEntity parent) {
    return FutureBuilder<List<AppListItemEntity>>(
      future: Cwflutter.obtainAllAppListItems(parent?.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'ERROR: ${snapshot.error}',
            style: TextStyle(color: Colors.red),
          );
        }

        if (snapshot.hasData) {
          final appListItems = snapshot.data;

          return ConstrainedBox(
            constraints: new BoxConstraints(
              minHeight: 160.0,
              maxHeight: 320.0,
            ),
            child: ListView.builder (
              itemCount: appListItems.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final appListItem = appListItems[index];

                if (appListItem.type == 'MAIN_PRODUCT') {
                  return AppListItemCellProduct(appListItem: appListItem);
                } else if (appListItem.type == 'NAVIGATION_ITEM') {
                  return AppListItemCellCategory(appListItem: appListItem);
                } else if (appListItem.type == 'OVERLAY_IMAGE') {
                  return Image.network(appListItem.imageUrl,
                    height: 100,
                    fit: BoxFit.fitWidth,
                  );
                }

                return ListTile( title: null, subtitle: null);
              },
            ),
          );
        }

        return CircularProgressIndicator();
      },
    );
  }

  Widget _showComponentsList() {
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
                children: components.map((it) => ComponentCell(component: it)).toList()
            ),
          );
        }

        return CircularProgressIndicator();
      },
    );
  }
}

class ComponentCell extends StatelessWidget {
  const ComponentCell({Key key, this.component}) : super(key: key);
  final ComponentEntity component;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (c) => ArPage(component: component,))),
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

class AppListItemCellProduct extends StatelessWidget {
  const AppListItemCellProduct({Key key, this.appListItem}) : super(key: key);
  final AppListItemEntity appListItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Cwflutter.obtainComponentById(appListItem.component_id)
              .then((component) {
                Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (c) => ArPage(component: component))
                );
              })
              .catchError((error) {
                Fluttertoast.showToast(
                    msg: error,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 2
                );
              });
        },
        child: ListTile(
          leading: Image.network(appListItem.imageUrl,
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
  const AppListItemCellCategory({Key key, this.appListItem}) : super(key: key);
  final AppListItemEntity appListItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO [smuravev] Implement onTap functionality by Category selection
          //                 (browse selected category).
        },
        child: ListTile(
          leading: Image.network(appListItem.imageUrl,
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