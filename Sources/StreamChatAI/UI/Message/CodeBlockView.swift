//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit
internal import MarkdownUI

/// A code block in a message: its language and a copy button over the highlighted code,
/// which scrolls sideways.
struct CodeBlockView: View {
    let configuration: CodeBlockConfiguration

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(configuration.language ?? L10n.StreamingMessage.codeBlockLanguageFallback)
                    .font(fonts.codeBlockLanguage)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(colors.codeBlockHeaderText))
                Spacer()

                images.codeBlockCopy
                    .onTapGesture {
                        UIPasteboard.general.string = configuration.content
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, layout.spacingXs)
            .background {
                Color(colors.codeBlockHeaderBackground)
            }

            Divider()

            ScrollView(.horizontal) {
                configuration.label
                    .relativeLineSpacing(.em(0.25))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding()
            }
        }
        .background(Color(colors.codeBlockBackground))
        .clipShape(RoundedRectangle(cornerRadius: layout.radiusMd))
        .markdownMargin(top: .zero, bottom: .em(0.8))
    }
}
