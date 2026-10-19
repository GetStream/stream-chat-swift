//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ScheduledMessageResponse {
    /// Builds the scheduled message model.
    ///
    /// The backend returns the user ids of the mentions, the id of the quoted message and the id of the poll,
    /// so they are resolved from the database when they are available there.
    func asModel(session: DatabaseSession) -> ScheduledMessage? {
        guard let channelId = try? ChannelId(cid: cid) else {
            log.error("Ignoring the scheduled message \(id), its channel id \(cid) is not valid")
            return nil
        }

        let author = ChatUser.make(payload: user)
        let mentionedUsers = Set((message.mentionedUsers ?? []).map { userId in
            session.user(id: userId).flatMap { try? $0.asModel() } ?? .placeholder(id: userId)
        })
        let quotedMessage = message.quotedMessageId.flatMap { session.message(id: $0) }.flatMap { try? $0.asModel() }
        let attachments = (message.attachments ?? []).enumerated().map { index, attachment in
            AnyChatMessageAttachment(
                id: AttachmentId(cid: channelId, messageId: id, index: index),
                type: attachment.attachmentType,
                payload: (try? JSONEncoder.default.encode(attachment.payload)) ?? Data(),
                downloadingState: nil,
                uploadingState: nil
            )
        }

        let poll = message.pollId.flatMap { try? session.poll(id: $0) }.flatMap { try? $0.asModel() }
        let sharedLocation = message.sharedLocation.flatMap { location -> SharedLocation? in
            guard let latitude = location.latitude, let longitude = location.longitude else { return nil }
            return SharedLocation(
                channelCid: channelId,
                createdAt: scheduledAt,
                createdByDeviceId: location.createdByDeviceId,
                endAt: location.endAt,
                latitude: latitude,
                longitude: longitude,
                messageId: id,
                updatedAt: updatedAt,
                userId: user.id
            )
        }

        let chatMessage = ChatMessage(
            id: id,
            cid: channelId,
            text: message.text,
            type: message.parentId == nil ? .regular : .reply,
            command: nil,
            createdAt: scheduledAt,
            locallyCreatedAt: nil,
            updatedAt: updatedAt,
            deletedAt: nil,
            arguments: nil,
            parentMessageId: message.parentId,
            showReplyInChannel: message.showInChannel ?? false,
            replyCount: 0,
            extraData: message.custom,
            quotedMessage: quotedMessage,
            isBounced: false,
            isSilent: message.silent ?? false,
            isShadowed: false,
            deletedForMe: false,
            reactionScores: [:],
            reactionCounts: [:],
            reactionGroups: [:],
            author: author,
            mentionedUsers: mentionedUsers,
            mentionedHere: message.mentionedHere ?? false,
            mentionedChannel: message.mentionedChannel ?? false,
            mentionedRoles: message.mentionedRoles ?? [],
            threadParticipants: [],
            attachments: attachments,
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: true,
            pinDetails: message.pinned == true ? MessagePinDetails(
                pinnedAt: scheduledAt,
                pinnedBy: author,
                expiresAt: message.pinExpires
            ) : nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: [],
            poll: poll,
            textUpdatedAt: nil,
            draftReply: nil,
            reminder: nil,
            sharedLocation: sharedLocation
        )

        return ScheduledMessage(
            id: id,
            cid: channelId,
            channel: channelSummary(channelId: channelId, session: session),
            message: chatMessage,
            quotedMessageId: message.quotedMessageId,
            scheduledAt: scheduledAt,
            status: ScheduledMessageStatus(rawValue: status),
            failureReason: failureReason.map(ScheduledMessageFailureReason.init(rawValue:)),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // The backend only returns the channel in query results, so the local one is used otherwise.
    private func channelSummary(channelId: ChannelId, session: DatabaseSession) -> ScheduledMessageChannel {
        if let channel {
            return ScheduledMessageChannel(cid: channelId, name: channel.name, imageURL: channel.image.flatMap(URL.init(string:)))
        }
        let localChannel = session.channel(cid: channelId)
        return ScheduledMessageChannel(cid: channelId, name: localChannel?.name, imageURL: localChannel?.imageURL)
    }
}

private extension ChatUser {
    static func make(payload: UserPayload) -> ChatUser {
        ChatUser(
            id: payload.id,
            name: payload.name,
            imageURL: payload.image.flatMap(URL.init(string:)),
            isOnline: payload.online,
            isBanned: payload.banned,
            isFlaggedByCurrentUser: false,
            userRole: UserRole(rawValue: payload.role),
            teamsRole: payload.teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            deactivatedAt: payload.deactivatedAt,
            lastActiveAt: payload.lastActive,
            teams: Set(payload.teams),
            language: payload.language.isEmpty ? nil : TranslationLanguage(languageCode: payload.language),
            avgResponseTime: payload.avgResponseTime,
            extraData: payload.custom
        )
    }

    static func placeholder(id: UserId) -> ChatUser {
        ChatUser(
            id: id,
            name: nil,
            imageURL: nil,
            isOnline: false,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )
    }
}
