//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

// Media picked in the photos picker that is still being downloaded, written, or compressed.
struct PendingMediaItem {
    let id: UUID
    let type: AttachmentType
    var previewImage: UIImage?
    var progress: Double
    // The share of the progress bar taken by downloading the file from iCloud.
    var downloadShare: Double
    let itemProvider: NSItemProvider
    let order: Int
}
