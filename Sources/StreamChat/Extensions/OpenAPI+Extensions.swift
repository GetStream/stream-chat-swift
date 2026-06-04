//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserResponseCommonFields {
    convenience init(_ user: UserResponse) {
        self.init(
            avgResponseTime: user.avgResponseTime,
            banned: user.banned,
            blockedUserIds: user.blockedUserIds,
            createdAt: user.createdAt,
            custom: user.custom,
            deactivatedAt: user.deactivatedAt,
            deletedAt: user.deletedAt,
            id: user.id,
            image: user.image,
            language: user.language,
            lastActive: user.lastActive,
            name: user.name,
            online: user.online,
            revokeTokensIssuedBefore: user.revokeTokensIssuedBefore,
            role: user.role,
            teams: user.teams,
            teamsRole: user.teamsRole,
            updatedAt: user.updatedAt
        )
    }
}

extension UserResponsePrivacyFields {
    convenience init(_ user: UserResponse) {
        self.init(
            avgResponseTime: user.avgResponseTime,
            banned: user.banned,
            blockedUserIds: user.blockedUserIds,
            createdAt: user.createdAt,
            custom: user.custom,
            deactivatedAt: user.deactivatedAt,
            deletedAt: user.deletedAt,
            id: user.id,
            image: user.image,
            invisible: nil,
            language: user.language,
            lastActive: user.lastActive,
            name: user.name,
            online: user.online,
            privacySettings: nil,
            revokeTokensIssuedBefore: user.revokeTokensIssuedBefore,
            role: user.role,
            teams: user.teams,
            teamsRole: user.teamsRole,
            updatedAt: user.updatedAt
        )
    }
}

extension UserResponse {
    convenience init(_ user: UserResponseCommonFields) {
        self.init(
            avgResponseTime: user.avgResponseTime,
            banned: user.banned,
            blockedUserIds: user.blockedUserIds,
            createdAt: user.createdAt,
            custom: user.custom,
            deactivatedAt: user.deactivatedAt,
            deletedAt: user.deletedAt,
            id: user.id,
            image: user.image,
            language: user.language,
            lastActive: user.lastActive,
            name: user.name,
            online: user.online,
            revokeTokensIssuedBefore: user.revokeTokensIssuedBefore,
            role: user.role,
            teams: user.teams,
            teamsRole: user.teamsRole,
            updatedAt: user.updatedAt
        )
    }

    convenience init(_ user: UserResponsePrivacyFields) {
        self.init(
            avgResponseTime: user.avgResponseTime,
            banned: user.banned,
            blockedUserIds: user.blockedUserIds,
            createdAt: user.createdAt,
            custom: user.custom,
            deactivatedAt: user.deactivatedAt,
            deletedAt: user.deletedAt,
            id: user.id,
            image: user.image,
            language: user.language,
            lastActive: user.lastActive,
            name: user.name,
            online: user.online,
            revokeTokensIssuedBefore: user.revokeTokensIssuedBefore,
            role: user.role,
            teams: user.teams,
            teamsRole: user.teamsRole,
            updatedAt: user.updatedAt
        )
    }
}

struct MessageListPayload: Decodable {
    let messages: [MessageResponse]
}

enum UserPayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case name
    case imageURL = "image"
    case role
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deactivatedAt = "deactivated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case unreadThreads = "unread_threads"
    case mutedUsers = "mutes"
    case mutedChannels = "channel_mutes"
    case isAnonymous = "anon"
    case devices
    case unreadCount = "unread_count"
    case language
    case privacySettings = "privacy_settings"
    case blockedUserIds = "blocked_user_ids"
    case teamsRole = "teams_role"
    case avgResponseTime = "avg_response_time"
    case pushPreference = "push_preferences"
}

private enum MessageTranslationsPayloadKeys {
    static let originalLanguage = "language"
    static let translatedSuffix = "_text"
}

extension Dictionary where Key == String, Value == String {
    var originalLanguage: String? {
        self[MessageTranslationsPayloadKeys.originalLanguage]
    }

    var translated: [TranslationLanguage: String] {
        reduce(into: [:]) { translatedDictionary, keyValuePair in
            let key = keyValuePair.key
            guard key != MessageTranslationsPayloadKeys.originalLanguage else { return }
            guard let suffixRange = key.range(of: MessageTranslationsPayloadKeys.translatedSuffix) else {
                log.warning("Unknown key in `translate` response: \(key), cannot decode", subsystems: .httpRequests)
                return
            }

            let languageCode = String(key.prefix(upTo: suffixRange.lowerBound))
            translatedDictionary[TranslationLanguage(languageCode: languageCode)] = keyValuePair.value
        }
    }

    static func messageTranslations(
        translations: [TranslationLanguage: String]?,
        originalLanguage: String?
    ) -> [String: String]? {
        guard translations != nil || originalLanguage != nil else { return nil }

        var i18n = originalLanguage.map { [MessageTranslationsPayloadKeys.originalLanguage: $0] } ?? [:]
        translations?.forEach {
            i18n[$0.key.languageCode + MessageTranslationsPayloadKeys.translatedSuffix] = $0.value
        }
        return i18n
    }
}

extension UploadChannelResponse {
    var fileURL: URL {
        URL(string: file ?? "")!
    }

    var thumbURL: URL? {
        thumbUrl.flatMap(URL.init(string:))
    }

    convenience init(fileURL: URL, thumbURL: URL?) {
        self.init(duration: "", file: fileURL.absoluteString, thumbUrl: thumbURL?.absoluteString)
    }
}

extension DeviceResponse {
    convenience init(id: DeviceId, createdAt: Date? = .init()) {
        self.init(
            createdAt: createdAt ?? Date(timeIntervalSince1970: 0),
            id: id,
            pushProvider: "",
            userId: ""
        )
    }
}

extension ListDevicesResponse {
    convenience init(devices: [DeviceResponse]) {
        self.init(devices: devices, duration: "")
    }
}

extension MembersResponse {
    convenience init(members: [ChannelMemberResponse]) {
        self.init(duration: "", members: members)
    }
}

extension ChannelMemberResponse {
    var userPayload: UserResponse? {
        user?.asUserPayload
    }

    var resolvedUserId: UserId {
        userPayload?.id ?? userId ?? ""
    }

    var memberRole: MemberRole? {
        MemberRole(rawChannelValue: channelRole)
    }

    var banExpiresAt: Date? {
        banExpires
    }

    var isBanned: Bool? {
        banned
    }

    var isShadowBanned: Bool? {
        shadowBanned
    }

    var isInvited: Bool? {
        invited
    }

    var extraData: [String: RawJSON]? {
        custom
    }

    convenience init(
        user: UserResponse?,
        userId: String,
        role: MemberRole?,
        createdAt: Date,
        updatedAt: Date,
        banExpiresAt: Date? = nil,
        isBanned: Bool? = nil,
        isShadowBanned: Bool? = nil,
        isInvited: Bool? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil,
        notificationsMuted: Bool = false,
        extraData: [String: RawJSON]? = nil
    ) {
        self.init(
            archivedAt: archivedAt,
            banExpires: banExpiresAt,
            banned: isBanned ?? false,
            channelRole: role?.rawChannelValue ?? MemberRole.member.rawChannelValue,
            createdAt: createdAt,
            custom: extraData ?? [:],
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            invited: isInvited,
            notificationsMuted: notificationsMuted,
            pinnedAt: pinnedAt,
            role: role?.rawValue,
            shadowBanned: isShadowBanned ?? false,
            updatedAt: updatedAt,
            user: user?.asUserResponse,
            userId: user?.id ?? userId
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
            custom: Self.customData(name: name, imageURL: imageURL, extraData: extraData),
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: members.union(invites).isEmpty ? nil : members.union(invites).map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }

    var name: String? {
        custom?["name"]?.stringValue
    }

    var imageURL: URL? {
        custom?["image"]?.stringValue.flatMap(URL.init(string:))
    }

    var extraData: [String: RawJSON] {
        var extraData = custom ?? [:]
        extraData["name"] = nil
        extraData["image"] = nil
        return extraData
    }

    private static func customData(name: String?, imageURL: URL?, extraData: [String: RawJSON]) -> [String: RawJSON]? {
        var custom = extraData
        if let name {
            custom["name"] = .string(name)
        }
        if let imageURL {
            custom["image"] = .string(imageURL.absoluteString)
        }
        return custom.isEmpty ? nil : custom
    }
}

extension FlagResponse {
    var flaggedMessageId: MessageId {
        itemId
    }
}

extension UserMuteResponse {
    var mutedUser: UserResponse {
        target?.asUserPayload ?? UserResponse(
            id: "",
            name: nil,
            imageURL: nil,
            role: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            isOnline: false,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:]
        )
    }

    var created: Date {
        createdAt
    }

    var updated: Date {
        updatedAt
    }

    convenience init(mutedUser: UserResponse, created: Date, updated: Date) {
        self.init(createdAt: created, target: mutedUser.asUserResponse, updatedAt: updated)
    }
}

extension MuteResponse {
    var mutedUser: UserMuteResponse {
        mutes?.first ?? UserMuteResponse(
            createdAt: Date(timeIntervalSince1970: 0),
            target: nil,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    var currentUser: OwnUserResponse {
        ownUser?.asOwnUserResponse ?? UserResponse(
            id: "",
            name: nil,
            imageURL: nil,
            role: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            isOnline: false,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:]
        ).asOwnUserResponse
    }
}

extension OwnUserResponse {
    var asOwnUserResponse: OwnUserResponse {
        self
    }

    var asUserPayload: UserResponse {
        UserResponse(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRolePayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }

    var asFullUserResponse: FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            blockedUserIds: blockedUserIds ?? [],
            channelMutes: channelMutes,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: id,
            image: image,
            invisible: isInvisible,
            language: language,
            lastActive: lastActive,
            mutes: mutes,
            name: name,
            online: isOnline,
            privacySettings: privacySettings,
            role: role,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: totalUnreadCount,
            unreadChannels: unreadChannels,
            unreadCount: unreadCount,
            unreadThreads: unreadThreads,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsRolePayload: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var lastActiveAt: Date? {
        lastActive
    }

    var isOnline: Bool {
        online
    }

    var isInvisible: Bool {
        invisible
    }

    var isBanned: Bool {
        banned
    }

    var extraData: [String: RawJSON] {
        custom
    }

    var mutedUsers: [UserMuteResponse] {
        mutes
    }

    var mutedChannels: [ChannelMute] {
        channelMutes
    }

    var unreadCountPayload: UnreadCountPayload? {
        UnreadCountPayload(
            channels: unreadChannels,
            messages: unreadCount,
            threads: unreadThreads >= 0 ? unreadThreads : nil
        )
    }

    var blockedUserIdsSet: Set<UserId> {
        Set(blockedUserIds ?? [])
    }

    var pushPreference: PushPreferencesResponse? {
        pushPreferences
    }

    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        extraData: [String: RawJSON],
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        mutedChannels: [ChannelMute] = [],
        unreadCount: UnreadCountPayload? = nil,
        privacySettings: UserPrivacySettingsPayload? = nil,
        blockedUserIds: Set<UserId> = [],
        pushPreference: PushPreferencesResponse?
    ) {
        self.init(
            avgResponseTime: nil,
            banned: isBanned,
            blockedUserIds: Array(blockedUserIds),
            channelMutes: mutedChannels,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: id,
            image: imageURL?.absoluteString,
            invisible: isInvisible,
            language: language ?? "",
            lastActive: lastActiveAt,
            mutes: mutedUsers,
            name: name,
            online: isOnline,
            privacySettings: privacySettings?.asPrivacySettingsResponse,
            pushPreferences: pushPreference,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadCount: unreadCount?.messages ?? 0,
            unreadThreads: unreadCount?.threads ?? -1,
            updatedAt: updatedAt
        )
    }
}

extension UserPrivacySettingsPayload {
    var asPrivacySettingsResponse: PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) }
        )
    }
}

extension MuteChannelResponse {
    var primaryChannelMute: ChannelMute? {
        channelMute ?? channelMutes?.first
    }

    convenience init(channelMute: ChannelMute, channelMutes: [ChannelMute]? = nil, ownUser: OwnUserResponse? = nil) {
        self.init(channelMute: channelMute, channelMutes: channelMutes, duration: "", ownUser: ownUser)
    }
}

extension ChannelMute {
    var channelPayload: ChannelResponse? {
        channel?.asChannelResponse
    }

    var userPayload: UserResponse? {
        user?.asUserPayload
    }

    var expiresAt: Date? {
        expires
    }

    convenience init(
        mutedChannel: ChannelResponse,
        user: UserResponse,
        createdAt: Date,
        updatedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.init(
            channel: mutedChannel.asChannelResponse,
            createdAt: createdAt,
            expires: expiresAt,
            updatedAt: updatedAt,
            user: user.asUserResponse
        )
    }

    convenience init(
        mutedChannel: ChannelResponse,
        user: OwnUserResponse,
        createdAt: Date,
        updatedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.init(
            mutedChannel: mutedChannel,
            user: user.asUserPayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt
        )
    }
}

extension PrivacySettingsResponse {
    var asUserPrivacySettingsPayload: UserPrivacySettingsPayload {
        UserPrivacySettingsPayload(
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) }
        )
    }
}

extension QueryDraftsResponse {
    convenience init(drafts: [DraftResponse], next: String? = nil) {
        self.init(drafts: drafts, duration: "", next: next)
    }
}

extension GetDraftResponse {
    convenience init(draft: DraftResponse) {
        self.init(draft: draft, duration: "")
    }
}

extension DraftResponse {
    var cid: ChannelId? {
        try? ChannelId(cid: channelCid)
    }

    var channelPayload: ChannelResponse? {
        channel?.asChannelResponse
    }

    convenience init(
        cid: ChannelId?,
        channelPayload: ChannelResponse?,
        createdAt: Date,
        message: DraftPayloadResponse,
        quotedMessage: MessageResponse?,
        parentId: String?,
        parentMessage: MessageResponse?
    ) {
        self.init(
            channel: channelPayload?.asChannelResponse,
            channelCid: cid?.rawValue ?? channelPayload?.cid ?? "",
            createdAt: createdAt,
            message: message,
            parentId: parentId,
            parentMessage: parentMessage?.asMessageResponse,
            quotedMessage: quotedMessage?.asMessageResponse
        )
    }
}

extension DraftPayloadResponse {
    var command: String? {
        nil
    }

    var args: String? {
        nil
    }

    var showReplyInChannel: Bool {
        showInChannel ?? false
    }

    var isSilent: Bool {
        silent ?? false
    }

    var mentionedUsersPayload: [UserResponse]? {
        mentionedUsers?.map(\.asUserPayload)
    }

    var extraData: [String: RawJSON] {
        custom
    }

    var attachmentPayloads: [Attachment]? {
        attachments
    }

    convenience init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        showReplyInChannel: Bool,
        mentionedUsers: [UserResponse]?,
        extraData: [String: RawJSON],
        attachments: [Attachment]?,
        isSilent: Bool
    ) {
        self.init(
            attachments: attachments,
            custom: extraData,
            id: id,
            mentionedUsers: mentionedUsers?.map(\.asUserResponse),
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
    }
}

extension CreateDraftRequest {
    convenience init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        parentId: String?,
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: String?,
        attachments: [Attachment],
        mentionedUserIds: [UserId],
        extraData: [String: RawJSON]
    ) {
        let message = MessageRequest(
            attachments: attachments.isEmpty ? nil : attachments,
            custom: extraData.isEmpty ? nil : extraData,
            id: id,
            mentionedUsers: mentionedUserIds.isEmpty ? nil : mentionedUserIds,
            parentId: parentId,
            quotedMessageId: quotedMessageId,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
        if let command {
            message.custom = (message.custom ?? [:]).merging(["command": .string(command)]) { _, new in new }
        }
        if let args {
            message.custom = (message.custom ?? [:]).merging(["args": .string(args)]) { _, new in new }
        }
        self.init(message: message)
    }
}

extension ReadStateResponse {
    var lastReadAt: Date {
        lastRead
    }

    var unreadMessagesCount: Int {
        unreadMessages
    }

    convenience init(
        user: UserResponse,
        lastReadAt: Date,
        lastReadMessageId: MessageId? = nil,
        unreadMessagesCount: Int,
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: MessageId? = nil
    ) {
        self.init(
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId,
            lastRead: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessages: unreadMessagesCount,
            user: user.asUserResponse
        )
    }

    convenience init(
        user: OwnUserResponse,
        lastReadAt: Date,
        lastReadMessageId: MessageId? = nil,
        unreadMessagesCount: Int,
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: MessageId? = nil
    ) {
        self.init(
            user: user.asUserPayload,
            lastReadAt: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessagesCount: unreadMessagesCount,
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId
        )
    }
}

extension WrappedUnreadCountsResponse {
    convenience init(
        totalUnreadCount: Int,
        totalUnreadThreadsCount: Int,
        totalUnreadCountByTeam: [TeamId: Int]?,
        channels: [UnreadCountsChannel],
        channelType: [UnreadCountsChannelType],
        threads: [UnreadCountsThread]
    ) {
        self.init(
            channelType: channelType,
            channels: channels,
            duration: "",
            threads: threads,
            totalUnreadCount: totalUnreadCount,
            totalUnreadCountByTeam: totalUnreadCountByTeam,
            totalUnreadThreadsCount: totalUnreadThreadsCount
        )
    }
}

extension UnreadCountsChannel {
    var channelIdValue: ChannelId {
        (try? ChannelId(cid: channelId)) ?? ChannelId(type: .messaging, id: channelId)
    }

    convenience init(channelId: ChannelId, unreadCount: Int, lastRead: Date?) {
        self.init(
            channelId: channelId.rawValue,
            lastRead: lastRead ?? Date(timeIntervalSince1970: 0),
            unreadCount: unreadCount
        )
    }
}

extension UnreadCountsChannelType {
    var channelTypeValue: ChannelType {
        ChannelType(rawValue: channelType)
    }

    convenience init(channelType: ChannelType, channelCount: Int, unreadCount: Int) {
        self.init(channelCount: channelCount, channelType: channelType.rawValue, unreadCount: unreadCount)
    }
}

extension UnreadCountsThread {
    convenience init(parentMessageId: MessageId, lastRead: Date?, lastReadMessageId: MessageId?, unreadCount: Int) {
        self.init(
            lastRead: lastRead ?? Date(timeIntervalSince1970: 0),
            lastReadMessageId: lastReadMessageId ?? "",
            parentMessageId: parentMessageId,
            unreadCount: unreadCount
        )
    }
}

extension ReactionGroupResponse {
    convenience init(
        sumScores: Int,
        count: Int,
        firstReactionAt: Date,
        lastReactionAt: Date
    ) {
        self.init(
            count: count,
            firstReactionAt: firstReactionAt,
            lastReactionAt: lastReactionAt,
            latestReactionsBy: [],
            sumScores: sumScores
        )
    }
}

extension DeliveredMessagePayload {
    convenience init(cid: ChannelId, id: MessageId) {
        self.init(cid: cid.rawValue, id: id)
    }
}

extension UpdateMemberPartialRequest {
    enum MemberUpdateField: String, CaseIterable {
        case archived
        case pinned
    }

    var archived: Bool? {
        self.set?[MemberUpdateField.archived.rawValue]?.boolValue
    }

    var pinned: Bool? {
        self.set?[MemberUpdateField.pinned.rawValue]?.boolValue
    }

    var extraData: [String: RawJSON]? {
        guard var extraData = self.set else { return nil }
        MemberUpdateField.allCases.forEach { extraData[$0.rawValue] = nil }
        return extraData.isEmpty ? nil : extraData
    }

    convenience init(
        archived: Bool? = nil,
        pinned: Bool? = nil,
        extraData: [String: RawJSON]? = nil
    ) {
        var set = extraData ?? [:]
        if let archived {
            set[MemberUpdateField.archived.rawValue] = .bool(archived)
        }
        if let pinned {
            set[MemberUpdateField.pinned.rawValue] = .bool(pinned)
        }
        self.init(set: set.isEmpty ? nil : set)
    }
}

extension ModerationV2Response {
    convenience init(
        originalText: String,
        action: String,
        textHarms: [String]?,
        imageHarms: [String]?,
        blocklistMatched: String?,
        semanticFilterMatched: String?,
        platformCircumvented: Bool?
    ) {
        self.init(
            action: action,
            blocklistMatched: blocklistMatched,
            imageHarms: imageHarms,
            originalText: originalText,
            platformCircumvented: platformCircumvented,
            semanticFilterMatched: semanticFilterMatched,
            textHarms: textHarms
        )
    }
}

extension CreateGuestResponse {
    convenience init(user: OwnUserResponse, token: Token) {
        let userResponse = user.asUserPayload.asUserResponse
        userResponse.id = token.userId
        self.init(accessToken: token.rawValue, duration: "", user: userResponse)
    }

    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}

extension UserResponse {
    var asUserPayload: UserResponse {
        self
    }

    var asUserResponse: UserResponse {
        self
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsRolePayload: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var lastActiveAt: Date? {
        lastActive
    }

    var isOnline: Bool {
        online
    }

    var isInvisible: Bool {
        false
    }

    var isBanned: Bool {
        banned
    }

    var extraData: [String: RawJSON] {
        custom
    }

    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        avgResponseTime: Int? = nil,
        extraData: [String: RawJSON]
    ) {
        self.init(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language ?? "",
            lastActive: lastActiveAt,
            name: name,
            online: isOnline,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            updatedAt: updatedAt
        )
    }
}

extension FullUserResponse {
    var asUserPayload: UserResponse {
        UserResponse(
            id: id,
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            role: UserRole(rawValue: role),
            teamsRole: teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            isOnline: online,
            isInvisible: false,
            isBanned: banned,
            teams: teams,
            language: language,
            avgResponseTime: avgResponseTime,
            extraData: custom
        )
    }

    var asOwnUserResponse: OwnUserResponse {
        OwnUserResponse(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRolePayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            extraData: extraData,
            devices: devices,
            mutedUsers: mutes,
            mutedChannels: channelMutes,
            unreadCount: .init(channels: unreadChannels, messages: unreadCount, threads: unreadThreads),
            privacySettings: privacySettings?.asUserPrivacySettingsPayload,
            blockedUserIds: Set(blockedUserIds),
            pushPreference: nil
        )
    }

    var asUserResponse: UserResponse {
        asUserPayload
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsRolePayload: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var lastActiveAt: Date? {
        lastActive
    }

    var isOnline: Bool {
        online
    }

    var isInvisible: Bool {
        invisible
    }

    var isBanned: Bool {
        banned
    }

    var extraData: [String: RawJSON] {
        custom
    }
}

extension QueryUsersResponse {
    var userPayloads: [UserResponse] {
        users.map(\.asUserPayload)
    }

    convenience init(users: [UserResponse]) {
        self.init(duration: "", users: users.map(\.asFullUserResponse))
    }
}

extension UserRequest {
    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var extraData: [String: RawJSON] {
        custom ?? [:]
    }

    convenience init(id: String, name: String?, imageURL: URL?, extraData: [String: RawJSON]) {
        self.init(custom: extraData, id: id, image: imageURL?.absoluteString, name: name)
    }
}

extension UpdateUserPartialRequest {
    var name: String? {
        self.set?["name"]?.stringValue
    }

    var imageURL: URL? {
        self.set?["image"]?.stringValue.flatMap(URL.init(string:))
    }

    var privacySettings: UserPrivacySettingsPayload? {
        guard let value = self.set?["privacy_settings"],
              let data = try? JSONEncoder.default.encode(value),
              let response = try? JSONDecoder.default.decode(PrivacySettingsResponse.self, from: data) else {
            return nil
        }
        return response.asUserPrivacySettingsPayload
    }

    var role: UserRole? {
        self.set?["role"]?.stringValue.map(UserRole.init(rawValue:))
    }

    var teamsRole: [TeamId: UserRole]? {
        guard let value = self.set?["teams_role"],
              let data = try? JSONEncoder.default.encode(value),
              let raw = try? JSONDecoder.default.decode([String: String].self, from: data) else {
            return nil
        }
        return raw.mapValues { UserRole(rawValue: $0) }
    }

    var extraData: [String: RawJSON]? {
        let reservedKeys = ["name", "image", "privacy_settings", "role", "teams_role"]
        let customData = (self.set ?? [:]).removingValues(forKeys: reservedKeys)
        return customData.isEmpty ? nil : customData
    }

    convenience init(
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettingsPayload?,
        role: UserRole?,
        teamsRole: [TeamId: UserRole]?,
        extraData: [String: RawJSON]?
    ) {
        var set = extraData ?? [:]
        if let name {
            set["name"] = .string(name)
        }
        if let imageURL {
            set["image"] = .string(imageURL.absoluteString)
        }
        if let privacySettings {
            set["privacy_settings"] = privacySettings.asPrivacySettingsResponse.rawJSON
        }
        if let role {
            set["role"] = .string(role.rawValue)
        }
        if let teamsRole {
            set["teams_role"] = teamsRole.mapValues(\.rawValue).rawJSON
        }
        self.init(id: "", set: set.isEmpty ? nil : set, unset: nil)
    }
}

extension UpdateUsersResponse {
    var user: OwnUserResponse {
        (try? validatedUser()) ?? UserResponse.empty.asOwnUserResponse
    }

    convenience init(user: OwnUserResponse) {
        self.init(duration: "", membershipDeletionTaskId: "", users: [user.id: user.asFullUserResponse])
    }

    func validatedUser() throws -> OwnUserResponse {
        guard let user = users.first?.value else {
            throw ClientError.Unexpected("Missing updated user.")
        }
        return user.asOwnUserResponse
    }
}

private extension Encodable {
    var rawJSON: RawJSON? {
        guard let data = try? JSONEncoder.default.encode(self) else { return nil }
        return try? JSONDecoder.default.decode(RawJSON.self, from: data)
    }
}

extension UserResponse {
    var asFullUserResponse: FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: [],
            id: id,
            image: imageURL?.absoluteString,
            invisible: isInvisible,
            language: language,
            lastActive: lastActiveAt,
            mutes: [],
            name: name,
            online: isOnline,
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
}

extension ChannelResponse {
    // Compatibility shims for callers written against the legacy channel detail payload class.
    var name: String? { custom["name"]?.stringValue }
    var imageURL: URL? { custom["image"]?.stringValue.flatMap(URL.init(string:)) }
    var extraData: [String: RawJSON] {
        var c = custom
        c["name"] = nil
        c["image"] = nil
        return c
    }

    var typeRawValue: String { type }
    var isDisabled: Bool { disabled }
    var isFrozen: Bool { frozen }
    var isBlocked: Bool? { blocked }
    var isHidden: Bool? { hidden }
    var cooldownDuration: Int { cooldown ?? 0 }
    var channelId: ChannelId? { try? ChannelId(cid: cid) }
    var asChannelResponse: ChannelResponse { self }
}

extension ChannelStateResponseFields {
    // Compatibility shims for the legacy ChannelStateResponseFields struct.
    var channelReads: [ReadStateResponse] { read ?? [] }
    var newestMessage: MessageResponse? {
        guard let first = messages.first, let last = messages.last else { return nil }
        return first.createdAt > last.createdAt ? first : last
    }
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
            commands: commands.map(\.asCommand),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ChannelConfig {
    var asChannelConfigWithInfo: ChannelConfigWithInfo {
        .init(
            automod: .unknown,
            automodBehavior: .unknown,
            commands: commands.map(\.asCommandOpenAPI),
            connectEvents: connectEventsEnabled,
            countMessages: false,
            createdAt: createdAt,
            customEvents: false,
            deliveryEvents: deliveryEventsEnabled,
            markMessagesPending: false,
            maxMessageLength: maxMessageLength,
            mutes: mutesEnabled,
            name: "",
            polls: pollsEnabled,
            pushNotifications: false,
            quotes: quotesEnabled,
            reactions: reactionsEnabled,
            readEvents: readEventsEnabled,
            reminders: messageRemindersEnabled,
            replies: repliesEnabled,
            search: searchEnabled,
            sharedLocations: sharedLocationsEnabled,
            skipLastMsgUpdateForSystemMsgs: skipLastMsgAtUpdateForSystemMsg,
            typingEvents: typingEventsEnabled,
            updatedAt: updatedAt,
            uploads: uploadsEnabled,
            urlEnrichment: urlEnrichmentEnabled,
            userMessageReminders: messageRemindersEnabled
        )
    }
}

extension CommandPayload {
    var asCommand: Command {
        .init(name: name, description: description, set: set, args: args)
    }
}

extension Command {
    var asCommandOpenAPI: CommandPayload {
        .init(args: args, description: description, name: name, set: set)
    }
}

extension MessageResponse {
    /// Custom-data key under which the originating campaign id is stored.
    static let campaignIdCustomKey = "created_by_campaign_id"

    var asMessagePayload: MessageResponse { self }
    var asMessageResponse: MessageResponse { self }

    // Compatibility shims for callers written against the legacy MessageResponse class.
    var extraData: [String: RawJSON] {
        get { custom }
        set { custom = newValue }
    }

    var isSilent: Bool { silent }
    var isShadowed: Bool { shadowed }
    var showReplyInChannel: Bool { showInChannel ?? false }
    var args: String? { nil }
    var location: SharedLocationResponseData? { sharedLocation }
    var moderationDetails: ModerationV2Response? { nil }
    var channel: ChannelResponse? { nil }
    var translations: [TranslationLanguage: String]? { i18n?.translated }
    var originalLanguage: String? { i18n?.originalLanguage }
    var campaignId: String? {
        if case let .string(value) = custom[Self.campaignIdCustomKey] {
            return value
        }
        return nil
    }
}

extension MessageWithChannelResponse {
    convenience init(messageResponse: MessageResponse, channel: ChannelResponse) {
        self.init(
            attachments: messageResponse.attachments,
            channel: channel,
            cid: messageResponse.cid,
            command: messageResponse.command,
            createdAt: messageResponse.createdAt,
            custom: messageResponse.custom,
            deletedAt: messageResponse.deletedAt,
            deletedForMe: messageResponse.deletedForMe,
            deletedReplyCount: messageResponse.deletedReplyCount,
            draft: messageResponse.draft,
            html: messageResponse.html,
            i18n: messageResponse.i18n,
            id: messageResponse.id,
            imageLabels: messageResponse.imageLabels,
            latestReactions: messageResponse.latestReactions,
            member: messageResponse.member,
            mentionedChannel: messageResponse.mentionedChannel,
            mentionedGroupIds: messageResponse.mentionedGroupIds,
            mentionedHere: messageResponse.mentionedHere,
            mentionedRoles: messageResponse.mentionedRoles,
            mentionedUsers: messageResponse.mentionedUsers,
            messageTextUpdatedAt: messageResponse.messageTextUpdatedAt,
            mml: messageResponse.mml,
            moderation: messageResponse.moderation,
            ownReactions: messageResponse.ownReactions,
            parentId: messageResponse.parentId,
            pinExpires: messageResponse.pinExpires,
            pinned: messageResponse.pinned,
            pinnedAt: messageResponse.pinnedAt,
            pinnedBy: messageResponse.pinnedBy,
            poll: messageResponse.poll,
            pollId: messageResponse.pollId,
            quotedMessage: messageResponse.quotedMessage,
            quotedMessageId: messageResponse.quotedMessageId,
            reactionCounts: messageResponse.reactionCounts,
            reactionGroups: messageResponse.reactionGroups,
            reactionScores: messageResponse.reactionScores,
            reminder: messageResponse.reminder,
            replyCount: messageResponse.replyCount,
            restrictedVisibility: messageResponse.restrictedVisibility,
            shadowed: messageResponse.shadowed,
            sharedLocation: messageResponse.sharedLocation,
            showInChannel: messageResponse.showInChannel,
            silent: messageResponse.silent,
            text: messageResponse.text,
            threadParticipants: messageResponse.threadParticipants,
            type: messageResponse.type,
            updatedAt: messageResponse.updatedAt,
            user: messageResponse.user
        )
    }

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

extension GetMessageResponse {
    var asMessageResponse: MessageResponse { message.asMessageResponse }
}

extension SendMessageResponsePayload {
    var asMessageResponse: MessageResponse { message }
}

extension DeleteMessageResponse {
    var asMessageResponse: MessageResponse { message }
}

extension UpdateMessagePartialResponse {
    var asMessageResponse: MessageResponse? { message }
}

extension MessageActionResponse {
    var asMessageResponse: MessageResponse? { message }
}

extension SearchResultMessage {
    convenience init(messageResponse: MessageResponse, channel: ChannelResponse? = nil) {
        self.init(
            attachments: messageResponse.attachments,
            channel: channel,
            cid: messageResponse.cid,
            command: messageResponse.command,
            createdAt: messageResponse.createdAt,
            custom: messageResponse.custom,
            deletedAt: messageResponse.deletedAt,
            deletedForMe: messageResponse.deletedForMe,
            deletedReplyCount: messageResponse.deletedReplyCount,
            draft: messageResponse.draft,
            html: messageResponse.html,
            i18n: messageResponse.i18n,
            id: messageResponse.id,
            imageLabels: messageResponse.imageLabels,
            latestReactions: messageResponse.latestReactions,
            member: messageResponse.member,
            mentionedChannel: messageResponse.mentionedChannel,
            mentionedGroupIds: messageResponse.mentionedGroupIds,
            mentionedHere: messageResponse.mentionedHere,
            mentionedRoles: messageResponse.mentionedRoles,
            mentionedUsers: messageResponse.mentionedUsers,
            messageTextUpdatedAt: messageResponse.messageTextUpdatedAt,
            mml: messageResponse.mml,
            moderation: messageResponse.moderation,
            ownReactions: messageResponse.ownReactions,
            parentId: messageResponse.parentId,
            pinExpires: messageResponse.pinExpires,
            pinned: messageResponse.pinned,
            pinnedAt: messageResponse.pinnedAt,
            pinnedBy: messageResponse.pinnedBy,
            poll: messageResponse.poll,
            pollId: messageResponse.pollId,
            quotedMessage: messageResponse.quotedMessage,
            quotedMessageId: messageResponse.quotedMessageId,
            reactionCounts: messageResponse.reactionCounts,
            reactionGroups: messageResponse.reactionGroups,
            reactionScores: messageResponse.reactionScores,
            reminder: messageResponse.reminder,
            replyCount: messageResponse.replyCount,
            restrictedVisibility: messageResponse.restrictedVisibility,
            shadowed: messageResponse.shadowed,
            sharedLocation: messageResponse.sharedLocation,
            showInChannel: messageResponse.showInChannel,
            silent: messageResponse.silent,
            text: messageResponse.text,
            threadParticipants: messageResponse.threadParticipants,
            type: messageResponse.type,
            updatedAt: messageResponse.updatedAt,
            user: messageResponse.user
        )
    }

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

extension SharedLocationResponseData {
    var channelId: String {
        channelCid
    }

    convenience init(
        channelId: String,
        messageId: String,
        userId: String,
        latitude: Double,
        longitude: Double,
        createdAt: Date,
        updatedAt: Date,
        endAt: Date?,
        createdByDeviceId: String
    ) {
        self.init(
            channelCid: channelId,
            createdAt: createdAt,
            createdByDeviceId: createdByDeviceId,
            endAt: endAt,
            latitude: Float(latitude),
            longitude: Float(longitude),
            messageId: messageId,
            updatedAt: updatedAt,
            userId: userId
        )
    }
}

extension ReminderResponseData {
    var channelId: ChannelId? {
        try? ChannelId(cid: channelCid)
    }

    convenience init(
        channelCid: ChannelId,
        messageId: MessageId,
        message: MessageResponse? = nil,
        channel: ChannelResponse? = nil,
        remindAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.init(
            channelCid: channelCid.rawValue,
            createdAt: createdAt,
            messageId: messageId,
            remindAt: remindAt,
            updatedAt: updatedAt,
            userId: ""
        )
    }
}

extension UpdateReminderResponse {
    convenience init(reminder: ReminderResponseData) {
        self.init(duration: "", reminder: reminder)
    }
}

extension QueryRemindersResponse {
    convenience init(reminders: [ReminderResponseData], next: String?) {
        self.init(duration: "", next: next, reminders: reminders)
    }
}

extension SharedLocationPayload {
    convenience init(latitude: Double, longitude: Double, endAt: Date?, createdByDeviceId: String) {
        self.init(
            createdByDeviceId: createdByDeviceId,
            endAt: endAt,
            latitude: Float(latitude),
            longitude: Float(longitude)
        )
    }
}

extension UpdateLiveLocationRequest {
    convenience init(messageId: String, latitude: Double, longitude: Double, createdByDeviceId: String) {
        self.init(
            latitude: Float(latitude),
            longitude: Float(longitude),
            messageId: messageId
        )
    }

    convenience init(messageId: String, createdByDeviceId: String) {
        self.init(endAt: Date(), messageId: messageId)
    }
}

extension SharedLocationsResponse {
    var locations: [SharedLocationResponseData] {
        activeLiveLocations
    }

    convenience init(locations: [SharedLocationResponseData]) {
        self.init(activeLiveLocations: locations, duration: "")
    }
}

extension PollResponseData {
    convenience init(
        allowAnswers: Bool,
        allowUserSuggestedOptions: Bool,
        answersCount: Int,
        createdAt: Date,
        createdById: String,
        description: String,
        enforceUniqueVote: Bool,
        id: String,
        name: String,
        updatedAt: Date,
        voteCount: Int,
        latestAnswers: [PollVoteResponseData?]?,
        options: [PollOptionResponseData?],
        ownVotes: [PollVoteResponseData?],
        custom: [String: RawJSON],
        latestVotesByOption: [String: [PollVoteResponseData]]?,
        voteCountsByOption: [String: Int],
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        createdBy: UserResponse? = nil
    ) {
        self.init(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt,
            createdBy: createdBy?.asUserResponse,
            createdById: createdBy?.id ?? createdById,
            custom: custom,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            isClosed: isClosed,
            latestAnswers: latestAnswers?.compactMap { $0 } ?? [],
            latestVotesByOption: latestVotesByOption ?? [:],
            maxVotesAllowed: maxVotesAllowed,
            name: name,
            options: options.compactMap { $0 },
            ownVotes: ownVotes.compactMap { $0 },
            updatedAt: updatedAt,
            voteCount: voteCount,
            voteCountsByOption: voteCountsByOption,
            votingVisibility: votingVisibility ?? ""
        )
    }
}

extension PollOptionResponseData {
    convenience init(id: String, text: String, custom: [String: RawJSON]?) {
        self.init(custom: custom ?? [:], id: id, text: text)
    }
}

extension PollVoteResponseData {
    var optionalOptionId: String? {
        optionId.isEmpty ? nil : optionId
    }

    convenience init(
        createdAt: Date,
        id: String,
        optionId: String?,
        pollId: String,
        updatedAt: Date,
        answerText: String? = nil,
        isAnswer: Bool? = false,
        userId: String? = nil,
        user: UserResponse? = nil
    ) {
        self.init(
            answerText: answerText,
            createdAt: createdAt,
            id: id,
            isAnswer: isAnswer,
            optionId: optionId ?? "",
            pollId: pollId,
            updatedAt: updatedAt,
            user: user?.asUserResponse,
            userId: userId
        )
    }
}

extension PushPreferenceInput {
    convenience init(
        chatLevel: String?,
        channelId: String?,
        disabledUntil: Date?,
        removeDisable: Bool?
    ) {
        self.init(
            channelCid: channelId,
            chatLevel: chatLevel.flatMap { PushPreferenceInputChatLevel(rawValue: $0) },
            disabledUntil: disabledUntil,
            removeDisable: removeDisable
        )
    }
}

extension PushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}

extension ChannelPushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}

extension UpsertPushPreferencesResponse {
    var channelPreferences: [String: [String: ChannelPushPreferencesResponse]] {
        userChannelPreferences.mapValues { $0.compactMapValues { $0 } }
    }

    convenience init(
        userPreferences: [String: PushPreferencesResponse?],
        channelPreferences: [String: [String: ChannelPushPreferencesResponse]]
    ) {
        self.init(
            duration: "",
            userChannelPreferences: channelPreferences,
            userPreferences: userPreferences.compactMapValues { $0 }
        )
    }
}

extension [String: PushPreferencesResponse?] {
    func asModel() -> [PushPreference] {
        values.compactMap { $0?.asModel() }
    }
}

extension [String: PushPreferencesResponse] {
    func asModel() -> [PushPreference] {
        values.map { $0.asModel() }
    }
}

extension [String: [String: ChannelPushPreferencesResponse]] {
    func asModel() -> [ChannelId: PushPreference] {
        .init(uniqueKeysWithValues: values
            .flatMap { $0 }
            .compactMap { key, value in
                guard let channelId = try? ChannelId(cid: key) else { return nil }
                return (channelId, value.asModel())
            })
    }
}

extension QueryPollsResponse {
    convenience init(duration: String, polls: [PollResponseData], next: String? = nil, prev: String? = nil) {
        self.init(duration: duration, next: next, polls: polls, prev: prev)
    }
}

extension PollVoteResponse {
    convenience init(duration: String, vote: PollVoteResponseData? = nil) {
        self.init(duration: duration, poll: nil, vote: vote)
    }
}

extension PollVotesResponse {
    convenience init(duration: String, votes: [PollVoteResponseData?], next: String? = nil, prev: String? = nil) {
        self.init(duration: duration, next: next, prev: prev, votes: votes.compactMap { $0 })
    }
}

extension MessageActionRequest {
    convenience init(cid: ChannelId, messageId: MessageId, action: AttachmentAction) {
        self.init(formData: [action.name: action.value])
    }
}

extension GetRepliesResponse {
    convenience init(messages: [MessageResponse]) {
        self.init(duration: "", messages: messages)
    }
}

private func openAPIModel<Model: Decodable, Value: Encodable>(from value: Value, as type: Model.Type = Model.self) -> Model? {
    (try? JSONEncoder.stream.encode(value))
        .flatMap { try? JSONDecoder.stream.decode(Model.self, from: $0) }
}

private func rawJSONDictionary<Value: Encodable>(from value: Value) -> [String: RawJSON]? {
    openAPIModel(from: value, as: [String: RawJSON].self)
}

private extension RawJSON {
    var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case let .number(value) = self { return Int(value) }
        return nil
    }
}

extension ChannelGetOrCreateRequest {
    convenience init(query: ChannelQuery) {
        if let request = openAPIModel(from: query, as: ChannelGetOrCreateRequest.self) {
            self.init(
                data: request.data,
                hideForCreator: request.hideForCreator,
                members: request.members,
                messages: request.messages,
                presence: request.presence,
                state: request.state,
                threadUnreadCounts: request.threadUnreadCounts,
                watch: request.watch,
                watchers: request.watchers
            )
        } else {
            self.init(
                data: query.channelPayload,
                presence: query.options.contains(.presence) ? true : nil,
                state: query.options.contains(.state) ? true : nil,
                watch: query.options.contains(.watch) ? true : nil
            )
        }
    }
}

extension QueryMembersPayload {
    convenience init(query: ChannelMemberListQuery) {
        let sort = query.sort.map {
            SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey)
        }
        self.init(
            filterConditions: query.filter?.toRawJSONDictionary() ?? [:],
            id: query.cid.id,
            limit: query.pagination.pageSize,
            offset: query.pagination.offset == 0 ? nil : query.pagination.offset,
            sort: sort.isEmpty ? nil : sort,
            type: query.cid.type.rawValue
        )
    }
}

extension UpdateChannelPartialRequest {
    convenience init(channelInput: ChannelInput, unsetProperties: [String]) {
        self.init(set: rawJSONDictionary(from: channelInput), unset: unsetProperties)
    }
}

extension ChannelInputRequest {
    convenience init(channelInput: ChannelInput) {
        if let request = openAPIModel(from: channelInput, as: ChannelInputRequest.self) {
            self.init(
                autoTranslationEnabled: request.autoTranslationEnabled,
                autoTranslationLanguage: request.autoTranslationLanguage,
                configOverrides: request.configOverrides,
                createdBy: request.createdBy,
                custom: request.custom,
                disabled: request.disabled,
                frozen: request.frozen,
                invites: request.invites,
                members: request.members,
                team: request.team
            )
        } else {
            self.init(custom: rawJSONDictionary(from: channelInput))
        }
    }
}

extension ChannelMemberRequest {
    convenience init(memberInfo: MemberInfoRequest) {
        self.init(custom: memberInfo.extraData, userId: memberInfo.userId)
    }
}

extension UpdateMessagePartialRequest {
    convenience init(_ request: MessagePartialUpdateRequest) {
        self.init(
            set: request.set.flatMap { rawJSONDictionary(from: $0) },
            skipEnrichUrl: request.skipEnrichUrl,
            unset: request.unset
        )
    }
}

extension SearchPayload {
    convenience init(query: MessageSearchQuery) {
        let sort = query.sort.map {
            SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey)
        }
        self.init(
            filterConditions: query.channelFilter.toRawJSONDictionary(),
            limit: query.pagination?.pageSize,
            messageFilterConditions: query.messageFilter.toRawJSONDictionary(),
            next: query.pagination?.cursor,
            offset: query.pagination.flatMap { $0.cursor == nil && $0.offset != 0 ? $0.offset : nil },
            sort: sort.isEmpty ? nil : sort
        )
    }
}

private extension ChannelMemberListSortingKey {
    var remoteKey: String {
        switch self {
        case .channelRole:
            return "channel_role"
        case .createdAt:
            return "created_at"
        case .name:
            return "name"
        case .userId:
            return "user_id"
        }
    }
}

private extension MessageSearchSortingKey {
    var remoteKey: String {
        switch self {
        case .createdAt:
            return "created_at"
        case .id:
            return "id"
        case .relevance:
            return "relevance"
        case .updatedAt:
            return "updated_at"
        }
    }
}

extension CreateDeviceRequest.CreateDeviceRequestPushProvider {
    init(pushProvider: PushProvider) {
        self = Self(rawValue: pushProvider.rawValue) ?? .unknown
    }
}

extension UserRequest {
    convenience init(userId: UserId, name: String?, imageURL: URL?, extraData: [String: RawJSON]) {
        self.init(
            custom: extraData.isEmpty ? nil : extraData,
            id: userId,
            image: imageURL?.absoluteString,
            name: name
        )
    }
}

extension SendEventRequest {
    convenience init<Payload: CustomEventPayload>(payload: Payload) {
        let data = try? JSONEncoder.default.encode(payload)
        var custom = data.flatMap { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) } ?? [:]
        // Strip the `type` field that CustomEventPayload encoders include — the
        // server takes the type from the outer EventRequest.type, not the payload.
        custom["type"] = nil
        self.init(event: EventRequest(
            custom: custom.isEmpty ? nil : custom,
            type: type(of: payload).eventType.rawValue
        ))
    }
}

extension SendReactionRequest {
    convenience init(enforceUnique: Bool, skipPush: Bool, reaction: ReactionRequest) {
        self.init(enforceUnique: enforceUnique, reaction: reaction, skipPush: skipPush)
    }
}

extension ReactionResponse {
    var reactionType: MessageReactionType {
        MessageReactionType(rawValue: type)
    }

    var userPayload: UserResponse {
        user.asUserPayload
    }

    var extraData: [String: RawJSON] {
        custom
    }

    convenience init(
        type: MessageReactionType,
        score: Int,
        messageId: String,
        createdAt: Date,
        updatedAt: Date,
        user: UserResponse,
        extraData: [String: RawJSON]
    ) {
        self.init(
            createdAt: createdAt,
            custom: extraData,
            messageId: messageId,
            score: score,
            type: type.rawValue,
            updatedAt: updatedAt,
            user: user.asUserResponse,
            userId: user.id
        )
    }
}

extension ReactionRequest {
    convenience init(
        type: MessageReactionType,
        score: Int,
        emojiCode: String?,
        extraData: [String: RawJSON]
    ) {
        var custom = extraData
        if let emojiCode {
            custom["emoji_code"] = .string(emojiCode)
        }
        self.init(
            custom: custom.isEmpty ? nil : custom,
            score: score,
            type: type.rawValue
        )
    }
}

extension FlagRequest {
    convenience init(
        reason: String? = nil,
        targetMessageId: String? = nil,
        targetUserId: String? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.init(
            custom: custom,
            entityId: targetMessageId ?? targetUserId ?? "",
            entityType: targetMessageId == nil ? "user" : "message",
            reason: reason
        )
    }
}

extension UserResponse {
    var asOwnUserResponse: OwnUserResponse {
        OwnUserResponse(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRolePayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            extraData: extraData,
            pushPreference: nil
        )
    }
}

extension FlagResponse {
    var flaggedUser: UserResponse {
        UserResponse(
            id: "",
            name: nil,
            imageURL: nil,
            role: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            isOnline: false,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:]
        )
    }
}

extension PollOptionInput {
    convenience init(text: String? = nil, custom: [String: RawJSON]? = nil) {
        self.init(custom: custom, text: text)
    }
}

extension CreatePollOptionRequest {
    convenience init(pollId: String, text: String, position: Int? = nil, custom: [String: RawJSON]? = nil) {
        self.init(custom: custom, text: text)
    }
}

extension TruncateChannelRequest {
    convenience init(skipPush: Bool, hardDelete: Bool, message: MessageRequest?) {
        self.init(
            hardDelete: hardDelete,
            message: message,
            skipPush: skipPush
        )
    }
}

extension BanRequest {
    convenience init(
        userId: UserId,
        cid: ChannelId,
        shadow: Bool,
        timeoutInMinutes: Int? = nil,
        reason: String? = nil
    ) {
        self.init(
            channelCid: cid.rawValue,
            reason: reason,
            shadow: shadow,
            targetUserId: userId,
            timeout: timeoutInMinutes
        )
    }
}

extension CastPollVoteRequest {
    convenience init(pollId: String, vote: VoteData? = nil) {
        self.init(vote: vote)
    }
}

extension VoteData {
    convenience init(
        answerText: String? = nil,
        optionId: String? = nil,
        option: PollOptionRequest? = nil
    ) {
        self.init(answerText: answerText, optionId: optionId)
    }
}

extension UpdatePollRequest {
    convenience init(
        id: String,
        name: String,
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        options: [PollOptionRequest?]? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.init(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            custom: custom,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            name: name,
            options: options?.compactMap { $0 },
            votingVisibility: votingVisibility.flatMap { UpdatePollRequestVotingVisibility(rawValue: $0) }
        )
    }
}

extension UpdatePollOptionRequest {
    convenience init(id: String, pollId: String, text: String, custom: [String: RawJSON]? = nil) {
        self.init(custom: custom, id: id, text: text)
    }
}

extension UpdatePollPartialRequest {
    convenience init(pollId: String, unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.init(set: set, unset: unset)
    }
}

extension SyncRequest {
    convenience init(lastSyncedAt: Date, cids: [ChannelId]) {
        self.init(channelCids: cids.map(\.rawValue), lastSyncAt: lastSyncedAt)
    }
}

extension MarkUnreadRequest {
    convenience init(criteria: MarkUnreadCriteria, userId: String) {
        switch criteria {
        case let .messageId(messageId):
            self.init(messageId: messageId)
        case let .messageTimestamp(messageTimestamp):
            self.init(messageTimestamp: messageTimestamp)
        }
    }
}

extension Attachment {
    convenience init(type: AttachmentType, payload: RawJSON) {
        let attachment: Attachment? = {
            guard let data = try? JSONEncoder.default.encode(payload) else { return nil }
            return try? JSONDecoder.default.decode(Attachment.self, from: data)
        }()
        if let attachment {
            self.init(
                actions: attachment.actions,
                assetUrl: attachment.assetUrl,
                authorIcon: attachment.authorIcon,
                authorLink: attachment.authorLink,
                authorName: attachment.authorName,
                color: attachment.color,
                custom: attachment.custom,
                fallback: attachment.fallback,
                fields: attachment.fields,
                footer: attachment.footer,
                footerIcon: attachment.footerIcon,
                giphy: attachment.giphy,
                imageUrl: attachment.imageUrl,
                ogScrapeUrl: attachment.ogScrapeUrl,
                originalHeight: attachment.originalHeight,
                originalWidth: attachment.originalWidth,
                pretext: attachment.pretext,
                text: attachment.text,
                thumbUrl: attachment.thumbUrl,
                title: attachment.title,
                titleLink: attachment.titleLink
            )
        } else {
            var dict = payload.dictionaryValue ?? [:]
            dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
            self.init(custom: dict)
        }
        self.type = type.rawValue
    }

    var attachmentType: AttachmentType {
        if ogScrapeUrl != nil {
            return .linkPreview
        }
        return type.map(AttachmentType.init(rawValue:)) ?? .unknown
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

private extension SharedLocationPayload {
    var asSharedLocationOpenAPI: SharedLocationPayload {
        SharedLocationPayload(
            createdByDeviceId: createdByDeviceId,
            endAt: endAt,
            latitude: Float(latitude),
            longitude: Float(longitude)
        )
    }
}

extension QueryThreadsResponse {
    convenience init(threads: [ThreadStateResponse], next: String? = nil) {
        self.init(duration: "", next: next, prev: nil, threads: threads)
    }
}

extension ThreadStateResponse {
    var extraData: [String: RawJSON] { custom }

    var channelDetailPayload: ChannelResponse? {
        if let channelPayload = channel?.asChannelResponse {
            return channelPayload
        }
        guard let cid = try? ChannelId(cid: channelCid) else { return nil }
        return ChannelResponse(
            cid: cid.rawValue,
            config: ChannelConfig().asChannelConfigWithInfo,
            createdAt: createdAt,
            createdBy: createdBy?.asUserResponse,
            custom: [:],
            disabled: false,
            frozen: false,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: 0,
            type: cid.type.rawValue,
            updatedAt: updatedAt
        )
    }

    var createdByPayload: UserResponse {
        createdBy?.asUserPayload ?? UserResponse.empty
    }

    var parentMessagePayload: MessageResponse? {
        parentMessage?.asMessagePayload ?? MessageResponse(
            attachments: [],
            cid: channelCid,
            createdAt: createdAt,
            custom: [:],
            deletedReplyCount: 0,
            html: "",
            id: parentMessageId,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [],
            ownReactions: [],
            pinned: false,
            reactionCounts: [:],
            reactionScores: [:],
            replyCount: replyCount ?? 0,
            restrictedVisibility: [],
            shadowed: false,
            showInChannel: false,
            silent: false,
            text: "",
            type: MessageType.regular.rawValue,
            updatedAt: updatedAt,
            user: createdByPayload
        )
    }

    var latestRepliesPayload: [MessageResponse] {
        latestReplies.compactMap(\.asMessagePayload)
    }

    var readPayload: [ReadStateResponse] { read ?? [] }

    var threadParticipantPayloads: [ThreadParticipantPayload] { threadParticipants ?? [] }

    convenience init(
        parentMessageId: MessageId,
        parentMessage: MessageResponse,
        channel: ChannelResponse,
        createdBy: UserResponse,
        replyCount: Int,
        participantCount: Int,
        activeParticipantCount: Int,
        threadParticipants: [ThreadParticipantPayload],
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        title: String?,
        latestReplies: [MessageResponse],
        read: [ReadStateResponse],
        draft: DraftResponse?,
        extraData: [String: RawJSON]
    ) {
        self.init(
            activeParticipantCount: activeParticipantCount,
            channel: channel.asChannelResponse,
            channelCid: channel.cid,
            createdAt: createdAt,
            createdBy: createdBy.asUserResponse,
            createdByUserId: createdBy.id,
            custom: extraData,
            deletedAt: nil,
            draft: draft,
            lastMessageAt: lastMessageAt,
            latestReplies: latestReplies.compactMap(\.asMessageResponse),
            parentMessage: parentMessage.asMessageResponse,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            read: read,
            replyCount: replyCount,
            threadParticipants: threadParticipants,
            title: title ?? "",
            updatedAt: updatedAt ?? createdAt
        )
    }
}

extension ThreadResponse {
    var cid: ChannelId? { try? ChannelId(cid: channelCid) }

    var extraData: [String: RawJSON] { custom }

    var channelDetailPayload: ChannelResponse? {
        if let channelPayload = channel?.asChannelResponse {
            return channelPayload
        }
        guard let cid = try? ChannelId(cid: channelCid) else { return nil }
        return ChannelResponse(
            cid: cid.rawValue,
            config: ChannelConfig().asChannelConfigWithInfo,
            createdAt: createdAt,
            createdBy: createdBy?.asUserResponse,
            custom: [:],
            disabled: false,
            frozen: false,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: 0,
            type: cid.type.rawValue,
            updatedAt: updatedAt
        )
    }

    var createdByPayload: UserResponse {
        createdBy?.asUserPayload ?? UserResponse.empty
    }

    var parentMessagePayload: MessageResponse? {
        parentMessage?.asMessagePayload ?? MessageResponse(
            attachments: [],
            cid: channelCid,
            createdAt: createdAt,
            custom: [:],
            deletedReplyCount: 0,
            html: "",
            id: parentMessageId,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [],
            ownReactions: [],
            pinned: false,
            reactionCounts: [:],
            reactionScores: [:],
            replyCount: replyCount ?? 0,
            restrictedVisibility: [],
            shadowed: false,
            showInChannel: false,
            silent: false,
            text: "",
            type: MessageType.regular.rawValue,
            updatedAt: updatedAt,
            user: createdByPayload
        )
    }

    convenience init(
        parentMessageId: MessageId,
        parentMessage: MessageResponse,
        channel: ChannelResponse,
        createdBy: UserResponse,
        replyCount: Int,
        participantCount: Int,
        activeParticipantCount: Int,
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        title: String?,
        extraData: [String: RawJSON]
    ) {
        self.init(
            activeParticipantCount: activeParticipantCount,
            channel: channel.asChannelResponse,
            channelCid: channel.cid,
            createdAt: createdAt,
            createdBy: createdBy.asUserResponse,
            createdByUserId: createdBy.id,
            custom: extraData,
            deletedAt: nil,
            lastMessageAt: lastMessageAt,
            parentMessage: parentMessage.asMessageResponse,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            replyCount: replyCount,
            threadParticipants: nil,
            title: title ?? "",
            updatedAt: updatedAt ?? createdAt
        )
    }

    convenience init(
        cid: ChannelId,
        parentMessageId: MessageId,
        replyCount: Int,
        participantCount: Int,
        activeParticipantCount: Int?,
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        title: String?
    ) {
        self.init(
            activeParticipantCount: activeParticipantCount ?? 0,
            channel: nil,
            channelCid: cid.rawValue,
            createdAt: createdAt,
            createdBy: nil,
            createdByUserId: "",
            custom: [:],
            deletedAt: nil,
            lastMessageAt: lastMessageAt,
            parentMessage: nil,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            replyCount: replyCount,
            threadParticipants: nil,
            title: title ?? "",
            updatedAt: updatedAt
        )
    }
}

extension ThreadParticipantPayload {
    var userPayload: UserResponse {
        user?.asUserPayload ?? UserResponse.empty
    }

    convenience init(
        user: UserResponse,
        threadId: String,
        createdAt: Date,
        lastReadAt: Date?
    ) {
        self.init(
            appPk: 0,
            channelCid: "",
            createdAt: createdAt,
            custom: [:],
            lastReadAt: lastReadAt ?? Date(timeIntervalSince1970: 0),
            lastThreadMessageAt: nil,
            leftThreadAt: nil,
            threadId: threadId,
            user: user.asUserResponse,
            userId: user.id
        )
    }
}

private extension UserResponse {
    static var empty: UserResponse {
        UserResponse(
            id: "",
            name: nil,
            imageURL: nil,
            role: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            isOnline: false,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:]
        )
    }
}

/// A type representing empty body for `.post` Endpoints.
/// Our backend currently expects a body (not `nil`), even if it's empty.
struct EmptyBody: Codable, Equatable {}

// MARK: - Endpoint compatibility wrappers

//
// Factories below keep existing call sites small while delegating to generated
// OpenAPI endpoints wherever the operation and model shape match.

extension Endpoint {
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
                        privacySettings: userInfo.privacySettings.map {
                            UserPrivacySettingsPayload(settings: $0).asPrivacySettingsResponse
                        }
                    )
                )
            ]
        )
    }

    /// Channel query endpoint used by `ChannelRepository.getChannel` and the
    /// channel-already-exists hot path.
    static func channelQuery(_ query: ChannelQuery, requiresConnectionId: Bool? = nil) -> Endpoint<ChannelStateResponse> {
        let request = ChannelGetOrCreateRequest(query: query)
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

    /// Flag / unflag a user. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagUser(_ flag: Bool, with userId: UserId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(reason: reason, targetUserId: userId, custom: extraData))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(reason: reason, targetMessageId: nil, targetUserId: userId, custom: extraData)
        )
    }

    /// Flag / unflag a message. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagMessage(_ flag: Bool, with messageId: MessageId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(reason: reason, targetMessageId: messageId, custom: extraData))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(reason: reason, targetMessageId: messageId, targetUserId: nil, custom: extraData)
        )
    }
}
