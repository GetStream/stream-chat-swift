//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/send-message/

import Foundation
import StreamChat

struct Snippets_04_01_SendMessage {
    var chatClient: ChatClient!
    var message: ChatMessage!
    var messageController: ChatMessageController!
    var originalMessage: ChatMessage!

    func sendingAMessage() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)

        channelController.createNewMessage(text: "Hello, world!") { result in
          switch result {
          case .success(let messageId):
            print(messageId)
          case .failure(let error):
            print(error)
          }
        }
    }

    func mentions() {
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "general"))

        // Send a message mentioning all online users
        channelController.createNewMessage(text: "Hey everyone!", mentionedHere: true)

        // Send a message mentioning all channel members
        channelController.createNewMessage(text: "Important announcement!", mentionedChannel: true)

        // Send a message mentioning specific roles
        channelController.createNewMessage(
          text: "Attention moderators!",
          mentionedRoles: ["channel_moderator", "admin"]
        )

        // Send a message mentioning a user group
        channelController.createNewMessage(
          text: "Design team, please review!",
          mentionedGroupIds: ["design-team-id"]
        )
    }

    func sendingMessagesWithAttachments() throws {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)

        let fileURL = URL(fileURLWithPath: "<file path>")
        let attachment = try AnyAttachmentPayload(
          localFileURL: fileURL,
          attachmentType: .image
        )

        channelController.createNewMessage(
          text: "Hello",
          attachments: [attachment],
          mentionedUserIds: ["josh-id"],
          extraData: ["priority": .string("high")]) { result in
            // Handle result
          }
    }

    func urlEnrichment() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)

        channelController.createNewMessage(text: "Check this out https://imgur.com/r/bears/4zmGbMN") { result in
          // Handle result
        }

        // Once the server has enriched the URL, the preview is a link attachment on the sent message
        let linkPreview = message.attachments(payloadType: LinkAttachmentPayload.self).first
        let previewTitle = linkPreview?.title
        let scrapedURL = linkPreview?.originalURL
        suppressUnusedWarning(previewTitle, scrapedURL)
    }

    func retrievingAMessage() {
        let channelId = ChannelId(type: .messaging, id: "general")
        let messageId = "message-id"
        let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

        messageController.synchronize { error in
          print(error ?? messageController.message!)
        }
    }

    func updatingAMessage() {
        messageController.editMessage(text: "Updated message text") { error in
          print(error ?? messageController.message!)
        }
    }

    func partialUpdate() {
        let messageController = chatClient.messageController(
          cid: ChannelId(type: .messaging, id: "general"),
          messageId: originalMessage.id
        )

        // Update text
        messageController.partialUpdateMessage(text: "Updated text")

        // Remove a custom field
        messageController.partialUpdateMessage(unsetProperties: ["color"])

        // Update nested properties
        messageController.partialUpdateMessage(extraData: ["details.status": .string("complete")])
    }

    func deletingAMessage() {
        // Soft delete
        messageController.deleteMessage { error in /* ... */ }

        // Hard delete
        messageController.deleteMessage(hard: true) { error in /* ... */ }

        // Delete for me
        messageController.deleteMessageForMe { error in /* ... */ }
    }
}
