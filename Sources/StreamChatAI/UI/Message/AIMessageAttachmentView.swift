//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// One of a message's attachments: an image as a thumbnail, and any other kind as a file, with
/// its name, type and size, that opens when tapped.
///
/// A file on this device opens in a preview, and one on the web through the `openURL`
/// environment action, which the app can set to open it its own way.
public struct AIMessageAttachmentView: View {
    var attachment: AIMessageAttachment
    var imageSize: CGFloat

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - attachment: What to show.
    ///   - imageSize: The width and height of an image.
    public init(attachment: AIMessageAttachment, imageSize: CGFloat = 180) {
        self.attachment = attachment
        self.imageSize = imageSize
    }

    public var body: some View {
        if attachment.kind == .image, attachment.image != nil || attachment.url != nil {
            Group {
                if let image = attachment.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    AsyncImage(url: attachment.url) { loaded in
                        loaded
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(colors.attachmentImagePlaceholder)
                    }
                }
            }
            .frame(width: imageSize, height: imageSize)
            .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl, style: .continuous))
            .accessibilityElement()
            .accessibilityLabel(attachment.displayName)
            .accessibilityAddTraits(.isImage)
        } else {
            AIFileAttachmentView(attachment: attachment)
        }
    }
}
