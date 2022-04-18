//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension AttachmentId {
    /// Returns a new unique id
    static var unique: Self {
        .init(cid: .unique, messageId: .unique, index: .random(in: 1..<1000))
    }
}
