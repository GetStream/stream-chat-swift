//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension AIComposerView {
    /// A composer for an ``AIConversation``. It shows the conversation's ``AIConversation/composer``, sends what the
    /// person writes to the conversation, and offers to stop the agent while it answers.
    ///
    /// - Parameters:
    ///   - conversation: The conversation the person writes in.
    ///   - viewFactory: The composer's views.
    init<Message: AIMessage>(conversation: AIConversation<Message>, viewFactory: ComposerFactory = DefaultAIComposerViewFactory.shared) {
        self.init(
            viewFactory: viewFactory,
            viewModel: conversation.composerViewModel,
            onMessageSend: { conversation.send($0) },
            onStopGenerating: { conversation.stop() }
        )
    }
}
