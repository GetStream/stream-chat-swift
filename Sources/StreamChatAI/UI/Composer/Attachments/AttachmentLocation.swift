//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A file attached to the next message.
public final class AttachmentLocation {
    public let url: URL
    /// Whether the composer created the file, and removes it when it's no longer needed.
    public let isTemporary: Bool

    public init(url: URL, isTemporary: Bool) {
        self.url = url
        self.isTemporary = isTemporary
    }
}
