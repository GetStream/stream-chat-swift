//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

@available(iOS 16, *)
struct SelectionBadge: View {
    let isSelected: Bool

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    
    var body: some View {
        ZStack {
            if isSelected {
                TileBadge(image: images.attachmentSelected, fill: Color(colors.attachmentBadgeSelectedBackground))
            } else {
                Circle()
                    .stroke(Color(colors.attachmentBadgeForeground), lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 20, height: 20)
    }
}
