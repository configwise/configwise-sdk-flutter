//
//  CwflutterArView.swift
//  cwflutter
//
//  Created by Sergey Muravev on 21.07.2020.
//

import Foundation
import ARKit
import RealityKit
import CWSDKRender

class CwflutterArView: NSObject, FlutterPlatformView {
    
    let channel: FlutterMethodChannel

    private let arDelegateQueue = DispatchQueue(label: "QueueArDelegate_\(UUID().uuidString)")
    
    private let arAdapter: CWArAdapter

    private var selectedArObject: CWArObjectEntity?
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "cwflutter_ar_\(viewId)", binaryMessenger: messenger)

        self.arAdapter = CWArAdapter(frame: .zero)
        
        super.init()
        
        self.channel.setMethodCallHandler(self.onMethodCalled)
        
        // Let's init ArAdapter
        arAdapter.delegateQueue = self.arDelegateQueue
        arAdapter.arSessionDelegate = self
        arAdapter.arCoachingOverlayViewDelegate = self
        arAdapter.arObjectSelectionDelegate = self
        arAdapter.arObjectManagementDelegate = self

        arAdapter.coachingEnabled = true
        arAdapter.hudColor = .blue
        arAdapter.hudEnabled = true
        arAdapter.arObjectSelectionMode = .single
    }
    
    func view() -> UIView { return self.arAdapter.arView }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
        
        switch call.method {
        case "init":
            self.arAdapter.runArSession()
            result(nil)
            break
            
        case "dispose":
            self.arAdapter.pauseArSession()
            result(nil)
            break
            
        case "addModel":
            guard let arguments = arguments, let componentId = arguments["componentId"] as? String else {
                result(FlutterError(
                    code: "0",
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
                        code: "0",
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }

                result(nil)
            }
            break
            
        case "resetSelection":
            self.arAdapter.deselectAllArObjects()
            result(nil)
            break
            
        case "removeSelectedModel":
            if let selectedArObject = self.selectedArObject {
                self.arAdapter.removeArObject(selectedArObject)
            }
            result(nil)
            break
            
        case "removeModel":
            guard let arguments = arguments, let modelId = arguments["modelId"] as? String else {
                result(FlutterError(
                    code: "0",
                    message: "'modelId' parameter must not be blank.",
                    details: nil
                ))
                return
            }
            guard let id = UInt64(modelId) else {
                result(FlutterError(
                    code: "0",
                    message: "'modelId' parameter must be numeric.",
                    details: nil
                ))
                return
            }

            if let arObject = self.arAdapter.arObjects.first(where: { $0.id == id }) {
                self.arAdapter.removeArObject(arObject)
            }
            result(nil)
            break
            
        case "setMeasurementShown":
            var showSizes = false
            if let arguments = arguments, let value = arguments["value"] as? Bool {
                showSizes = value
            }

            // TODO [smuravev] ConfigWiseSDK_2X doesn't support showSizes feature.
            //                 Maybe, we implement it later.
            // self.arAdapter.showSizes = showSizes
//            result(self.arAdapter.showSizes)
            result(false)
            break
        
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
}

// MARK: - CWArObjectSelectionDelegate

extension CwflutterArView: CWArObjectSelectionDelegate {

    func arObjectSelected(_ arObject: CWArObjectEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.selectedArObject = arObject
            self.channel.invokeMethod(
                "onModelSelected",
                arguments: [
                    "modelId": "\(arObject.id)",
                    "componentId": "\(arObject.catalogItem.id)"
                ]
            )
        }

        if let error = arObject.loadableContent.error {
            showArError("Unable to load product model due: \(error.localizedDescription)")
        }
    }

    func arObjectDeselected(_ arObject: CWArObjectEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.selectedArObject = nil
            self.channel.invokeMethod("onSelectionReset", arguments: nil)
        }
    }
}

// MARK: - CWArObjectManagementDelegate

extension CwflutterArView: CWArObjectManagementDelegate {

    func arObjectAdded(_ arObject: CWArObjectEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onArModelAdded",
                arguments: [
                    "modelId": "\(arObject.id)",
                    "componentId": "\(arObject.catalogItem.id)"
                ]
            )
        }
    }

    func arObjectRemoved(_ arObject: CWArObjectEntity) {
        if arObject == self.selectedArObject {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.selectedArObject = nil
                self.arObjectDeselected(arObject)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(
                "onModelDeleted",
                arguments: [
                    "modelId": "\(arObject.id)",
                    "componentId": "\(arObject.catalogItem.id)"
                ]
            )
        }
    }
}

// MARK: - ARSessionDelegate, ARSessionObserver

extension CwflutterArView: ARSessionDelegate {

    private func showArError(_ error: Error, isCritical: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod(
                "onError",
                arguments: [
                    "isCritical": isCritical,
                    "message": error.localizedDescription
                ]
            )
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        showArError(error, isCritical: true)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArSessionPaused", arguments: nil)
        }
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let restarted = false
            self.channel.invokeMethod("onArSessionStarted", arguments: restarted)
        }
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        true
    }
}

// MARK: - ARCoachingOverlayViewDelegate

extension CwflutterArView: ARCoachingOverlayViewDelegate {

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
}

// MARK: - AR

//extension CwflutterArView: ArManagementDelegate {
//
//
//
//    func onArFirstPlaneDetected(simdWorldPosition: simd_float3) {
//        let serializedSimdWorldPosition = serializeArray(simdWorldPosition)
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.channel.invokeMethod("onArFirstPlaneDetected", arguments: serializedSimdWorldPosition)
//        }
//    }
//}

// MARK: - ArObjects

extension CwflutterArView {
    
    private func addModel(
        componentId: String,
        simdWorldPosition: simd_float3?,
        block: @escaping (Error?) -> Void
    ) {
//        ComponentService.sharedInstance.obtainComponentById(id: componentId) { component, error in
//            if let error = error {
//                block(error)
//                return
//            }
//
//            guard let component = component else {
//                block("Unable to find component with such id.")
//                return
//            }
//
//            ModelLoaderService.sharedInstance.loadModelBy(component: component, block: { model, error in
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    self.channel.invokeMethod(
//                        "onModelLoadingProgress",
//                        arguments: [
//                            "componentId": componentId,
//                            "progress": 100
//                        ]
//                    )
//                }
//
//                if let error = error {
//                    block(error)
//                    return
//                }
//                guard let model = model else {
//                    block("Loaded model is nil")
//                    return
//                }
//
//                self.arAdapter.addModel(modelNode: model, simdWorldPosition: simdWorldPosition, selectModel: true)
//                block(nil)
//            }, progressBlock: { status, completed in
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    self.channel.invokeMethod(
//                        "onModelLoadingProgress",
//                        arguments: [
//                            "componentId": componentId,
//                            "progress": Int(completed * 100)
//                        ]
//                    )
//                }
//            })
//        }
    }
}
