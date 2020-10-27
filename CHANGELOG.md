## 1.0.0

* Initial release of ConfigWise SDK Flutter plugin.

## 1.0.1

* Loading of 3D models is implemented. We automatically put loaded models to AR scene.
* Ability to rotate, move, scale shown 3D models (using gestures).

## 1.0.4

* ConfigWise Android SDK is integrated to ConfigWise SDK Flutter plugin.
So, both mobile platforms (iOS and Android) are supported by our plugin at this moment.

## 1.0.5

* Updated iOS bridge to use latest ConfigWiseSDK v1.3.1. Xcode 12 / Swift 5.3 compatibility.
* Implemented functionality to retrieve AppContent data from ConfigWise backend.

## 1.0.6

* Gradle (in Android part) has been updated up to latest versions.

* iOS and Android bridges extended to support 'remove model from AR scene' feature and to support 'reset selected model in AR scene'.
Flutter example app (AR sceen is extended to show 'add', 'confirm' and 'delete' buttons which required to manage multiple products in the AR scene).

* Couple of defects in Android bridge have been fixed (defects about AR native code invocation of Android SDK).
Few defects are fixed in deserializers (Vector3Converter, Vector4Converter).
Flutter example app (AR sceen is extended to provide 'add new product' in to AR scene).

* 'Show Measurement' feature is implemented in iOS bridge and in the Flutter example app. NOTICE: This feature doesn't work on Android devices, 
because Android ConfigWiseSDK doesn't support it yet (this feature is available in iOS SDK only).
