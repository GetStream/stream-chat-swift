//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// A message the person sent: its attachments, then its text in a bubble, at the trailing edge.
/// Pressing the bubble offers to copy the text, and to edit it given `onEdit`.
public struct AIUserMessageView<AttachmentContent: View>: View {
    var text: String
    var attachments: [AIMessageAttachment]
    var onEdit: (@MainActor () -> Void)?
    var attachmentContent: (AIMessageAttachment) -> AttachmentContent

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var icons
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - text: What the person wrote.
    ///   - attachments: What they sent with it, such as images and files.
    ///   - onEdit: Edits the message, such as by putting its text back in the composer.
    ///   - attachmentContent: The view of each attachment.
    public init(
        text: String,
        attachments: [AIMessageAttachment] = [],
        onEdit: (@MainActor () -> Void)? = nil,
        @ViewBuilder attachmentContent: @escaping (AIMessageAttachment) -> AttachmentContent
    ) {
        self.text = text
        self.attachments = attachments
        self.onEdit = onEdit
        self.attachmentContent = attachmentContent
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: layout.spacingXs) {
            ForEach(attachments.indices, id: \.self) { index in
                attachmentContent(attachments[index])
            }
            if !text.isEmpty {
                Text(text)
                    .font(fonts.userMessage)
                    .foregroundStyle(Color(colors.userMessageText))
                    .padding(.horizontal, layout.spacingMd)
                    .padding(.vertical, layout.spacingSm)
                    .background(
                        Color(colors.userMessageBackground),
                        in: RoundedRectangle(cornerRadius: layout.radius2xl, style: .continuous)
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = text
                        } label: {
                            Label {
                                Text(L10n.MessageActions.copy)
                            } icon: {
                                icons.messageCopy
                            }
                        }
                        if let onEdit {
                            Button(action: onEdit) {
                                Label {
                                    Text(L10n.MessageActions.edit)
                                } icon: {
                                    icons.messageEdit
                                }
                            }
                        }
                    }
            }
        }
        .padding(.leading, layout.spacing3xl)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

public extension AIUserMessageView where AttachmentContent == AIMessageAttachmentView {
    /// - Parameters:
    ///   - text: What the person wrote.
    ///   - attachments: What they sent with it, such as images and files.
    ///   - onEdit: Edits the message, such as by putting its text back in the composer.
    init(
        text: String,
        attachments: [AIMessageAttachment] = [],
        onEdit: (@MainActor () -> Void)? = nil
    ) {
        self.init(text: text, attachments: attachments, onEdit: onEdit) { attachment in
            AIMessageAttachmentView(attachment: attachment)
        }
    }
}
