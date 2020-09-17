//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
}
