//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public extension AIComposerView {
    /// A composer for an ``AIConversation``. It shows the conversation's
    /// ``AIConversation/composerViewModel``, sends what the person writes to the conversation,
    /// and offers to stop the agent while it answers. Given another conversation, it shows that
    /// one's draft.
    ///
    /// - Parameters:
    ///   - conversation: The conversation the person writes in.
    ///   - viewFactory: The composer's views.
    init<Message: AIMessage>(
        conversation: AIConversation<Message>,
        viewFactory: ComposerFactory = DefaultAIComposerViewFactory.shared
    ) {
        self.init(
            viewFactory: viewFactory,
            following: conversation.composerViewModel,
            onMessageSend: { conversation.send($0) },
            onStopGenerating: { conversation.stop() }
        )
    }
}
