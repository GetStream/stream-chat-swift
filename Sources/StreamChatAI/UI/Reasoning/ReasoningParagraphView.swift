//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// One paragraph of reasoning. It is equatable so that only the paragraph still being
/// written is rendered again as the reasoning grows.
struct ReasoningParagraphView: View, Equatable {
    let text: String
    let color: Color

    var body: some View {
        Text(ReasoningParagraph.attributed(text))
            .foregroundStyle(color)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}
