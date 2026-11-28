//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A round badge on a tile, such as its check mark or its remove button.
@available(iOS 15.0, macOS 12.0, *)
struct TileBadge: View {
    let image: Image
    let fill: Color

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(colors.attachmentBadgeForeground).opacity(0.9))
                .elevation(light: layout.lightElevation1, dark: layout.darkElevation1)
            Circle()
                .fill(fill)
            image
                .font(fonts.attachmentBadgeIcon)
                .foregroundStyle(Color(colors.attachmentBadgeForeground))
        }
    }
}
