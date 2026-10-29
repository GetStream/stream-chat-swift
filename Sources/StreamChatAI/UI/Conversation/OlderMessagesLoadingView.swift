//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct OlderMessagesLoadingView: View {
    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ProgressView()
            .tint(Color(colors.conversationLoadingIndicator))
            .frame(maxWidth: .infinity)
            .padding(.top, layout.spacingMd)
    }
}
