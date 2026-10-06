//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The chat option picked for the next message, with a button that removes it.
struct SelectedChatOptionChip: View {
    let option: ChatOption
    let onRemove: () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        HStack {
            HStack {
                Image(systemName: option.icon)
                Text(option.shortTitle)
                    .font(fonts.headline)
                Button {
                    onRemove()
                } label: {
                    images.composerRemove
                }
            }
            .foregroundStyle(Color(colors.composerChatOptionText))
            .padding(.all, layout.spacingXs)
            .background(Color(colors.composerChatOptionBackground))
            .cornerRadius(layout.radiusXl)
            
            Spacer()
        }
    }
}
