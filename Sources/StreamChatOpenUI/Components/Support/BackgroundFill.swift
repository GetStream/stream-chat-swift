//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
extension View {
    // A fill behind the view, as a view of its own. As a background style, iOS 27 draws the
    // view's text again each time more of it scrolls into a list.
    func backgroundFill<Style: ShapeStyle>(_ style: Style) -> some View {
        background { Rectangle().fill(style) }
    }

    func backgroundFill<Style: ShapeStyle, Fill: Shape>(_ style: Style, in shape: Fill) -> some View {
        background { shape.fill(style) }
    }
}
