//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct ScrollToLatestButton: View {
    var action: () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        let shadow = layout.lightElevation2
        Button(action: action) {
            images.conversationScrollToLatest
                .font(fonts.conversationScrollButton)
                .foregroundStyle(Color(colors.conversationScrollButtonIcon))
                .frame(width: layout.buttonVisualHeightMd, height: layout.buttonVisualHeightMd)
                .background(Circle().fill(Color(colors.conversationScrollButtonBackground)))
                .overlay(Circle().strokeBorder(Color(colors.conversationScrollButtonBorder)))
                .shadow(color: Color(shadow.color), radius: shadow.blur / 2, x: shadow.x, y: shadow.y)
                .frame(minWidth: layout.buttonHitTargetMinWidth, minHeight: layout.buttonHitTargetMinHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Conversation.scrollToLatest)
    }
}
