//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

@available(iOS 16.0, *)
extension View {
    @ViewBuilder func applyBeginAtZero(_ include: Bool) -> some View {
        self.chartYScale(domain: include ? .automatic(includesZero: true) : .automatic(includesZero: false))
    }
}
