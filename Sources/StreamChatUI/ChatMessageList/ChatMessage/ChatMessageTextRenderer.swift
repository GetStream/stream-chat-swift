//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The component responsible for getting the text content of a message text.
struct ChatMessageTextRenderer {
    func text(for message: ChatMessage, channel: ChatChannel) -> String {
        if message.type == .ephemeral {
            return message.text
        }

        if message.isDeleted {
            return L10n.Message.deletedMessagePlaceholder
        }

        if let currentUserLang = channel.membership?.language,
           let translatedText = message.translatedText(for: currentUserLang) {
            return translatedText
        }

        return message.text
    }
}
