//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// One of a message's attachments: an image as a thumbnail, and any other kind as a file, with
/// its name, type and size, that opens when tapped.
///
/// A file on this device opens in a preview, and one on the web through the `openURL`
/// environment action, which the app can set to open it its own way.
public struct AIMessageAttachmentView: View {
    var attachment: AIMessageAttachment
    var imageSize: CGFloat

    /// - Parameters:
    ///   - attachment: What to show.
    ///   - imageSize: The width and height of an image.
    public init(attachment: AIMessageAttachment, imageSize: CGFloat = 180) {
        self.attachment = attachment
        self.imageSize = imageSize
    }

    public var body: some View {
        if attachment.kind == .image, attachment.image != nil || attachment.url != nil {
            AIImageAttachmentView(attachment: attachment, size: imageSize)
        } else {
            AIFileAttachmentView(attachment: attachment)
        }
    }
}
