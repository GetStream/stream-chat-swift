//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct AIImageAttachmentView: View {
    var attachment: AIMessageAttachment
    var size: CGFloat

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
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
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(attachment.displayName)
        .accessibilityAddTraits(.isImage)
    }
}
