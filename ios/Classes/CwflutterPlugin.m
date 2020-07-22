#import "CwflutterPlugin.h"
#if __has_include(<cwflutter/cwflutter-Swift.h>)
#import <cwflutter/cwflutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cwflutter-Swift.h"
#endif

@implementation CwflutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwflutterPlugin registerWithRegistrar:registrar];
}
@end
