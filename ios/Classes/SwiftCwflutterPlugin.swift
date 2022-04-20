import Flutter
import UIKit
import ARKit
import CWSDKData

public class SwiftCwflutterPlugin: NSObject, FlutterPlugin {
    
    private var channel: FlutterMethodChannel

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cwflutter", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(
            SwiftCwflutterPlugin(channel: channel),
            channel: channel
        )
        
        let arFactory = ArFactory(messenger: registrar.messenger())
        registrar.register(arFactory, withId: "cwflutter_ar")
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        
        super.init()
        
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

            var dbAccessPeriod: Int = 0
            var lightEstimateEnabled = true
            if let arguments = call.arguments as? Dictionary<String, Any?> {
                dbAccessPeriod = arguments["dbAccessPeriod"] as? Int ?? 0
                lightEstimateEnabled = arguments["lightEstimateEnabled"] as? Bool ?? true
            }
            
            ConfigWiseSDK.initialize([
                .variant: SdkVariant.B2C,
                .companyAuthToken: companyAuthToken,
                .dbAccessPeriod: dbAccessPeriod,
                .lightEstimateEnabled: lightEstimateEnabled,
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
        
        else if call.method == "obtainFile" {
            guard let arguments = call.arguments as? Dictionary<String, Any?>,
                let fileKey = arguments["file_key"] as? String
            else {
                result(FlutterError(
                    code: BAD_REQUEST,
                    message: "'file_key' parameter must not be blank.",
                    details: nil
                ))
                return
            }
            
            DownloadingService.sharedInstance.obtainFileFromLocalCache(fileKey: fileKey) { fileUrl, error in
                if let error = error {
                    result(FlutterError(
                        code: INTERNAL_ERROR,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                
                result(fileUrl?.path ?? "")
            }
        }
            
        else if call.method == "obtainAllComponents" {
            var offset: Int?
            var max: Int?
            if let arguments = call.arguments as? Dictionary<String, Any?> {
                offset = arguments["offset"] as? Int
                max = arguments["max"] as? Int
            }
            
            self.obtainAllComponents(offset: offset, max: max) { serializedComponents, error in
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
            var parentId: String?
            var offset: Int?
            var max: Int?
            if let arguments = call.arguments as? Dictionary<String, Any?> {
                parentId = arguments["parent_id"] as? String
                offset = arguments["offset"] as? Int
                max = arguments["max"] as? Int
            }
            
            self.obtainAllAppListItems(parentId: parentId, offset: offset, max: max) { serializedAppListItems, error in
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
        
        // TODO [smuravev] Here, we disable code related on Apple TrueDepth API (because currently not used).
        //                 Do not enable it until we really start using it (otherwise Apple rejects validation in AppStore):
        //                 Here is what Apple requests to solve:
        //                 --
        //                 We have started the review of your app, but we are not able to continue because we need additional information about how your app uses information collected by the TrueDepth API.
        //                 To help us proceed with the review of your app, please provide complete and detailed information to the following questions.
        //                 What information is your app collecting using the TrueDepth API?
        //                 For what purposes are you collecting this information? Please provide a complete and clear explanation of all planned uses of this data.
        //                 Will the data be shared with any third parties? Where will this information be stored?
        //                 --
        //
//        case 1:
//            if #available(iOS 12.0, *) {
//                return ARImageTrackingConfiguration.isSupported
//            } else {
//                return false
//            }
//        case 2:
//            #if !DISABLE_TRUEDEPTH_API
//            return ARFaceTrackingConfiguration.isSupported
//            #else
//            return false
//            #endif
//        case 3:
//            if #available(iOS 13.0, *) {
//                return ARBodyTrackingConfiguration.isSupported
//            } else {
//                return false
//            }
            
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
        offset: Int?,
        max: Int?,
        block: @escaping ([Dictionary<String, Any?>], Error?) -> Void
    ) {
        ComponentService.sharedInstance.obtainAllComponentsByCurrentCatalog(offset: offset, max: max) { entities, error in
            if let error = error {
                block([], error)
                return
            }
            
            let serializedEntities = entities.map { serializeComponentEntity($0) }
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
            guard let entity = entity else {
                block(nil, nil)
                return
            }
            
            let serializedEntity = serializeComponentEntity(entity)
            block(serializedEntity, nil)
        }
    }
    
    private func obtainAllAppListItems(
        parentId: String?,
        offset: Int?,
        max: Int?,
        block: @escaping ([Dictionary<String, Any?>], Error?) -> Void
    ) {
        var parent: AppListItemEntity?
        if let parentId = parentId {
            parent = AppListItemEntity()
            parent?.objectId = parentId
        }
        
        AppListItemService.sharedInstance.obtainAppListItemsByCurrentCatalog(parent: parent, offset: offset, max: max) { [weak self] entities, error in
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
        
        if entity.isMainProduct {
            guard let component = entity.component else {
                return false
            }
        }

        return true
    }
}

// MARK: - Observers

extension SwiftCwflutterPlugin {
    
    private func initObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onSignOut),
            name: ConfigWiseSDK.signOutNotification,
            object: nil
        )
    }

    @objc func onSignOut(notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onSignOut", arguments: "Unauthorized.")
        }
    }
}
