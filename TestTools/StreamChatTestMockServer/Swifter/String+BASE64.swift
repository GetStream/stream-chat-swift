//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {
    public static func toBase64(_ data: [UInt8]) -> String {
        return Data(data).base64EncodedString()
    }
}
