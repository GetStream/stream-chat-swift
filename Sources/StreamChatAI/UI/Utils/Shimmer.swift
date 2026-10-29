//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A highlight sweeping across the content while something is in progress. It stays
/// still when Reduce Motion is on.
struct Shimmer: ViewModifier {
    let isActive: Bool
    let highlight: Color

    @State private var moving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .overlay {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        LinearGradient(colors: [.clear, highlight, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: width * 0.6)
                            .offset(x: moving ? width : -width * 0.6)
                            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: moving)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
                .onAppear { moving = true }
                .onDisappear { moving = false }
        } else {
            content
        }
    }
}
