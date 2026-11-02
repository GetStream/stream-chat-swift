//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension AIComposerView {
    /// A composer for an ``AIChat``. It shows the chat's ``AIChat/composer``, sends what the
    /// person writes to the chat, and offers to stop the agent while it answers.
    ///
    /// - Parameters:
    ///   - chat: The conversation the person writes in.
    ///   - viewFactory: The composer's views.
    init<Message: AIMessage>(chat: AIChat<Message>, viewFactory: ComposerFactory = DefaultAIComposerViewFactory.shared) {
        self.init(
            viewFactory: viewFactory,
            viewModel: chat.composer,
            onMessageSend: { chat.send($0) },
            onStopGenerating: { chat.stop() }
        )
    }
}
