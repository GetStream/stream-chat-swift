//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AttachmentLocation {
    public let url: URL
    public let isTemporary: Bool

    init(url: URL, isTemporary: Bool) {
        self.url = url
        self.isTemporary = isTemporary
    }
}
