//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A reply's thinking before any of it arrives: "Thinking…", counting the seconds.
///
/// ``AIConversationView`` shows it under the latest question while `isThinking`, counting from
/// when the question was asked, and the reply's first reasoning step takes its place as
/// "Thought for 8s". Anywhere else it counts from `since`, or from when it appears. Its header
/// is in `AIAppearance.fonts.messagePart`, as reasoning steps are.
public struct AIThinkingView: View {
    var since: Date?

    @Environment(\.aiThinkingTurn) private var turn

    /// - Parameter since: When the thinking began.
    public init(since: Date? = nil) {
        self.since = since
    }

    public var body: some View {
        StreamingReasoningView(thinkingSince: since ?? turn.flatMap { $0.clock.start(of: $0.key) })
    }
}
