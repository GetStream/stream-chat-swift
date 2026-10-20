//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct AIMessageTurnView<Message: Identifiable, MessageContent: View, Footer: View>: View {
    var messages: [Message]
    var spacing: CGFloat
    var isThinking: Bool
    var footer: Footer?
    var messageContent: (Message) -> MessageContent

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(messages) { message in
                messageContent(message)
            }
            if isThinking {
                AIThinkingView()
            }
            if let footer {
                footer
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
