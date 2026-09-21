//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

// A photo or video selected in the composer's media picker.
struct SelectedMediaItem: Sendable {
    let url: URL
    let type: AttachmentType
}
