//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension MessagePayload {
    /// Converts the MessagePayload to a ChatMessage model
    /// - Parameters:
    ///   - cid: The channel ID the message belongs to
    ///   - currentUserId: The current user's ID for determining sent status
    ///   - channelReads: Channel reads for determining readBy status
    /// - Returns: A ChatMessage instance
    func asModel(
        cid: ChannelId,
        currentUserId: UserId?,
        channelReads: [ChatChannelRead]
    ) -> ChatMessage? {
        let author = user.asModel()
        let mentionedUsers = Set(mentionedUsers.compactMap { $0.asModel() })
        let threadParticipants = threadParticipants.compactMap { $0.asModel() }
        
        // Map quoted message recursively
        let quotedMessage = quotedMessage?.asModel(
            cid: cid,
            currentUserId: currentUserId,
            channelReads: channelReads
        )
        
        // Map reactions
        let latestReactions = Set(latestReactions.compactMap { $0.asModel(messageId: id) })

        let currentUserReactions: Set<ChatMessageReaction>
        if ownReactions.isEmpty {
            currentUserReactions = latestReactions.filter { $0.author.id == currentUserId }
        } else {
            currentUserReactions = Set(ownReactions.compactMap { $0.asModel(messageId: id) })
        }
        
        // Map attachments
        let attachments: [AnyChatMessageAttachment] = attachments
            .enumerated()
            .compactMap { offset, attachmentPayload in
                guard let payloadData = try? JSONEncoder.stream.encode(attachmentPayload.payload) else {
                    return nil
                }
                return AnyChatMessageAttachment(
                    id: .init(cid: cid, messageId: id, index: offset),
                    type: attachmentPayload.type,
                    payload: payloadData,
                    downloadingState: nil,
                    uploadingState: nil
                )
            }

        // Calculate readBy from channel reads
        let createdAtInterval = createdAt.timeIntervalSince1970
        let messageUserId = user.id
        let readBy = channelReads.filter { read in
            read.user.id != messageUserId && read.lastReadAt.timeIntervalSince1970 >= createdAtInterval
        }
        
        return ChatMessage(
            id: id,
            cid: cid,
            text: text,
            type: type,
            command: command,
            createdAt: createdAt,
            locallyCreatedAt: nil,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            arguments: args,
            parentMessageId: parentId,
            showReplyInChannel: showReplyInChannel,
            replyCount: replyCount,
            extraData: extraData,
            quotedMessage: quotedMessage,
            isBounced: moderationDetails?.action == MessageModerationAction.bounce.rawValue,
            isSilent: isSilent,
            isShadowed: isShadowed,
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups.reduce(into: [:]) { acc, element in
                acc[element.key] = ChatMessageReactionGroup(
                    type: element.key,
                    sumScores: element.value.sumScores,
                    count: element.value.count,
                    firstReactionAt: element.value.firstReactionAt,
                    lastReactionAt: element.value.lastReactionAt
                )
            },
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            attachments: attachments,
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: latestReactions,
            currentUserReactions: currentUserReactions,
            isSentByCurrentUser: user.id == currentUserId,
            pinDetails: pinned ? MessagePinDetails(
                pinnedAt: pinnedAt ?? createdAt,
                pinnedBy: pinnedBy?.asModel() ?? author,
                expiresAt: pinExpires
            ) : nil,
            translations: translations,
            originalLanguage: originalLanguage.flatMap { TranslationLanguage(languageCode: $0) },
            moderationDetails: moderationDetails.map { .init(
                originalText: $0.originalText,
                action: .init(rawValue: $0.action),
                textHarms: $0.textHarms,
                imageHarms: $0.imageHarms,
                blocklistMatched: $0.blocklistMatched,
                semanticFilterMatched: $0.semanticFilterMatched,
                platformCircumvented: $0.platformCircumvented
            ) },
            readBy: Set(readBy.map(\.user)),
            poll: nil,
            textUpdatedAt: messageTextUpdatedAt,
            draftReply: nil,
            reminder: reminder.map {
                .init(
                    remindAt: $0.remindAt,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            sharedLocation: location.map {
                .init(
                    messageId: $0.messageId,
                    channelId: cid,
                    userId: $0.userId,
                    createdByDeviceId: $0.createdByDeviceId,
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    updatedAt: $0.updatedAt,
                    createdAt: $0.createdAt,
                    endAt: $0.endAt
                )
            }
        )
    }
}

extension MessageReactionPayload {
    /// Converts the MessageReactionPayload to a ChatMessageReaction model
    /// - Returns: A ChatMessageReaction instance
    func asModel(messageId: MessageId) -> ChatMessageReaction {
        ChatMessageReaction(
            id: [user.id, messageId, type.rawValue].joined(separator: "/"),
            type: type,
            score: score,
            createdAt: createdAt,
            updatedAt: updatedAt,
            author: user.asModel(),
            extraData: extraData
        )
    }
}
