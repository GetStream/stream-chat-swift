//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// Location Attachment Composer Preview
extension LocationAttachmentPayload: AttachmentPreviewProvider {
    public static let preferredAxis: NSLayoutConstraint.Axis = .vertical

    public func previewView(components: Components) -> UIView {
        /// For simplicity, we are using the same view for the Composer preview,
        /// but a different one could be provided.
        let preview = LocationAttachmentSnapshotView()
        preview.coordinate = coordinate
        return preview
    }
}
