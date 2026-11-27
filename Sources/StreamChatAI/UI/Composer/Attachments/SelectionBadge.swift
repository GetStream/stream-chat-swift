//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct SelectionBadge: View {
    let isSelected: Bool

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout
    
    var body: some View {
        ZStack {
            if isSelected {
                TileBadge(image: images.attachmentSelected, fill: Color(colors.attachmentBadgeSelectedBackground))
            } else {
                Circle()
                    .stroke(Color(colors.attachmentBadgeForeground), lineWidth: layout.iconStrokeEmphasis)
                    .frame(width: layout.iconSizeSm, height: layout.iconSizeSm)
            }
        }
        .frame(width: layout.iconSizeMd, height: layout.iconSizeMd)
    }
}
