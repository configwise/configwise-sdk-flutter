import Flutter
import ARKit
import Combine
import CWSDKData
import CWSDKRender

class DI {
    private var _authRepository: CWAuthRepository?
    var authRepository: CWAuthRepository {
        if _authRepository == nil {
            _authRepository = CWAuthRepositoryImpl()
        }
        return _authRepository!
    }

    private var _downloadingRepository: CWDownloadingRepository?
    var downloadingRepository: CWDownloadingRepository {
        if _downloadingRepository == nil {
            _downloadingRepository = CWDownloadingRepositoryImpl()
        }
        return _downloadingRepository!
    }

    private var _catalogItemRepository: CWCatalogItemRepository?
    var catalogItemRepository: CWCatalogItemRepository {
        if _catalogItemRepository == nil {
            _catalogItemRepository = CWCatalogItemRepositoryImpl()
        }
        return _catalogItemRepository!
    }

    private var _arObjectRepository: CWArObjectRepository?
    var arObjectRepository: CWArObjectRepository {
        if _arObjectRepository == nil {
            _arObjectRepository = CWArObjectRepositoryImpl(downloadingRepository: di.downloadingRepository)
        }
        return _arObjectRepository!
    }
}

let di = DI()

public class SwiftCwflutterPlugin: NSObject, FlutterPlugin {
    
    private let channel: FlutterMethodChannel

    private var subscriptions = Set<AnyCancellable>()

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
        
        NotificationCenter.default.publisher(for: ConfigWiseSDK.unauthorizedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.channel.invokeMethod("onSignOut", arguments: "Unauthorized.")
            }
            .store(in: &self.subscriptions)
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
                let channelToken = arguments["channelToken"] as? String
            else {
                result(FlutterError(
                    code: "0",
                    message: "'channelToken' parameter must not be blank.",
                    details: nil
                ))
                return
            }

            ConfigWiseSDK.initialize([
                .channelToken(channelToken),
                .authMode(.b2c),
                .testMode(false)
            ])

            result(true)
        }

        else if call.method == "signIn" {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.signIn() { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            if let cwError = error as? CWError, case .invocationFailed(let reason) = cwError {
                                result(FlutterError(
                                    code: "\(reason.statusCode)",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            } else {
                                result(FlutterError(
                                    code: "0",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            }
                            return
                        }
                        result(true)
                    }
                }
            }
        }
        
        else if call.method == "obtainFile" {
            guard let arguments = call.arguments as? Dictionary<String, Any?>,
                let fileKey = arguments["file_key"] as? String
            else {
                result(FlutterError(
                    code: "0",
                    message: "'file_key' parameter must not be blank.",
                    details: nil
                ))
                return
            }

            guard !fileKey.isEmpty else {
                result(nil)
                return
            }

            guard let url = URL(string: fileKey) else {
                result(FlutterError(
                    code: "0",
                    message: "'file_key' value must be downloading URL.",
                    details: nil
                ))
                return
            }

            DispatchQueue.global(qos: .utility).async {
                di.downloadingRepository.externalDownload(url) { fileUrl, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            if let cwError = error as? CWError, case .invocationFailed(let reason) = cwError {
                                result(FlutterError(
                                    code: "\(reason.statusCode)",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            } else {
                                result(FlutterError(
                                    code: "0",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            }
                            return
                        }

                        result(fileUrl?.path ?? "")
                    }
                }
            }
        }
            
        else if call.method == "obtainAllComponents" {
            var offset: Int?
            var max: Int?
            if let arguments = call.arguments as? Dictionary<String, Any?> {
                offset = arguments["offset"] as? Int
                max = arguments["max"] as? Int
            }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.obtainAllComponents(offset: offset, max: max) { serializedComponents, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            if let cwError = error as? CWError, case .invocationFailed(let reason) = cwError {
                                result(FlutterError(
                                    code: "\(reason.statusCode)",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            } else {
                                result(FlutterError(
                                    code: "0",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            }
                            return
                        }
                        result(serializedComponents)
                    }
                }
            }
        }
            
        else if call.method == "obtainComponentById" {
            guard let arguments = call.arguments as? Dictionary<String, Any?>,
                let componentId = arguments["id"] as? String
            else {
                result(FlutterError(
                    code: "0",
                    message: "'id' parameter must not be blank.",
                    details: nil
                ))
                return
            }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.obtainComponentById(componentId) { serializedComponent, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            if let cwError = error as? CWError, case .invocationFailed(let reason) = cwError {
                                result(FlutterError(
                                    code: "\(reason.statusCode)",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            } else {
                                result(FlutterError(
                                    code: "0",
                                    message: error.localizedDescription,
                                    details: nil
                                ))
                            }
                            return
                        }
                        result(serializedComponent)
                    }
                }
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

            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.obtainAllAppListItems(parentId: parentId, offset: offset, max: max) { serializedAppListItems, error in
                    if let error = error {
                        result(FlutterError(
                            code: "0",
                            message: error.localizedDescription,
                            details: nil
                        ))
                        return
                    }
                    result(serializedAppListItems)
                }
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
        // .b2c mode
        di.authRepository.login(CWLoginQuery()) { entity, error in
            if let error = error {
                block(error)
                return
            }
            guard entity != nil else {
                block("Unauthorized.")
                return
            }
            block(nil)
        }
    }
    
    private func obtainAllComponents(
        offset: Int?,
        max: Int?,
        block: @escaping ([Dictionary<String, Any?>], Error?) -> Void
    ) {
        let query = CWCatalogItemQuery(max: max, offset: offset)
        di.catalogItemRepository.getCatalogItems(query) { entities, error in
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
        guard let id = Int(componentId) else {
            block(nil, nil)
            return
        }
        let query = CWCatalogItemQuery(id: id)
        di.catalogItemRepository.getCatalogItem(query) { entity, error in
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
        let query = CWCatalogItemQuery(max: max, offset: offset)
        di.catalogItemRepository.getCatalogItems(query) { entities, error in
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
    
    private func isAppListItemVisible(_ entity: CWCatalogItemEntity) -> Bool {
        return true
    }
}
