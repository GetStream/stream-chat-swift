//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// A code block in a message: its language and a copy button over the highlighted code,
/// which scrolls sideways.
@available(iOS 15.0, macOS 12.0, *)
struct CodeBlockView: View {
    let configuration: CodeBlockConfiguration

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    @StateObject private var highlighting = CodeHighlighting()

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
                Text(code)
                    .textStyleFont()
                    .textStyleForegroundColor()
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
        .task(id: configuration.content) {
            guard configuration.language != nil else { return }
            highlighting.highlight(configuration.content)
        }
    }

    // Code without a language shows plain, in the text color of the reply.
    private var code: AttributedString {
        guard configuration.language != nil else {
            return AttributedString(configuration.content)
        }
        return highlighting.text(for: configuration.content, colors: codeColors)
    }

    private var codeColors: CodeColors {
        CodeColors(
            plainText: Color(colors.codeText),
            tokens: [
                .keyword: Color(colors.codeKeyword),
                .string: Color(colors.codeString),
                .type: Color(colors.codeType),
                .call: Color(colors.codeCall),
                .number: Color(colors.codeNumber),
                .comment: Color(colors.codeComment),
                .property: Color(colors.codeProperty),
                .dotAccess: Color(colors.codeDotAccess),
                .preprocessing: Color(colors.codePreprocessing)
            ]
        )
    }
}
