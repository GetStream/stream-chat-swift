//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/drafts/

import StreamChat
import UIKit

struct Snippets_05_10_12_Drafts {
    var chatClient: ChatClient!
    var currentUserController: CurrentChatUserController!
    var imageAttachment: AnyAttachmentPayload!

    func creatingADraftMessage() {
        // Create/update a draft message in a channel
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)
        channelController.updateDraftMessage(
            text: "Hello, this is my draft message",
            isSilent: false,
            attachments: [imageAttachment],
            mentionedUserIds: ["user-id-1", "user-id-2"],
            quotedMessageId: "quoted-message-id",
            extraData: ["custom_field": .string("value")]
        ) { _ in
            print("Draft message saved: \(channelController.channel?.draftMessage?.text ?? "")")
        }

        // Create/update a draft message in a thread (parent message)
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "parent-message-id"
        )
        messageController.updateDraftReply(
            text: "This is my draft reply",
            isSilent: false,
            attachments: [imageAttachment],
            mentionedUserIds: ["user-id-1"],
            quotedMessageId: "quoted-message-id",
            showReplyInChannel: true,
            extraData: ["custom_field": .string("value")]
        ) { _ in
            print("Draft message saved: \(messageController.message?.draftReply?.text ?? "")")
        }
    }

    func deletingADraftMessage() {
        // Delete the draft message for a channel
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)
        channelController.deleteDraftMessage()

        // Delete the draft message for a thread
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "parent-message-id"
        )
        messageController.deleteDraftReply()
    }

    func loadingADraftMessage() {
        // Load the draft message for a channel
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)
        channelController.loadDraftMessage { result in
            switch result {
            case .success(let draftMessage):
                print("Draft message loaded: \(draftMessage?.text ?? "")")
            case .failure(let error):
                print("Failed to load draft message: \(error)")
            }
        }

        // Load the draft message for a thread
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "parent-message-id"
        )
        messageController.loadDraftReply { result in
            switch result {
            case .success(let draftReply):
                print("Draft reply loaded: \(draftReply?.text ?? "")")
            case .failure(let error):
                print("Failed to load draft reply: \(error)")
            }
        }
    }

    func queryingDraftMessages() {
        // Load the draft messages for the current user
        let currentUserController = chatClient.currentUserController()
        currentUserController.loadDraftMessages { result in
            switch result {
            case .success:
                print("Draft messages loaded: \(currentUserController.draftMessages)")
            case .failure(let error):
                print("Failed to load draft messages: \(error)")
            }
        }
    }

    // Whenever the drafts are updated, it will be notified through the currentUserController delegate
    class MyView: UIView, CurrentChatUserControllerDelegate {
        let controller: CurrentChatUserController

        init(controller: CurrentChatUserController) {
            self.controller = controller
            super.init(frame: .zero)
            controller.delegate = self
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func currentUserController(
            _ controller: CurrentChatUserController,
            didChangeDraftMessages draftMessages: [DraftMessage]
        ) {
            // Handle the changes
        }
    }

    func pagination() {
        // Load the next page of draft messages
        currentUserController.loadMoreDraftMessages()

        // With a custom page size
        currentUserController.loadMoreDraftMessages(limit: 20) { result in
            switch result {
            case .success:
                print("Draft messages loaded: \(currentUserController.draftMessages)")
            case .failure(let error):
                print("Failed to load draft messages: \(error)")
            }
        }
    }

    // Events
    class DraftEventsObserver: EventsControllerDelegate {
        let eventsController: EventsController

        init(chatClient: ChatClient) {
            eventsController = chatClient.eventsController()
            eventsController.delegate = self
        }

        func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
            if let event = event as? DraftUpdatedEvent {
                let threadId = event.draftMessage.threadId
                let channelId = event.cid
                // handle draft updated event
                suppressUnusedWarning(threadId, channelId)
            } else if let event = event as? DraftDeletedEvent {
                let threadId = event.threadId
                let channelId = event.cid
                // handle draft deleted event
                suppressUnusedWarning(threadId, channelId)
            }
        }
    }
}
