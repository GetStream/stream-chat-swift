//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The header while the model thinks, counting the seconds. A view opened midway counts
/// from how long the model had already thought.
struct ThinkingTitle: View {
    var duration: TimeInterval?
    @State private var appeared = Date()

    var body: some View {
        TimelineView(.periodic(from: appeared, by: 1)) { context in
            Text(StreamingReasoningView.thinkingTitle(elapsed: max(duration ?? 0, context.date.timeIntervalSince(appeared))))
                .monospacedDigit()
        }
    }
}
