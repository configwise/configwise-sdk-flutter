import Flutter
import UIKit
import ARKit
import ConfigWiseSDK

public class SwiftCwflutterPlugin: NSObject, FlutterPlugin {
    
    static var channel: FlutterMethodChannel?
    
    static var registrar: FlutterPluginRegistrar? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "cwflutter", binaryMessenger: registrar.messenger())
        SwiftCwflutterPlugin.registrar = registrar
        
        registrar.addMethodCallDelegate(
            SwiftCwflutterPlugin(),
            channel: channel!
        )
        
        let arFactory = ArFactory(messenger: registrar.messenger())
        registrar.register(arFactory, withId: "cwflutter_ar")
    }
    
    public override init() {
        super.init()
        
        // Let's add observers
        initObservers()
    }
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPlatformVersion" {
            result("iOS " + UIDevice.current.systemVersion)
        }

        else if call.method == "checkConfiguration" {
            let res = self.checkConfiguration(call.arguments)
            result(res)
        }

        else if call.method == "initialize" {
            guard let arguments = call.arguments as? Dictionary<String, Any>,
                let companyAuthToken = arguments["companyAuthToken"] as? String
            else {
                result(FlutterError(
                    code: BAD_REQUEST,
                    message: "'companyAuthToken' parameter must not be blank.",
                    details: nil
                ))
                return
            }
            
            ConfigWiseSDK.initialize([
                .variant: SdkVariant.B2C,
                .companyAuthToken: companyAuthToken,
                .debugLogging: false,
                .debug3d: false
            ])
            result(true)
        }

        else if call.method == "signIn" {
            self.signIn() { error in
                if let error = error {
                    result(FlutterError(
                        code: UNAUTHORIZED,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                result(true)
            }
        }
            
        else if call.method == "obtainAllComponents" {
            self.obtainAllComponents() { serializedComponents, error in
                if let error = error {
                    result(FlutterError(
                        code: INTERNAL_ERROR,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                result(serializedComponents)
            }
        }
            
        else if call.method == "obtainComponentById" {
            guard let arguments = call.arguments as? Dictionary<String, Any?>,
                let componentId = arguments["id"] as? String
            else {
                result(FlutterError(
                    code: BAD_REQUEST,
                    message: "'id' parameter must not be blank.",
                    details: nil
                ))
                return
            }

            self.obtainComponentById(componentId) { serializedComponent, error in
                if let error = error {
                    result(FlutterError(
                        code: INTERNAL_ERROR,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                result(serializedComponent)
            }
        }
        
        else if call.method == "obtainAllAppListItems" {
            var parentId: String? = nil
            if let arguments = call.arguments as? Dictionary<String, Any?> {
                parentId = arguments["parent_id"] as? String
            }
            
            self.obtainAllAppListItems(parentId: parentId) { serializedAppListItems, error in
                if let error = error {
                    result(FlutterError(
                        code: INTERNAL_ERROR,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                result(serializedAppListItems)
            }
        }

        else {
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - ArFactory

class ArFactory: NSObject, FlutterPlatformViewFactory {
    
    let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let view = CwflutterArView(withFrame: frame, viewIdentifier: viewId, messenger: self.messenger)
        return view
    }
}

// MARK: - FlutterError codes (specific for our plugin)

let BAD_REQUEST = "400"
let UNAUTHORIZED = "401"
let FORBIDDEN = "403"
let NOT_FOUND = "404"
let INTERNAL_ERROR = "500"
let NOT_IMPLEMENTED = "501"

// MARK: - ConfigWiseSDK

extension SwiftCwflutterPlugin {
    
    private func checkConfiguration(_ arguments: Any?) -> Bool {
        guard let arguments = arguments as? Dictionary<String, Any>,
            let configurationType = arguments["configuration"] as? Int else {
            return false
        }

        switch configurationType {
        case 0:
            return ARWorldTrackingConfiguration.isSupported
        case 1:
            if #available(iOS 12.0, *) {
                return ARImageTrackingConfiguration.isSupported
            } else {
                return false
            }
        case 2:
            #if !DISABLE_TRUEDEPTH_API
            return ARFaceTrackingConfiguration.isSupported
            #else
            return false
            #endif
        case 3:
            if #available(iOS 13.0, *) {
                return ARBodyTrackingConfiguration.isSupported
            } else {
                return false
            }
        default:
            return false
        }
    }
    
    private func signIn(block: @escaping (Error?) -> Void) {
        AuthService.sharedInstance.currentCompany { company, error in
            if let error = error {
                block(error)
                return
            }
            if company != nil {
                block(nil)
                return
            }

            // Let's try to automatically sign-in in B2C mode
            AuthService.sharedInstance.signIn() { user, error in
                if let error = error {
                    block(error)
                    return
                }
                guard user != nil else {
                    block("Unauthorized - user not found.")
                    return
                }
                
                block(nil)
            }
        }
    }
    
    private func obtainAllComponents(
        block: @escaping ([Dictionary<String, Any?>], Error?) -> Void
    ) {
        ComponentService.sharedInstance.obtainAllComponentsByCurrentCatalog() { entities, error in
            if let error = error {
                block([], error)
                return
            }
            
            let serializedEntities = entities.filter { $0.isVisible }.map { serializeComponentEntity($0) }
            block(serializedEntities, nil)
        }
    }
    
    private func obtainComponentById(
        _ componentId: String,
        block: @escaping (Dictionary<String, Any?>?, Error?) -> Void
    ) {
        ComponentService.sharedInstance.obtainComponentById(id: componentId) { entity, error in
            if let error = error {
                block(nil, error)
                return
            }
            guard let entity = entity, entity.isVisible else {
                block(nil, nil)
                return
            }
            
            let serializedEntity = serializeComponentEntity(entity)
            block(serializedEntity, nil)
        }
    }
    
    private func obtainAllAppListItems(
        parentId: String?,
        block: @escaping ([Dictionary<String, Any?>], Error?) -> Void
    ) {
        var parent: AppListItemEntity?
        if let parentId = parentId {
            parent = AppListItemEntity()
            parent?.objectId = parentId
        }
        
        AppListItemService.sharedInstance.obtainAppListItemsByCurrentCatalog(parent: parent) { [weak self] entities, error in
            guard let self = self else {
                block([], nil)
                return
            }
            if let error = error {
                block([], error)
                return
            }
            
            let serializedEntities = entities
                .filter { self.isAppListItemVisible($0) }
                .map { serializeAppListItemEntity($0) }
            block(serializedEntities, nil)
        }
    }
    
    private func isAppListItemVisible(_ entity: AppListItemEntity) -> Bool {
        if !entity.enabled { return false }
        
        if entity.isOverlayImage {
            return entity.isImageExist()
                || !entity.label.isEmpty
                || !entity.desc.isEmpty
        }
        else if entity.isNavigationItem {
            return !entity.label.isEmpty || !entity.desc.isEmpty
        }
        else if entity.isMainProduct {
            guard let component = entity.component else {
                return false
            }
            return component.isVisible
        }
        return false
    }
}

// MARK: - Observers

extension SwiftCwflutterPlugin {
    
    private func initObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onUnsupportedAppVersion),
            name: ConfigWiseSDK.unsupportedAppVersionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onSignOut),
            name: ConfigWiseSDK.signOutNotification,
            object: nil
        )
    }
    
    @objc func onUnsupportedAppVersion(notification: NSNotification) {
        DispatchQueue.main.async {
            let message = "Unsupported ConfigWiseSDK version. Please update it."
            print("[ERROR] \(message)")
            if let channel = SwiftCwflutterPlugin.channel {
                channel.invokeMethod("onSignOut", arguments: message)
            }
        }
    }

    @objc func onSignOut(notification: NSNotification) {
        DispatchQueue.main.async {
            if let channel = SwiftCwflutterPlugin.channel {
                channel.invokeMethod("onSignOut", arguments: "Unauthorized.")
            }
        }
    }
}
