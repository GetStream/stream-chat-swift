//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import CoreData.NSManagedObjectContext
@testable import StreamChat

public extension ChatMessage {
    /// Creates a new `ChatMessage` object from the provided data.
    static func mock(
        id: MessageId = .unique,
        cid: ChannelId = .unique,
        text: String = .unique,
        type: MessageType = .reply,
        author: ChatUser = .unique,
        command: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 113),
        locallyCreatedAt: Date? = nil,
        updatedAt: Date = Date(timeIntervalSince1970: 774),
        deletedAt: Date? = nil,
        arguments: String? = nil,
        parentMessageId: MessageId? = nil,
        quotedMessage: ChatMessage? = nil,
        showReplyInChannel: Bool = false,
        replyCount: Int = 0,
        extraData: [String: RawJSON] = [:],
        isBounced: Bool = false,
        isSilent: Bool = false,
        isShadowed: Bool = false,
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: TranslationLanguage? = nil,
        moderationsDetails: MessageModerationDetails? = nil,
        reactionScores: [MessageReactionType: Int] = [:],
        reactionCounts: [MessageReactionType: Int] = [:],
        reactionGroups: [MessageReactionType: ChatMessageReactionGroup] = [:],
        mentionedUsers: Set<ChatUser> = [],
        threadParticipants: [ChatUser] = [],
        threadParticipantsCount: Int = 0,
        attachments: [AnyChatMessageAttachment] = [],
        latestReplies: [ChatMessage] = [],
        localState: LocalMessageState? = nil,
        isFlaggedByCurrentUser: Bool = false,
        latestReactions: Set<ChatMessageReaction> = [],
        currentUserReactions: Set<ChatMessageReaction> = [],
        currentUserReactionsCount: Int = 0,
        isSentByCurrentUser: Bool = false,
        pinDetails: MessagePinDetails? = nil,
        readBy: Set<ChatUser> = [],
        underlyingContext: NSManagedObjectContext? = nil,
        textUpdatedAt: Date? = nil,
        poll: Poll? = nil,
        draftReply: DraftMessage? = nil,
        sharedLocation: SharedLocation? = nil
    ) -> Self {
        .init(
            id: id,
            cid: cid,
            text: text,
            type: type,
            command: command,
            createdAt: createdAt,
            locallyCreatedAt: locallyCreatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            arguments: arguments,
            parentMessageId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            replyCount: replyCount,
            extraData: extraData,
            quotedMessage: quotedMessage,
            isBounced: isBounced,
            isSilent: isSilent,
            isShadowed: isShadowed,
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            author: author,
            mentionedUsers: mentionedUsers,
            threadParticipants: threadParticipants,
            attachments: attachments,
            latestReplies: latestReplies,
            localState: localState,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            latestReactions: latestReactions,
            currentUserReactions: currentUserReactions,
            isSentByCurrentUser: isSentByCurrentUser,
            pinDetails: pinDetails,
            translations: translations,
            originalLanguage: originalLanguage,
            moderationDetails: moderationsDetails,
            readBy: readBy,
            poll: poll,
            textUpdatedAt: textUpdatedAt,
            draftReply: draftReply,
            sharedLocation: sharedLocation
        )
    }
}

extension MessageModerationDetails {
    static func mock(
        originalText: String,
        action: MessageModerationAction,
        textHarms: [String]? = nil,
        imageHarms: [String]? = nil,
        blocklistMatched: String? = nil,
        semanticFilterMatched: String? = nil,
        platformCircumvented: Bool? = nil
    ) -> Self {
        .init(
            originalText: originalText,
            action: action,
            textHarms: textHarms,
            imageHarms: imageHarms,
            blocklistMatched: blocklistMatched,
            semanticFilterMatched: semanticFilterMatched,
            platformCircumvented: platformCircumvented
        )
    }
}
