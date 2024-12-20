//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// Location Attachment Composer Preview
extension StaticLocationAttachmentPayload: AttachmentPreviewProvider {
    public static let preferredAxis: NSLayoutConstraint.Axis = .vertical

    public func previewView(components: Components) -> UIView {
        /// For simplicity, we are using the same view for the Composer preview,
        /// but a different one could be provided.
        let preview = LocationAttachmentSnapshotView()
        preview.content = .init(
            messageId: nil,
            latitude: latitude,
            longitude: longitude,
            isLive: false
        )
        return preview
    }
}
