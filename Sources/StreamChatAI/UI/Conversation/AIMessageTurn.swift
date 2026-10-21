//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// A message the person sent, and the replies after it. Messages before the person's first
// one, such as a greeting, make a turn of their own.
struct AIMessageTurn<Message: Identifiable>: Identifiable {
    var messages: [Message]

    var id: Message.ID {
        messages[0].id
    }

    static func turns(of messages: [Message], isSentByCurrentUser: (Message) -> Bool) -> [AIMessageTurn] {
        var turns: [AIMessageTurn] = []
        for message in messages {
            if turns.isEmpty || isSentByCurrentUser(message) {
                turns.append(AIMessageTurn(messages: [message]))
            } else {
                turns[turns.count - 1].messages.append(message)
            }
        }
        return turns
    }
}
