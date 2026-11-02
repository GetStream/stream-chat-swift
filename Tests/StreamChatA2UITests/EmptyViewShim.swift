//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A stand-in view for catalog definitions in tests that never render.
@MainActor
struct EmptyViewShim: View {
    var body: some View {
        EmptyView()
    }
}
