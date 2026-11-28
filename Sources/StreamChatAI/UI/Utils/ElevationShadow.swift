//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension View {
    // An elevation token's shadow, the light or the dark one for the color scheme. A horizontal
    // shadow falls sideways, as a sidebar's does, by the token's vertical offset.
    func elevation(light: BoxShadow, dark: BoxShadow, axis: Axis = .vertical) -> some View {
        modifier(ElevationShadow(light: light, dark: dark, axis: axis))
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct ElevationShadow: ViewModifier {
    let light: BoxShadow
    let dark: BoxShadow
    let axis: Axis

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shadow = colorScheme == .dark ? dark : light
        content.shadow(
            color: Color(shadow.color),
            radius: shadow.blur / 2,
            x: axis == .horizontal ? shadow.y : shadow.x,
            y: axis == .horizontal ? shadow.x : shadow.y
        )
    }
}
