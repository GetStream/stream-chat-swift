//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct AttachmentTile<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout
    
    var body: some View {
        RoundedRectangle(cornerRadius: layout.radiusXl)
            .fill(Color(colors.attachmentPickerTileBackground))
            .overlay {
                content()
                    .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl))
            }
            .frame(width: 100, height: 100)
            .contentShape(RoundedRectangle(cornerRadius: layout.radiusXl))
    }
}
