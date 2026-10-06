//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A round badge on a tile, such as its check mark or its remove button.
@available(iOS 16, *)
struct TileBadge: View {
    let image: Image
    let fill: Color

    @Injected(\.aiAppearance.colors) private var colors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(colors.attachmentBadgeForeground).opacity(0.9))
                .shadow(radius: 1)
            Circle()
                .fill(fill)
            image
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(colors.attachmentBadgeForeground))
        }
    }
}
