//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension AttachmentAction {
    /// Returns a new unique action
    static var unique: Self {
        .init(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )
    }
}
