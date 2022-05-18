# cwflutter

## Compatibility

+ iOS: ConfigWise SDK flutter plugin is only supported by mobile devices:
  + with A9 or later processors.
  + iOS 14.5 and newer.
+ Android: Minimal Android 7.0 (API-24)
  + Installed Google AR Core: https://play.google.com/store/apps/details?id=com.google.ar.core
  + See full list of supported devices, here: https://developers.google.com/ar/devices

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

To use this plugin, add `cwflutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

Get the [COMPANY_AUTH_TOKEN Credentials](https://manage.configwise.io) for your AR project. For more details go to [https://docs.configwise.io/api/setup-authentication-token//](https://docs.configwise.io/api/setup-authentication-token/)

Import `package:cwflutter/cwflutter.dart`, and initiate `Cwflutter Plugin` with your credentials.

### Integration

```dart
    try {
      await Cwflutter.initialize(
        defaultTargetPlatform == TargetPlatform.iOS
          ? "YOUR_IOS_COMPANY_AUTH_TOKEN"
          : "YOUR_ANDROID_COMPANY_AUTH_TOKEN",
        1 * 60 * 60,       // 1 hr
        400 * 1024 * 1024, // 400 Mb - we recommend to set 400 Mb or more for androidLowMemoryThreshold
        true
      );
    } on PlatformException catch (e) {
      print('Failed to initialize ConfigWise SDK due error: ${error.message}');
    }

    try {
      await Cwflutter.signIn();
    } on PlatformException catch (e) {
      print('Unable to pass authorization due error: ${error.message}');
    }
```

**NOTICE:** See examples (how to initialize and pass authorization) in our example project - see `_initConfigWiseSdk()` function in the 
[example/lib/main.dart](example/lib/main.dart)  

## Usage

We highly recommend to use our example project (code) to get first experience.
See: [example/lib/main.dart](example/lib/main.dart)

### Depend on it

Follow the [installation instructions](https://pub.dev/packages/cwflutter/install) from Dart Packages site.

### Update Info.plist

The plugin use native view from ARKit, which is not yet supported by default. To make it work add the following code to `Info.plist`:
```xml
    <key>io.flutter.embedded_views_preview</key>
    <string>YES</string>
```
ARKit uses the device camera, so do not forget to provide the `NSCameraUsageDescription`. You may specify it in `Info.plist` like that:
```xml
    <key>NSCameraUsageDescription</key>
    <string>Describe why your app needs AR here.</string>
``` 
