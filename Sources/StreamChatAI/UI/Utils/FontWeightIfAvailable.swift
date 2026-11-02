//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension View {
    // Before iOS 16 a view can't change its font's weight, so it keeps the weight it has.
    @ViewBuilder
    func fontWeightIfAvailable(_ weight: Font.Weight) -> some View {
        if #available(iOS 16, *) {
            fontWeight(weight)
        } else {
            self
        }
    }
}
