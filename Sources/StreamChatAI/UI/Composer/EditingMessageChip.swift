//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

// Says the person is editing a message they sent, with a button that cancels it.
@available(iOS 15.0, macOS 12.0, *)
struct EditingMessageChip: View {
    let onCancel: () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        HStack {
            HStack {
                images.messageEdit
                    .accessibilityHidden(true)
                Text(L10n.Composer.editing)
                    .font(fonts.composerChatOption)
                Button(action: onCancel) {
                    images.composerRemove
                }
                .accessibilityLabel(L10n.Composer.cancelEditing)
            }
            .foregroundStyle(Color(colors.composerChatOptionText))
            .padding(.all, layout.spacingXs)
            .background(Color(colors.composerChatOptionBackground))
            .cornerRadius(layout.radiusXl)

            Spacer()
        }
    }
}
