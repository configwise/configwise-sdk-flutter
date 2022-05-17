//
//  CwflutterArView.swift
//  cwflutter
//
//  Created by Sergey Muravev on 21.07.2020.
//

import Foundation
import ARKit
import RealityKit
import CWSDKData
import CWSDKRender

class CwflutterArView: NSObject, FlutterPlatformView {
    
    private let channel: FlutterMethodChannel

    private let arDelegateQueue = DispatchQueue(label: "QueueArDelegate_\(UUID().uuidString)")
    
    private var arAdapter: CWArAdapter?

    private var selectedArObject: CWArObjectEntity?

    private var onArFirstPlaneDetected = false
    
    init(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        messenger: FlutterBinaryMessenger
    ) {
        self.channel = FlutterMethodChannel(name: "cwflutter_ar_\(viewId)", binaryMessenger: messenger)

        self.arAdapter = CWArAdapter(frame: .zero)
        
        super.init()
        
        self.channel.setMethodCallHandler(self.onMethodCalled)
        
        // Let's init ArAdapter
        if let arAdapter = self.arAdapter {
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
    }
    
    func view() -> UIView {
        return self.arAdapter?.arView ?? UIView(frame: .zero)
    }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>

        guard let arAdapter = self.arAdapter else {
            result(FlutterError(
                code: "0",
                message: "ArAdapter not initialized.",
                details: nil
            ))
            return
        }
        
        switch call.method {
        case "init":
            arAdapter.runArSession()
            result(nil)
            self.onArSessionStarted(restarted: true)
            break
            
        case "dispose":
            arAdapter.pauseArSession()
            result(nil)
            self.onArSessionPaused()
            self.arAdapter = nil
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
            guard let id = Int(componentId) else {
                result(FlutterError(
                    code: "0",
                    message: "'componentId' parameter must be numeric.",
                    details: nil
                ))
                return
            }
            
            var simdWorldPosition: simd_float3?
            if let worldPosition = arguments["worldPosition"] as? [Float] {
                simdWorldPosition = deserializeArray(worldPosition)
            }

            self.addModel(componentId: id) { error in
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
            arAdapter.deselectAllArObjects()
            result(nil)
            break
            
        case "removeSelectedModel":
            if let selectedArObject = self.selectedArObject {
                arAdapter.removeArObject(selectedArObject)
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

            if let arObject = arAdapter.arObjects.first(where: { $0.id == id }) {
                arAdapter.removeArObject(arObject)
            }
            result(nil)
            break
            
        case "setMeasurementShown":
            // TODO [smuravev] ConfigWiseSDK_2X doesn't support showSizes feature.
            //                 Maybe, we implement it later.
//            var showSizes = false
//            if let arguments = arguments, let value = arguments["value"] as? Bool {
//                showSizes = value
//            }
//            arAdapter.showSizes = showSizes
//            result(arAdapter.showSizes)

            result(false)
            break
        
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
}

extension CwflutterArView {

    private func onArSessionStarted(restarted: Bool) {
        // NOTE [smuravev] Do NOT place these two blocks under one DispatchQueue.main

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArSessionStarted", arguments: restarted)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.onArFirstPlaneDetected else { return }

            self.onArFirstPlaneDetected = true
            let serializedSimdWorldPosition = serializeArray(simd_float3.zero)
            self.channel.invokeMethod("onArFirstPlaneDetected", arguments: serializedSimdWorldPosition)
        }
    }

    private func onArSessionPaused() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel.invokeMethod("onArSessionPaused", arguments: nil)
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
        self.onArSessionPaused()
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        self.onArSessionStarted(restarted: false)
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        true
    }
}

// MARK: - ARCoachingOverlayViewDelegate

extension CwflutterArView: ARCoachingOverlayViewDelegate {

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        self.onArSessionStarted(restarted: true)
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
}

// MARK: - ArObjects

extension CwflutterArView {
    
    private func addModel(
        componentId: Int,
        block: @escaping (Error?) -> Void
    ) {
        let query = CWCatalogItemQuery(id: componentId)
        di.catalogItemRepository.getCatalogItem(query) { [weak self] entity, error in
            if let error = error {
                block(error)
                return
            }
            guard let entity = entity else {
                block("Unable to find catalog item with such id.")
                return
            }

            self?.startPlacement(catalogItem: entity)
            block(nil)
        }
    }

    private func startPlacement(catalogItem: CWCatalogItemEntity) {
        DispatchQueue.main.async { [weak self] in
            let arObject = di.arObjectRepository.createArObject(catalogItem: catalogItem)
            self?.startPlacement(arObject: arObject)
        }
    }

    private func startPlacement(arObject: CWArObjectEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let arAdapter = self?.arAdapter else { return }

            arAdapter.hudShown = true
            arAdapter.hudObject = arObject

            if case .notRequested = arObject.loadableContent {
                arObject.load()
            }
        }
    }

    private func finishPlacement() {
        DispatchQueue.main.async { [weak self] in
            guard let arAdapter = self?.arAdapter else { return }

            if let arObject = arAdapter.placeArObjectFromHud() {
                arAdapter.selectArObject(arObject)
            }
            arAdapter.hudShown = false
        }
    }
}
