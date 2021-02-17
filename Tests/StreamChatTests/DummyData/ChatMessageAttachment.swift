//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChatMessageAttachmentSeed {
    static func dummy(
        localURL: URL = .unique(),
        fileName: String = .unique,
        type: AttachmentType = .image
    ) -> Self {
        .init(
            localURL: localURL,
            fileName: fileName,
            type: type
        )
    }
}
