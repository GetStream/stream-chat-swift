//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension JSONEncoder {
    func encodedString<T: Encodable>(_ encodable: T) -> String {
        if #available(iOS 13, *) {
            let encodedData = try! encode(encodable)
            return String(data: encodedData, encoding: .utf8)!.trimmingCharacters(in: .init(charactersIn: "\""))
            
        } else {
            @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
            // Workaround for a bug https://bugs.swift.org/browse/SR-6163 fixed in iOS 13
            let data = try! encode(["key": encodable])
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            return json["key"] as! String
        }
    }
}
