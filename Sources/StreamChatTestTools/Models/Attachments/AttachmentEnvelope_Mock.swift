//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension ChatMessageAttachmentEnvelope {
    static let mockFile = Self(localFileURL: .quote)!
    static let mockImage = Self(localFileURL: .image)!
}

private extension URL {
    class ThisBundle {}

    static let image = Bundle(for: ThisBundle.self)
        .url(forResource: "yoda", withExtension: "jpg")!

    static let quote = Bundle(for: ThisBundle.self)
        .url(forResource: "yoda", withExtension: "txt")!
}
