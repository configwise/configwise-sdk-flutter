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

## 1.0.7

* Flutter plugin updated to use latest versions of ConfigWise SDKs (Android SDK v1.2.10, iOS SDK v1.3.3).
iOS example migrated to Xcode 12. Flutter AppListItemEntity and ComponentEntity have been fixed to support 
new 'Secured Downloading' mechanism.

* Optional pagination parameters (offset, max) have been added in the obtainAllComponents() and in 
the obtainAllAppListItems() functions.
NOTICE: Use null values in these params to obtain all entities in the transaction (without pagination).

* 'Secured Downloading' and 'Usage of downloading cache' (to increase loading performance) features have been 
implemented in the ConfigWise Flutter plugin.

## 1.0.8

* Flutter plugin updated to use latest version of ConfigWise iOS SDKs (v1.3.4)

* Minimal deployment target has been set as iOS 12.0

## 1.0.9

* Flutter plugin updated to use latest version of ConfigWise iOS SDKs (v1.3.8)

* Improvements in floor detection.

* Memory leaks (in iOS ConfigWiseSDK) have been fixed.

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.12)

* `onArPlaneDetected` callback interface has been renamed to `onArFirstPlaneDetected`.

* Two redundant callback functions have been removed from interface (`onArSessionInterrupted`, `onArSessionInterruptionEnded`).

* Extra ConfigWiseSDK initialization options have been added:

    * `dbAccessPeriod` (sec, 0 by default) - set number of seconds here if you wish 
    to query locally cached data instead to request data from server DB.
    Eg: `1hr = 1 * 60 * 60 sec`.
    Set 0 to always request data from server DB.
    
    * `lightEstimateEnabled` (true by default) - If enabled then real environment lights detected by your camera will be 
    used to calculate visualisation settings in the AR scene.

* Pagination issues (to obtain entities) have been fixed.

## 1.0.10

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.13).

* Obfuscator, minificator and shrinker rules (specific for Google R8 obfuscator) have been fixed in 
the Android part to exclude obfuscating of code which uses Java reflection on runtime, such as:
`org.greenrobot.eventbus.Subscribe`, `androidx.lifecycle.Lifecycle`, `androidx.lifecycle.LifecycleObserver`.

* Now, you can skip usage of `--no-shrink` build parameter in your release builds.

* Flutter plugin updated to use latest version of ConfigWise iOS SDKs (v1.3.9).

* Small bugs have been fixed in iOS ConfigWiseSDK (specific for Product Link functionality).

## 1.0.11

* Pinch gestures (to resize 3D models in the AR scene) have been disabled.

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.13).

* Bug has been fixed (sometimes 3D model is locked and unable to move it in AR scene in Android app).

* `onModelLoadingProgress` callback interface has been attached to Android bridge.
NOTICE: Currently (on Android platform) this callback executed twise. 1'st time - when AR starts 
loading of 3D model (`progress` parameter is `0`). 2'nd time (`progress` parameter is `100`) it will 
be run after 3D mode loading completed). Further Android `onModelLoadingProgress` functionality will 
be implemented successfully (it will be executed multiple times instead of currently twice).
On iOS platform this callback executes multiple times (`progress` parameter gives values `0...100`).
Use this callback to show (hide) progress indicator of loading.

## 1.0.12

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.15).

* Localization of AR error messages have been implemented in Android ConfigWiseSDK (EN, NL languages).

* Small improvements in Android ConfigWiseSDK.


## 1.0.13

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.16).

* Low memory management has been implemented in Android ConfigWiseSDK. This throws critical error (onArCriticalError) 
if not enough RAM to continue AR session.

## 1.0.14

* Flutter plugin has been updated to use latest version of Android ConfigWiseSDK (v1.2.18).

* Android: Runtime crash `Fatal Exception: com.google.ar.core.exceptions.FatalException` has been handled and fixed.

* Android: We fixed memory-checker and critical error handling to guarantee thread-safe.

* Android: LOW_MEMORY_THRESHOLD parameter has been made as customizable parameter. You can set it 
in `Cwflutter.initialize()` invocation (see `androidLowMemoryThreshold` parameter).
NOTICE: this parameter must be set as amount of bytes. Default value is 400 Mb (400 * 1024 * 1024).

* Android: Potential memory leaks have been fixed in `ConfigWiseSDK`, `DownloadingService` classes.

## 1.0.15

* Usage of Apple TrueDepth API has been removed from ConfigWise Flutter plugin. 

* Flutter plugin updated to use latest version of ConfigWise iOS SDKs (v1.3.10).

* ASSIMP library has been removed from iOS ConfigWiseSDK (because not used anymore).

* Unused `SimpleReachability` has been removed from iOS ConfigWiseSDK.
  
* Introduced 'Zip capability' in iOS ConfigWiseSDK (now, we can load 3D models from zip files uploaded through CBO).
  
* Memory usage improvements in iOS ConfigWiseSDK.

## 1.0.16

* Flutter Plugin has been updated to use latest stable version of iOS ConfigWiseSDK (v1.4.1).

* Usage of latest version of Android ConfigWiseSDK (v1.3.0) has been added.

## 1.0.17

* Flutter Plugin has been updated to use latest stable version of iOS ConfigWiseSDK (v1.5.2).

* Usage of latest version of Android ConfigWiseSDK (v1.4.2) has been added.

* Hardening improvements.
