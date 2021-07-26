//
//  CwflutterArView.swift
//  cwflutter
//
//  Created by Sergey Muravev on 21.07.2020.
//

import Foundation
import ARKit
import ConfigWiseSDK

class CwflutterArView: NSObject, FlutterPlatformView {
    
    let sceneView: ARSCNView
    
    let channel: FlutterMethodChannel
    
    private let arAdapter: ArAdapter
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "cwflutter_ar_\(viewId)", binaryMessenger: messenger)
        
        self.sceneView = ARSCNView(frame: frame)
        self.arAdapter = ArAdapter()
        
        super.init()
        
        self.channel.setMethodCallHandler(self.onMethodCalled)
        
        // Let's init ArAdapter
        self.arAdapter.managementDelegate = self
        self.arAdapter.sceneView = self.sceneView
        
        self.arAdapter.modelHighlightingMode = .glow
        self.arAdapter.gesturesEnabled = true
        self.arAdapter.movementEnabled = true
        self.arAdapter.rotationEnabled = true
        self.arAdapter.scalingEnabled = false
        self.arAdapter.snappingsEnabled = false
        self.arAdapter.overlappingOfModelsAllowed = true
    }
    
    func view() -> UIView { return self.sceneView }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
        
        switch call.method {
        case "init":
            self.arAdapter.runArSession(restartArExperience: true)
            result(nil)
            break
            
        case "dispose":
            self.onDispose(result)
            result(nil)
            break
            
        case "addModel":
            guard let arguments = arguments, let componentId = arguments["componentId"] as? String else {
                result(FlutterError(
                    code: BAD_REQUEST,
                    message: "'componentId' parameter must not be blank.",
                    details: nil
                ))
                return
            }
            
            var simdWorldPosition: simd_float3?
            if let worldPosition = arguments["worldPosition"] as? [Float] {
                simdWorldPosition = deserializeArray(worldPosition)
            }
            
            self.addModel(componentId: componentId, simdWorldPosition: simdWorldPosition) { error in
                if let error = error {
                    result(FlutterError(
                        code: INTERNAL_ERROR,
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }

                result(nil)
            }
            break
            
        case "resetSelection":
            self.arAdapter.resetSelection()
            result(nil)
            break
            
        case "removeSelectedModel":
            if let selectedModel = self.arAdapter.selectedModel {
                self.arAdapter.removeModelBy(id: selectedModel.id)
            }
            result(nil)
            break
            
        case "removeModel":
            guard let arguments = arguments, let modelId = arguments["modelId"] as? String else {
                result(FlutterError(
                    code: BAD_REQUEST,
                    message: "'modelId' parameter must not be blank.",
                    details: nil
                ))
                return
            }
            
            self.arAdapter.removeModelBy(id: modelId)
            result(nil)
            break
            
        case "setMeasurementShown":
            var showSizes = false
            if let arguments = arguments, let value = arguments["value"] as? Bool {
                showSizes = value
            }
            
            self.arAdapter.showSizes = showSizes
            result(self.arAdapter.showSizes)
            break
        
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func onDispose(_ result: FlutterResult) {
        self.arAdapter.pauseArSession()
        result(nil)
    }
}

// MARK: - AR

extension CwflutterArView: ArManagementDelegate {
    
    func onArShowHelpMessage(type: ArHelpMessageType?, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArShowHelpMessage", arguments: message)
        }
    }
    
    func onArHideHelpMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArHideHelpMessage", arguments: nil)
        }
    }
    
    func onAdapterError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onError",
                arguments: [
                    "isCritical": false,
                    "message": error.localizedDescription
                ]
            )
        }
    }
    
    func onAdapterErrorCritical(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onError",
                arguments: [
                    "isCritical": true,
                    "message": error.localizedDescription
                ]
            )
        }
    }
    
    func onArSessionStarted(restarted: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArSessionStarted", arguments: restarted)
        }
    }
    
    func onArSessionPaused() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArSessionPaused", arguments: nil)
        }
    }
    
    func onArUnsupported(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onError",
                arguments: [
                    "isCritical": true,
                    "message": message
                ]
            )
        }
    }
    
    func onArFirstPlaneDetected(simdWorldPosition: simd_float3) {
        let serializedSimdWorldPosition = serializeArray(simdWorldPosition)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArFirstPlaneDetected", arguments: serializedSimdWorldPosition)
        }
    }
    
    func onModelAdded(modelId: String, componentId: String, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.channel.invokeMethod(
                    "onError",
                    arguments: [
                        "isCritical": false,
                        "message": error.localizedDescription
                    ]
                )
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onArModelAdded",
                arguments: [
                    "modelId": modelId,
                    "componentId": componentId
                ]
            )
        }
    }
    
    func onModelPositionChanged(modelId: String, componentId: String, position: SCNVector3, rotation: SCNVector4) {
    }
    
    func onModelSelected(modelId: String, componentId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onModelSelected",
                arguments: [
                    "modelId": modelId,
                    "componentId": componentId
                ]
            )
        }
    }
    
    func onModelDeleted(modelId: String, componentId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onModelDeleted",
                arguments: [
                    "modelId": modelId,
                    "componentId": componentId
                ]
            )
        }
    }
    
    func onSelectionReset() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onSelectionReset", arguments: nil)
        }
    }
    
    func onAnchorModelModelSelected(modelId: String, anchorObjectId: String) {
    }
    
    func onAnchorModelModelDeselected(modelId: String, anchorObjectId: String) {
    }
}

// MARK: - Models

extension CwflutterArView {
    
    private func addModel(
        componentId: String,
        simdWorldPosition: simd_float3?,
        block: @escaping (Error?) -> Void
    ) {
        ComponentService.sharedInstance.obtainComponentById(id: componentId) { component, error in
            if let error = error {
                block(error)
                return
            }
            
            guard let component = component else {
                block("Unable to find component with such id.")
                return
            }
            
            ModelLoaderService.sharedInstance.loadModelBy(component: component, block: { model, error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.channel.invokeMethod(
                        "onModelLoadingProgress",
                        arguments: [
                            "componentId": componentId,
                            "progress": 100
                        ]
                    )
                }

                if let error = error {
                    block(error)
                    return
                }
                guard let model = model else {
                    block("Loaded model is nil")
                    return
                }
                
                self.arAdapter.addModel(modelNode: model, simdWorldPosition: simdWorldPosition, selectModel: true)
                block(nil)
            }, progressBlock: { status, completed in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.channel.invokeMethod(
                        "onModelLoadingProgress",
                        arguments: [
                            "componentId": componentId,
                            "progress": Int(completed * 100)
                        ]
                    )
                }
            })
        }
    }
}
