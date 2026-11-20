//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/typing-indicators/

import StreamChat

@MainActor
struct Snippets_05_04_TypingIndicators {
    var client: ChatClient!

    func sendingTypingEvents() {
        // The Swift client keeps track of the typing state for you.
        // Just call `sendKeystrokeEvent()` every time the user types.

        // sends a typing.start event, resent at most once every 23 seconds while the user keeps typing
        // automatically sends a typing.stop event 7 seconds after the last keystroke
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        // automatically
        channelController.sendKeystrokeEvent()

        // or manually
        channelController.sendStartTypingEvent()
        channelController.sendStopTypingEvent()
    }

    func receivingTypingIndicatorEvents() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        // Keep a strong reference to delegate since controller only keeps a weak reference
        let delegate = ChannelDelegate()
        channelController.delegate = delegate

        channelController.synchronize()
    }

    class ChannelDelegate: ChatChannelControllerDelegate {
      func channelController(_ channelController: ChatChannelController,
                  didChangeTypingUsers typingUsers: Set<TypingUser>) {
        // handle new typing users
      }
    }
}
