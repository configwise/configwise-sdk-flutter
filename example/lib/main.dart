import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cwflutter/cwflutter.dart';
import 'package:cwflutter/widget/ar_configuration.dart';
import 'package:cwflutter/domain/component_entity.dart';

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
  List<ComponentEntity> components = List<ComponentEntity>();

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

      components.add(ComponentEntity(
          "id",
          "genericName",
          "description",
          "productNumber",
          "productLink",
          true,
          "",
          12345,
          true
      ));
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
                children: ArConfiguration.values.map((configuration) => showSupport(configuration)).toList(),
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

              showConfigWiseSDKInfo(),

              Spacer(),
            ]
        ),
      ),
    );
  }
}

Widget showSupport(ArConfiguration configuration) {
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

Widget showConfigWiseSDKInfo() {
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

              showAuthorized(),
            ],
          );
        }

        return CircularProgressIndicator();
      }
  );
}

Widget showAuthorized() {
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
          return showComponentsList();
        }

        return CircularProgressIndicator();
      })
  );
}

Widget showComponentsList() {
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
            style: Theme.of(context).textTheme.subhead,
          ),
          subtitle: Text(
            component.genericName,
            style: Theme.of(context).textTheme.subtitle,
          ),
        ),
      ),
    );
  }
}
