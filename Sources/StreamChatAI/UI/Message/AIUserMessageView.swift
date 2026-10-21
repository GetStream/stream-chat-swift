//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// A message the person sent: its attachments, then its text in a bubble, at the trailing edge.
/// Pressing the bubble offers to copy the text, and to edit it given `onEdit`.
public struct AIUserMessageView<Factory: AIConversationViewFactory>: View {
    var viewFactory: Factory
    var text: String
    var attachments: [AIMessageAttachment]
    var onEdit: (@MainActor () -> Void)?

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var icons
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - viewFactory: The views of the attachments.
    ///   - text: What the person wrote.
    ///   - attachments: What they sent with it, such as images and files.
    ///   - onEdit: Edits the message, such as by putting its text back in the composer.
    public init(
        viewFactory: Factory = DefaultAIConversationViewFactory.shared,
        text: String,
        attachments: [AIMessageAttachment] = [],
        onEdit: (@MainActor () -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        self.text = text
        self.attachments = attachments
        self.onEdit = onEdit
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: layout.spacingXs) {
            ForEach(attachments.indices, id: \.self) { index in
                viewFactory.makeAttachmentView(
                    options: AIMessageAttachmentViewOptions(attachment: attachments[index], role: .user)
                )
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
