//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// One chat option: its icon, title and description. Tapping it runs its action.
struct ChatOptionRow: View {
    let option: ChatOption

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        Button {
            withAnimation {
                option.action()
            }
        } label: {
            HStack(spacing: layout.spacingMd) {
                Image(systemName: option.icon)

                VStack(alignment: .leading) {
                    Text(option.title)
                        .font(fonts.chatOptionTitle)

                    Text(option.description)
                        .font(fonts.chatOptionDescription)
                        .foregroundStyle(Color(colors.attachmentPickerOptionDescription))
                }
                Spacer()
            }
            .tint(Color(colors.attachmentPickerOptionTitle))
            .foregroundStyle(Color(colors.attachmentPickerOptionTitle))
        }
    }
}
