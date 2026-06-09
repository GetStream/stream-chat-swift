//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Attachment

extension Attachment {
    var attachmentType: AttachmentType {
        if ogScrapeUrl != nil {
            return .linkPreview
        }
        return type.map(AttachmentType.init(rawValue:)) ?? .unknown
    }

    static func make(type: AttachmentType, payload: RawJSON) -> Attachment {
        let attachment: Attachment
        if let data = try? JSONEncoder.default.encode(payload),
           let decoded = try? JSONDecoder.default.decode(Attachment.self, from: data) {
            attachment = decoded
        } else {
            var dict = payload.dictionaryValue ?? [:]
            dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
            attachment = Attachment(custom: dict)
        }
        attachment.type = type.rawValue
        return attachment
    }

    var payload: RawJSON {
        guard
            let data = try? JSONEncoder.default.encode(self),
            case var .dictionary(dict) = (try? JSONDecoder.default.decode(RawJSON.self, from: data)) ?? .dictionary([:])
        else {
            return .dictionary([:])
        }
        dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
        if case let .dictionary(customDict) = dict["custom"] ?? .dictionary([:]) {
            for (key, value) in customDict {
                dict[key] = value
            }
        }
        dict.removeValue(forKey: "custom")
        return .dictionary(dict)
    }
}

// MARK: - Channel

extension ChannelConfigWithInfo {
    var asChannelConfig: ChannelConfig {
        .init(
            reactionsEnabled: reactions,
            typingEventsEnabled: typingEvents,
            readEventsEnabled: readEvents,
            deliveryEventsEnabled: deliveryEvents,
            connectEventsEnabled: connectEvents,
            uploadsEnabled: uploads,
            repliesEnabled: replies,
            quotesEnabled: quotes,
            searchEnabled: search,
            mutesEnabled: mutes,
            pollsEnabled: polls,
            urlEnrichmentEnabled: urlEnrichment,
            skipLastMsgAtUpdateForSystemMsg: skipLastMsgUpdateForSystemMsgs,
            messageRemindersEnabled: userMessageReminders,
            sharedLocationsEnabled: sharedLocations,
            messageRetention: "",
            maxMessageLength: maxMessageLength,
            commands: commands.map { Command(name: $0.name, description: $0.description, set: $0.set, args: $0.args) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ChannelInput {
    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        self.init(
            custom: extraData.merging([
                "name": name.map(RawJSON.string),
                "image": imageURL.map { .string($0.absoluteString) }
            ].compactMapValues { $0 }, uniquingKeysWith: { $1 }).nilIfEmpty,
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: members.union(invites).isEmpty ? nil : members.union(invites).map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }
}

extension ChannelInputRequest {
    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: [String: RawJSON]
    ) {
        let allMembers = members.union(invites)
        self.init(
            custom: extraData.merging([
                "name": name.map(RawJSON.string),
                "image": imageURL.map { .string($0.absoluteString) }
            ].compactMapValues { $0 }, uniquingKeysWith: { $1 }).nilIfEmpty,
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: allMembers.isEmpty ? nil : allMembers.map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }
}

extension ChannelResponse {
    var channelId: ChannelId? { try? ChannelId(cid: cid) }

    /// The channel's custom data with the reserved `name` and `image` keys removed,
    /// since those are surfaced as dedicated `name`/`imageURL` properties.
    var extraData: [String: RawJSON] {
        var extraData = custom
        extraData["name"] = nil
        extraData["image"] = nil
        return extraData
    }

    var imageURL: URL? { custom["image"]?.stringValue.flatMap(URL.init(string:)) }
    var name: String? { custom["name"]?.stringValue }
}

extension ChannelStateResponse {
    var asChannelStateResponseFields: ChannelStateResponseFields {
        ChannelStateResponseFields(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

extension ChannelStateResponseFields {
    var asChannelStateResponse: ChannelStateResponse {
        ChannelStateResponse(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            duration: "",
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

// MARK: - Endpoint compatibility wrappers

//
// Factories below keep existing call sites small while delegating to generated
// OpenAPI endpoints wherever the operation and model shape match.

extension Endpoint {
    /// Channel query endpoint used by `ChannelRepository.getChannel` and the
    /// channel-already-exists hot path.
    static func channelQuery(_ query: ChannelQuery, requiresConnectionId: Bool? = nil) -> Endpoint<ChannelStateResponse> {
        let request = query.asChannelGetOrCreateRequest()
        return .init(
            path: query.id.map { .getOrCreateChannel(type: query.type.rawValue, id: $0) } ?? .getOrCreateDistinctChannel(type: query.type.rawValue),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId ?? query.options.contains(oneOf: [.presence, .state, .watch]),
            body: request
        )
    }

    /// Channel watcher list — uses channel query endpoint with a watcher-shaped query.
    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: query.cid.type.rawValue, id: query.cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: query
        )
    }

    /// Flag / unflag a message. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagMessage(_ flag: Bool, with messageId: MessageId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(custom: extraData, entityId: messageId, entityType: "message", reason: reason))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(custom: extraData, entityId: messageId, entityType: "message", reason: reason)
        )
    }

    /// Flag / unflag a user. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagUser(_ flag: Bool, with userId: UserId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(custom: extraData, entityId: userId, entityType: "user", reason: reason))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(custom: extraData, entityId: userId, entityType: "user", reason: reason)
        )
    }

    /// Loads the pinned messages of a channel. The OpenAPI spec does not expose
    /// a `pinned_messages` operation, so the path is built manually.
    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<MessageListPayload> {
        .init(
            path: .custom("channels/\(cid.apiPath)/pinned_messages"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }

    /// Unbans a channel member. The OpenAPI `ban` operation is POST-only;
    /// `DELETE /moderation/ban` has no generated factory yet.
    static func unbanMember(_ userId: UserId, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/ban"),
            method: .delete,
            queryItems: [
                "target_user_id": userId,
                "channel_cid": cid.rawValue
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    /// User unmute — OpenAPI only exposes channel unmute, so this endpoint
    /// remains custom until the user unmute operation is generated.
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/unmute"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }

    /// WebSocket connect endpoint. The OpenAPI spec exposes `longPoll` for the
    /// long-polling fallback, but the actual WebSocket establishment uses
    /// `?json=<payload>` on `/connect` with a hand-shaped auth body.
    static func webSocketConnect(userInfo: UserInfo) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WSAuthMessage(
                    products: nil,
                    token: "",
                    userDetails: ConnectUserDetailsRequest(
                        custom: userInfo.extraData,
                        id: userInfo.id,
                        image: userInfo.imageURL?.absoluteString,
                        invisible: userInfo.isInvisible,
                        language: userInfo.language?.languageCode,
                        name: userInfo.name,
                        privacySettings: userInfo.privacySettings.map(\.asPrivacySettingsResponse)
                    )
                )
            ]
        )
    }
}

// MARK: - Message

struct MessageListPayload: Decodable {
    let messages: [MessageResponse]
}

extension MessageResponse {
    /// The message translations, wrapped for convenient access.
    var translations: MessageTranslations? {
        i18n.map { MessageTranslations(i18n: $0) }
    }
}

extension MessageWithChannelResponse {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}

extension SearchResultMessage {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}

// MARK: - User

extension CreateGuestResponse {
    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}

extension FullUserResponse {
    func asOwnUserResponse() -> OwnUserResponse {
        OwnUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            channelMutes: channelMutes,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            devices: devices,
            id: id,
            image: image,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            latestHiddenChannels: latestHiddenChannels,
            mutes: mutes,
            name: name,
            online: online,
            privacySettings: privacySettings,
            pushPreferences: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: totalUnreadCount,
            unreadChannels: unreadChannels,
            unreadCount: unreadCount,
            unreadThreads: unreadThreads,
            updatedAt: updatedAt
        )
    }

    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

extension OwnUserResponse {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var unreadCountPayload: UnreadCountPayload? {
        UnreadCountPayload(
            channels: unreadChannels,
            messages: unreadCount,
            threads: unreadThreads >= 0 ? unreadThreads : nil
        )
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }
}

extension QueryUsersResponse {
    var userResponses: [UserResponse] {
        users.map { $0.asUserResponse() }
    }
}

extension UserPrivacySettings {
    var asPrivacySettingsResponse: PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) }
        )
    }
}

extension UserResponse {
    func asFullUserResponse() -> FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            devices: [],
            id: id,
            image: image,
            invisible: false,
            language: language,
            lastActive: lastActive,
            mutes: [],
            name: name,
            online: online,
            role: userRole.rawValue,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            updatedAt: updatedAt
        )
    }

    func asUserResponseCommonFields() -> UserResponseCommonFields {
        UserResponseCommonFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    func asUserResponsePrivacyFields() -> UserResponsePrivacyFields {
        UserResponsePrivacyFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            invisible: nil,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            privacySettings: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var teamsUserRole: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }
}

extension UserResponseCommonFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

extension UserResponsePrivacyFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}
