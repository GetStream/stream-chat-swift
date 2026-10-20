//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A reply's thinking before any of it arrives: "Thinking…", counting the seconds.
///
/// ``AIConversationView`` shows it under the latest question while `isThinking`, counting from
/// when the question was asked, and the reply's first reasoning step takes its place as
/// "Thought for 8s". Anywhere else it counts from `since`, or from when it appears.
public struct AIThinkingView: View {
    var since: Date?
    var font: Font?

    @Environment(\.aiThinkingTurn) private var turn

    /// - Parameters:
    ///   - since: When the thinking began.
    ///   - font: The font of the header, `AIAppearance.fonts.messagePart` by default.
    public init(since: Date? = nil, font: Font? = nil) {
        self.since = since
        self.font = font
    }

    public var body: some View {
        var view = StreamingReasoningView(text: "", isThinking: true, font: font)
        view.thinkingStart = since ?? turn.flatMap { $0.clock.start(of: $0.key) }
        return view
    }
}
