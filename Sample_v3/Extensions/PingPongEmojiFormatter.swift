//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient

/// Formats the given WebSocket ping/pong log message with the emoji prefix: 🏓
public class PingPongEmojiFormatter: LogFormatter {
    public func format(logDetails: LogDetails, message: String) -> String {
        (message.contains("WebSocket Ping") || message.contains("WebSocket Pong") ? "🏓 " : "") + message
    }
}
