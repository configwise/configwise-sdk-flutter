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
        self.arAdapter.scalingEnabled = true
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

                // TODO [smuravev] Implement CwflutterArView.addModel(), here
                // result(nil)
                result(FlutterMethodNotImplemented)
            }
            break
        case "dispose":
            self.onDispose(result)
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func onDispose(_ result: FlutterResult) {
        self.sceneView.session.pause()
        result(nil)
    }
}

// MARK: - AR

extension CwflutterArView: ArManagementDelegate {
    
    func onArShowHelpMessage(type: ArHelpMessageType?, message: String) {
        channel.invokeMethod("onArShowHelpMessage", arguments: message)
    }
    
    func onArHideHelpMessage() {
        channel.invokeMethod("onArHideHelpMessage", arguments: nil)
    }
    
    func onArSessionError(error: Error, message: String) {
        channel.invokeMethod(
            "onError",
            arguments: [
                "isCritical": true,
                "message": !message.isEmpty ? message : error.localizedDescription
            ]
        )
    }
    
    func onArSessionInterrupted(message: String) {
        channel.invokeMethod("onArSessionInterrupted", arguments: message)
    }
    
    func onArSessionInterruptionEnded(message: String) {
        channel.invokeMethod("onArSessionInterruptionEnded", arguments: message)
    }
    
    func onArSessionStarted(restarted: Bool) {
        channel.invokeMethod("onArSessionStarted", arguments: restarted)
    }
    
    func onArSessionPaused() {
        channel.invokeMethod("onArSessionPaused", arguments: nil)
    }
    
    func onArUnsupported(message: String) {
        channel.invokeMethod(
            "onError",
            arguments: [
                "isCritical": true,
                "message": message
            ]
        )
    }
    
    func onArPlaneDetected(simdWorldPosition: simd_float3) {
        channel.invokeMethod("onArPlaneDetected", arguments: serializeArray(simdWorldPosition))
    }
    
    func onArModelAdded(modelId: String, componentId: String, error: Error?) {
        if let error = error {
            channel.invokeMethod(
                "onError",
                arguments: [
                    "isCritical": false,
                    "message": error.localizedDescription
                ]
            )
            return
        }
        
        channel.invokeMethod(
            "onArModelAdded",
            arguments: [
                "modelId": modelId,
                "componentId": componentId
            ]
        )
    }
    
    func onModelPositionChanged(modelId: String, componentId: String, position: SCNVector3, rotation: SCNVector4) {
    }
    
    func onModelSelected(modelId: String, componentId: String) {
        channel.invokeMethod(
            "onModelSelected",
            arguments: [
                "modelId": modelId,
                "componentId": componentId
            ]
        )
    }
    
    func onModelDeleted(modelId: String, componentId: String) {
        channel.invokeMethod(
            "onModelDeleted",
            arguments: [
                "modelId": modelId,
                "componentId": componentId
            ]
        )
    }
    
    func onSelectionReset() {
        channel.invokeMethod("onSelectionReset", arguments: nil)
    }
}

// MARK: - Models

extension CwflutterArView {
    
    private func addModel(
        componentId: String,
        simdWorldPosition: simd_float3?,
        block: @escaping (Error?) -> Void
    ) {
        // TODO [smuravev] Implement CwflutterArView.addModel(), here
        block(nil)
    }
}
