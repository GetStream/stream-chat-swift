//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatUser {
    static let birthLandFieldName = "birthland"

    var birthLand: String {
        guard let v = extraData[ChatUser.birthLandFieldName] else {
            return ""
        }
        guard case let .string(birthLand) = v else {
            return ""
        }
        return birthLand
    }
}
