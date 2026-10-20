//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import QuickLook
import StreamCore
import SwiftUI
import UniformTypeIdentifiers

struct AIFileAttachmentView: View {
    var attachment: AIMessageAttachment

    @State private var preview: URL?
    @Environment(\.openURL) private var openURL

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        if let url = attachment.url {
            Button {
                if url.isFileURL {
                    preview = url
                } else {
                    openURL(url)
                }
            } label: {
                card
            }
            .buttonStyle(.plain)
            .quickLookPreview($preview)
        } else {
            card
                .accessibilityElement(children: .combine)
        }
    }

    private var card: some View {
        HStack(spacing: layout.spacingSm) {
            icon
                .font(fonts.attachmentIcon)
                .foregroundStyle(Color(colors.attachmentIcon))
                .frame(width: layout.iconSizeLg, height: layout.iconSizeLg)
                .background(
                    Color(colors.attachmentIconBackground),
                    in: RoundedRectangle(cornerRadius: layout.radiusMd, style: .continuous)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: layout.spacingXxxs) {
                Text(attachment.displayName)
                    .font(fonts.attachmentName)
                    .foregroundStyle(Color(colors.attachmentName))
                    .lineLimit(1)
                    .truncationMode(.middle)
                let details = attachment.details
                if !details.isEmpty {
                    Text(details)
                        .font(fonts.attachmentDetails)
                        .foregroundStyle(Color(colors.attachmentDetails))
                        .lineLimit(1)
                }
            }
        }
        .padding(layout.spacingSm)
        .background(
            Color(colors.attachmentBackground),
            in: RoundedRectangle(cornerRadius: layout.radiusXl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: layout.radiusXl, style: .continuous)
                .stroke(Color(colors.attachmentBorder))
        )
    }

    private var icon: Image {
        guard let type = attachment.contentType else {
            return attachment.kind == .image ? images.attachmentImage : images.attachmentFile
        }
        if type.conforms(to: .pdf) {
            return images.attachmentPDF
        } else if type.conforms(to: .image) {
            return images.attachmentImage
        } else if type.conforms(to: .audio) {
            return images.attachmentAudio
        } else if type.conforms(to: .movie) {
            return images.attachmentVideo
        } else if type.conforms(to: .archive) {
            return images.attachmentArchive
        }
        return images.attachmentFile
    }
}
