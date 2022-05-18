//
//  Serializers.swift
//  cwflutter
//
//  Created by Sergey Muravev on 21.07.2020.
//

import Foundation
import ARKit
import CWSDKData

func serializeArray(_ array: simd_float2) -> Array<Float> {
    return [array[0], array[1]]
}

func serializeArray(_ array: simd_float3) -> Array<Float> {
    return [array[0], array[1], array[2]]
}

func serializeArray(_ array: simd_float4) -> Array<Float> {
    return [array[0], array[1], array[2], array[3]]
}

func serializeVector(_ vector: SCNVector3) -> Array<Float> {
    return [vector.x, vector.y, vector.z]
}

func serializeMatrix(_ matrix: simd_float4x4) -> Array<Float> {
    return [matrix.columns.0, matrix.columns.1, matrix.columns.2, matrix.columns.3].flatMap { serializeArray($0) }
}

func serializeComponentEntity(_ entity: CWCatalogItemEntity) -> Dictionary<String, Any> {
    [
        "id": "\(entity.id)",
        "parent_id": "",
        "genericName": entity.name,
        "description": "",
        "productNumber": entity.ean ?? "",
        "productLink": entity.productUrl?.absoluteString ?? "",
        "isFloating": false,
        "thumbnailFileKey": entity.thumbnailUrl?.absoluteString ?? "",
        "totalSize": 0,
        "isVariance": false
    ] as [String: Any]
}

func serializeAppListItemEntity(_ entity: CWCatalogItemEntity) -> Dictionary<String, Any> {
    [
        "id": "\(entity.id)",
        "parent_id": "",
        "component_id": "\(entity.id)",
        "type": "MAIN_PRODUCT",
        "label": entity.name,
        "description": "",
        "imageFileKey": entity.thumbnailUrl?.absoluteString ?? "",
        "index": 0,
        "textColor": ""
    ] as [String: Any]
}
