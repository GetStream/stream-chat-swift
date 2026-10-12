//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The chat options a message can be sent with, such as web search.
struct ChatOptionsList: View {
    let options: [ChatOption]

    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: layout.spacingMd) {
                ForEach(options) { option in
                    ChatOptionRow(option: option)
                }
            }
            .padding()
        }
    }
}
