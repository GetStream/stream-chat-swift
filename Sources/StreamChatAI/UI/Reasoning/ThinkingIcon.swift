//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The brain, pulsing while the model thinks (on systems that animate symbols).
struct ThinkingIcon: View {
    var image: Image
    var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if #available(iOS 17.0, *) {
            image
                .symbolEffect(.pulse, options: .repeating, isActive: isActive && !reduceMotion)
        } else {
            image
        }
    }
}
