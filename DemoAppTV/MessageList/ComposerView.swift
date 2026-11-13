//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct ComposerView: View {
    let chat: Chat
    @State private var text = ""

    var body: some View {
        HStack(spacing: 24) {
            TextField("Message", text: $text)
                .onSubmit(send)
            Button("Send", action: send)
                .disabled(trimmedText.isEmpty)
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func send() {
        let text = trimmedText
        guard !text.isEmpty else { return }
        self.text = ""
        Task {
            try? await chat.sendMessage(with: text)
        }
    }
}
