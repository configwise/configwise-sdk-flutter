//
//  ComponentEntitySerializer.swift
//  Alamofire
//
//  Created by Sergey Muravev on 22.07.2020.
//

import Foundation
import ConfigWiseSDK

func serializeComponentEntity(_ entity: ComponentEntity) -> Dictionary<String, Any> {
    [
        "id": entity.objectId ?? "",
        "genericName": entity.genericName,
        "description": entity.desc,
        "productNumber": entity.productNumber,
        "productLink": entity.productLink,
        "isFloating": entity.isFloating,
        "thumbnailFileUrl": entity.thumbnailFileUrl?.absoluteString ?? "",
        "totalSize": entity.totalSize,
        "isVisible": entity.isVisible
    ] as [String: Any]
}
