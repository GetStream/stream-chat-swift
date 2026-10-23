//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The header while the model thinks, counting the seconds. A view opened midway counts
/// from how long the model had already thought, or from `since`, when the thinking began.
struct ThinkingTitle: View {
    var duration: TimeInterval?
    var since: Date?
    @State private var appeared = Date()

    var body: some View {
        let start = since ?? appeared
        TimelineView(.periodic(from: start, by: 1)) { context in
            Text(StreamingReasoningView.thinkingTitle(elapsed: max(duration ?? 0, context.date.timeIntervalSince(start))))
                .monospacedDigit()
        }
    }
}
