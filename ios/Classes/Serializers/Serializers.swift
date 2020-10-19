//
//  Serializers.swift
//  cwflutter
//
//  Created by Sergey Muravev on 21.07.2020.
//

import Foundation
import ARKit
import ConfigWiseSDK

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

func serializeComponentEntity(_ entity: ComponentEntity) -> Dictionary<String, Any> {
    [
        "id": entity.objectId ?? "",
        "parent_id": entity.parent?.objectId ?? "",
        "genericName": entity.genericName,
        "description": entity.desc,
        "productNumber": entity.productNumber,
        "productLink": entity.productLink,
        "isFloating": entity.isFloating,
        "thumbnailFileUrl": entity.thumbnailFileUrl?.absoluteString ?? "",
        "totalSize": entity.totalSize,
        "isVariance": entity.parent != nil
    ] as [String: Any]
}

func serializeAppListItemEntity(_ entity: AppListItemEntity) -> Dictionary<String, Any> {
    [
        "id": entity.objectId ?? "",
        "parent_id": entity.parent?.objectId ?? "",
        "component_id": entity.component?.objectId ?? "",
        "type": entity.type.rawValue,
        "label": entity.label,
        "description": entity.desc,
        "imageUrl": entity.imageUrl?.absoluteString ?? "",
        "index": entity.index,
        "textColor": entity.textColor?.rgbaString ?? ""
    ] as [String: Any]
}
