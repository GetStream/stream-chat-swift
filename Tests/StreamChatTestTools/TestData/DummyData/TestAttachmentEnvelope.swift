//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

struct TestAttachmentPayload: AttachmentPayload, Hashable {
    static let type = AttachmentType(rawValue: .unique)

    let name: String
    let number: Int
}

extension TestAttachmentPayload {
    static var unique: Self {
        .init(name: .unique, number: .random(in: 1...100))
    }
}
