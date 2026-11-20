//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/presence-format/

import StreamChat

struct Snippets_05_05_PresenceFormat {
    var channelController: ChatChannelController!
    var chatClient: ChatClient!
    var token: Token!
    var userID: UserId!

    // Listening to Presence Changes
    class PresenceObserver: EventsControllerDelegate {
      let eventsController: EventsController

      init(client: ChatClient) {
        eventsController = client.eventsController()
        eventsController.delegate = self
      }

      func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let event = event as? UserPresenceChangedEvent {
          // Update your UI with event.user and event.user.isOnline
          suppressUnusedWarning(event)
        }
      }
    }

    func presenceDataFormat() {
        guard let member = channelController.channel?.lastActiveMembers.first else { return }
        let isOnline = member.isOnline
        let lastActiveAt = member.lastActiveAt
        suppressUnusedWarning(isOnline, lastActiveAt)
    }

    func invisible() {
        chatClient.connectUser(
          userInfo: .init(
            id: userID,
            isInvisible: true
          ),
          token: token
        ) { error in
          // …
        }
    }
}
