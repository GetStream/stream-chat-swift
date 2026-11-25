//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/threads/

import Foundation
import StreamChat

@MainActor struct Snippets_04_03_Threads {
    var chatClient: ChatClient!
    var client: ChatClient!
    var date: Date!
    var messageController: ChatMessageController!
    var parentMessageId: MessageId!
    var threadId: MessageId!
    var token: Token!

    func startingAThread() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let messageId = "parent-message-id"
        let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

        messageController.createNewReply(text: "This is a reply in a thread")
    }

    func paginatingThreadReplies() {
        let messageController = client.messageController(
          cid: .init(type: .messaging, id: "general"),
          messageId: "parent-message-id"
        )

        // Get the first 20 replies
        messageController.loadPreviousReplies(limit: 20) { error in
          guard error == nil else { return }
          print(messageController.replies)

          // Get 20 more (older) replies
          messageController.loadPreviousReplies(limit: 20) { error in
            print(messageController.replies)
          }
        }
    }

    func inlineReplies() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)

        channelController.createNewMessage(
          text: "I agree with this point",
          quotedMessageId: "original-message-id"
        ) { result in
          switch result {
          case let .success(messageId):
            print(messageId)
          case let .failure(error):
            print(error)
          }
        }
    }

    func queryingThreads() {
        let query = ThreadListQuery(watch: true)
        let threadListController = chatClient.threadListController(query: query)
        threadListController.synchronize { error in
          print(threadListController.threads)
        }
    }

    func filteringAndSorting() {
        // Get threads created by a specific user, sorted by creation date
        let query = ThreadListQuery(
          watch: true,
          filter: .and([
            .equal(.createdByUserId, to: "user-1"),
            .greaterOrEqual(.updatedAt, than: date)
          ]),
          sort: [.init(key: .createdAt, isAscending: false)],
          limit: 10,
          replyLimit: 5,
          participantLimit: 25
        )
        let threadListController = chatClient.threadListController(query: query)
        threadListController.synchronize { error in
          guard error == nil else { return }
          print(threadListController.threads)

          // Get next page
          threadListController.loadMoreThreads(limit: 10) { result in
            // Handle result
          }
        }
    }

    func gettingAThreadByID() {
        let messageController = chatClient.messageController(
          cid: ChannelId(type: .messaging, id: "general"),
          messageId: parentMessageId
        )

        messageController.loadThread(replyLimit: 10, participantLimit: 25) { result in
          switch result {
          case .success(let thread):
            print(thread.replyCount, thread.latestReplies)
          case .failure(let error):
            print(error)
          }
        }
    }

    func updatingThreadTitleAndCustomData() {
        // Set properties
        messageController.updateThread(
          title: "Project Discussion",
          extraData: ["priority": .string("high")]
        ) { result in
          // Handle result
        }

        // Remove properties
        messageController.updateThread(
          title: nil,
          unsetProperties: ["priority"]
        ) { result in
          // Handle result
          }
    }

    func totalUnreadThreadsAsync() async throws {
        let connectedUser = try await chatClient.connectUser(
          userInfo: .init(id: "user-id"),
          token: token
        )
        print(connectedUser.state.user.unreadCount.threads)
    }

    func markingThreadsAsReadOrUnread() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let messageController = chatClient.messageController(cid: channelId, messageId: threadId)

        // Mark thread as read
        messageController.markThreadRead { error in
          // Handle error
        }

        // Mark thread as unread
        messageController.markThreadUnread { error in
          // Handle error
        }
    }

    func unreadCountPerThread() {
        let currentUserController = chatClient.currentUserController()

        currentUserController.loadAllUnreads { result in
          switch result {
          case .success(let unreads):
            print(unreads.totalUnreadThreadsCount)

            for thread in unreads.threads {
              print(thread.parentMessageId)
              print(thread.unreadCount)
              if let lastRead = thread.lastRead {
                print(lastRead)
              }
            }
          case .failure(let error):
            print(error)
          }
        }
    }

    func threadManager() {
        let threadListController = chatClient.threadListController(query: ThreadListQuery(watch: true))

        // Load threads
        threadListController.synchronize { error in
          guard error == nil else { return }

          // Access current state
          let threads = threadListController.threads
          suppressUnusedWarning(threads)

          // Load more threads
          threadListController.loadMoreThreads { result in
            // Handle result
          }
        }

        // The current user's unread thread count
        let unreadThreadCount = chatClient.currentUserController().unreadCount.threads
        suppressUnusedWarning(unreadThreadCount)
    }

    class ThreadRepliesObserver: ChatMessageControllerDelegate {
      let threadListController: ChatThreadListController
      var messageController: ChatMessageController?

      init(chatClient: ChatClient) {
        // `watch: true` is required to receive real-time updates
        threadListController = chatClient.threadListController(query: ThreadListQuery(watch: true, limit: 10))
        threadListController.synchronize { [weak self] error in
          guard let self, let thread = self.threadListController.threads.first else { return }

          // Open the thread: the message controller keeps its replies up to date from now on
          let messageController = chatClient.messageController(
            cid: thread.channel.cid,
            messageId: thread.parentMessageId
          )
          messageController.delegate = self
          messageController.loadPreviousReplies()
          self.messageController = messageController
        }
      }

      func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
      ) {
        print(controller.replies)
      }
    }

    func eventHandling() {}

    class ThreadListObserver: ChatThreadListControllerDelegate {
      let threadListController: ChatThreadListController

      init(chatClient: ChatClient) {
        // With `watch: true`, all loaded threads receive their events
        threadListController = chatClient.threadListController(query: ThreadListQuery(watch: true))
        threadListController.delegate = self
        threadListController.synchronize()
      }

      func controller(
        _ controller: ChatThreadListController,
        didChangeThreads changes: [ListChange<ChatThread>]
      ) {
        print(controller.threads)
      }
    }

    func eventHandling2() {}
}
