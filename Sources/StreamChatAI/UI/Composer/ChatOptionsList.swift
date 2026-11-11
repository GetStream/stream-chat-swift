//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The chat options a message can be sent with, such as web search.
@available(iOS 15.0, macOS 12.0, *)
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
