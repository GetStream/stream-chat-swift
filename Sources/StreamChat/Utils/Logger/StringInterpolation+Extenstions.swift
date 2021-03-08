//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Data) {
        guard
            let object = try? JSONSerialization.jsonObject(with: value, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: .utf8)
        else {
            appendLiteral(String(describing: value))
            return
        }
        appendLiteral(prettyPrintedString)
    }
    
    mutating func appendInterpolation<T>(_ value: EventPayload<T>) {
        var description = "\n-----\(type(of: value))-----\n"
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let propertyName = child.label {
                description += "     \(propertyName): \(child.value)\n"
            }
        }
        appendLiteral(description)
    }
}
