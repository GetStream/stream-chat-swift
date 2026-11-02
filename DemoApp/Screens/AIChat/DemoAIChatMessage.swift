//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatAI

/// A message of a Stream Chat channel as StreamChatAI shows it: the person's messages in
/// bubbles, and the agent's replies as their steps, their answer and their attachments.
///
/// A message is the agent's when it has `ai_generated: true`, or when someone else sent it. The
/// agent is still writing it while it has `generating: true`, and its steps are its attachments
/// of the `ai_*` types.
struct DemoAIChatMessage: AIMessage {
    let message: ChatMessage
    let role: AIMessageRole
    let parts: [AIMessagePart]
    let attachments: [AIMessageAttachment]

    init(_ message: ChatMessage) {
        self.message = message
        role = message.isSentByCurrentUser && !message.isAIGenerated ? .user : .assistant
        parts = AIMessagePart.parts(from: message.allAttachments.map { ($0.type.rawValue, $0.payload) })
        attachments = message.imageAttachments.map { image in
            .image(image.uploadingState?.localFileURL ?? image.imageURL, name: image.title)
        } + message.videoAttachments.map { video in
            .file(video.uploadingState?.localFileURL ?? video.videoURL, name: video.title, size: video.file.size, mimeType: video.file.mimeType)
        } + message.fileAttachments.map { file in
            .file(file.uploadingState?.localFileURL ?? file.assetURL, name: file.title, size: file.file.size, mimeType: file.file.mimeType)
        }
    }

    var id: MessageId {
        message.id
    }

    var text: String {
        message.text
    }

    var isGenerating: Bool {
        message.extraData["generating"]?.boolValue == true
    }
}

extension ChatMessage {
    /// Whether the agent wrote it, as the Stream AI backend contract marks its replies.
    var isAIGenerated: Bool {
        extraData["ai_generated"]?.boolValue == true
    }

    /// Whether it belongs in an AI conversation: a message or a reply that is still there.
    var isShownInAIConversation: Bool {
        deletedAt == nil && (type == .regular || type == .reply)
    }
}
