//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatClientConfig.DeletedMessageVisibility: CustomStringConvertible {
    public var description: String {
        labelText
    }

    public var labelText: String {
        switch self {
        case .alwaysHidden:
            return "alwaysHidden"
        case .alwaysVisible:
            return "alwaysVisible"
        case .visibleForCurrentUser:
            return "visibleForCurrentUser"
        }
    }
}
