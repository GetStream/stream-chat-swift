//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/unread/

import StreamChat

@MainActor
struct Snippets_05_03_Unread {
    var channelController: ChatChannelController!
    var client: ChatClient!

    func readingUnreadCounts() {
        // Use the currentUserController to get unread counts and listen for changes
        let currentUserController = client.currentUserController()

        // Keep a strong reference to delegate since controller only keeps a weak reference
        let delegate = CurrentUserDelegate()
        currentUserController.delegate = delegate

        currentUserController.synchronize()
    }

    class CurrentUserDelegate: CurrentChatUserControllerDelegate {
      func currentUserController(_ controller: CurrentChatUserController,
                    didChangeCurrentUserUnreadCount: UnreadCount) {
        // Handle unread count change (both initial and real-time updates)
      }
    }

    func unreadCountsServerSide() {
        let currentUserController = client.currentUserController()
        currentUserController.loadAllUnreads { result in
          switch result {
          case .success(let unreads):
            print(unreads.totalUnreadCount) // total unread count for user
            print(unreads.channels) // distribution of unread counts across channels
            print(unreads.channelType) // distribution of unread counts across channel types
            print(unreads.totalUnreadThreadsCount) // total unread threads
            print(unreads.threads) // list of unread counts per thread
          case .failure(let error):
            print("Failed to load unread counts: \(error)")
          }
        }
    }

    func markRead() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.markRead()
    }

    func markRead2() {
        channelController.markUnread(from: "message-id") { result in
          // …
        }
    }

    func markAllAsRead() {
        let currentUserController = client.currentUserController()
        currentUserController.markAllRead { error in
          // Handle error
        }
    }

    func readStateShowingHowFarOtherUsersHaveRead() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.synchronize() { error in
          if error == nil {
            let reads = channelController.channel?.reads
            suppressUnusedWarning(reads)
          }
        }
    }

    func unreadMessagesPerChannel() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        // Keep a strong reference to delegate since controller only keeps a weak reference
        let delegate = ChannelDelegate()
        channelController.delegate = delegate

        channelController.synchronize()
    }

    class ChannelDelegate: ChatChannelControllerDelegate {
      func channelController(_ channelController: ChatChannelController,
                  didUpdateChannel channel: EntityChange<ChatChannel>) {
        let unreadCount = channelController.channel?.unreadCount
        suppressUnusedWarning(unreadCount)
      }
    }

    // `ChannelDelegate` is declared by an earlier fence too, so this one stays local
    func unreadMentionsPerChannel() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        class ChannelDelegate: ChatChannelControllerDelegate {
          func channelController(_ channelController: ChatChannelController,
                      didUpdateChannel channel: EntityChange<ChatChannel>) {
            let unreadMentions = channelController.channel?.unreadCount.mentions
            suppressUnusedWarning(unreadMentions)
          }
        }

        // Keep a strong reference to delegate since controller only keeps a weak reference
        let delegate = ChannelDelegate()
        channelController.delegate = delegate

        channelController.synchronize()
    }
}
