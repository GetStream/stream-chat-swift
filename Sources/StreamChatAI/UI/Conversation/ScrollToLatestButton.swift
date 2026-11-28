//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct ScrollToLatestButton: View {
    var action: () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        Button(action: action) {
            images.conversationScrollToLatest
                .font(fonts.conversationScrollButton)
                .foregroundStyle(Color(colors.conversationScrollButtonIcon))
                .frame(width: layout.buttonVisualHeightMd, height: layout.buttonVisualHeightMd)
                .background(Circle().fill(Color(colors.conversationScrollButtonBackground)))
                .overlay(Circle().strokeBorder(Color(colors.conversationScrollButtonBorder)))
                .elevation(light: layout.lightElevation2, dark: layout.darkElevation2)
                .frame(minWidth: layout.buttonHitTargetMinWidth, minHeight: layout.buttonHitTargetMinHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Conversation.scrollToLatest)
    }
}
