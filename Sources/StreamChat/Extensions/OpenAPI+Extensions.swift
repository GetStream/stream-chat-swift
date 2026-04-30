//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Typealiases for reducing changes when switching to OpenAPI generated models
typealias AppSettingsPayload = GetApplicationResponse
typealias AttachmentActionRequestBody = MessageActionRequest
typealias CastPollVoteRequestBody = CastPollVoteRequest
typealias ChannelDeliveredRequestPayload = MarkDeliveredRequest
typealias ChannelEditDetailPayload = ChannelInput
typealias ChannelMemberBanRequestPayload = BanRequest
typealias ChannelMemberListPayload = MembersResponse
typealias ChannelTruncateRequestPayload = TruncateChannelRequest
typealias ChannelReadPayload = ReadStateResponse
typealias ChannelUnreadByTypePayload = UnreadCountsChannelType
typealias CreatePollOptionRequestBody = CreatePollOptionRequest
typealias CreatePollRequestBody = CreatePollRequest
typealias CurrentUserPayload = OwnUserResponse
typealias CurrentUserChannelUnreadPayload = UnreadCountsChannel
typealias CurrentUserThreadUnreadPayload = UnreadCountsThread
typealias CurrentUserUpdateResponse = UpdateUsersResponse
typealias CurrentUserUnreadsPayload = WrappedUnreadCountsResponse
typealias CustomEventRequestBody = SendEventRequest
typealias DeliveredMessagePayload = DeliveredMessagePayloadOpenAPI
typealias DeviceListPayload = ListDevicesResponse
typealias DevicePayload = DeviceResponse
typealias DraftListPayloadResponse = QueryDraftsResponse
typealias DraftMessagePayload = DraftPayloadResponseOpenAPI
typealias DraftMessageRequestBody = CreateDraftRequest
typealias DraftPayload = DraftResponse
typealias DraftPayloadResponse = GetDraftResponse
typealias FileUploadPayload = UploadChannelResponse
typealias FlagMessagePayload = FlagResponse
typealias FlagRequestBody = FlagRequest
typealias FlagUserPayload = FlagResponse
typealias GuestUserTokenPayload = CreateGuestResponse
typealias GuestUserTokenRequestPayload = UserRequest
typealias ActiveLiveLocationsResponsePayload = SharedLocationsResponse
typealias LiveLocationUpdateRequestPayload = UpdateLiveLocationRequest
typealias MarkUnreadPayload = MarkUnreadRequest
typealias MessageAttachmentPayload = Attachment
typealias MessageReactionGroupPayload = ReactionGroupResponse
typealias MessageReactionPayload = ReactionResponse
typealias MessageReactionRequestPayload = SendReactionRequest
typealias MessageModerationDetailsPayload = ModerationV2Response
typealias MessageTranslationsPayload = [String: String]
typealias MemberContainerPayload = ChannelMemberResponse
typealias MemberInvitePayload = ChannelMemberResponse
typealias MemberPayload = ChannelMemberResponse
typealias MemberRolePayload = ChannelMemberResponse
typealias MemberUpdatePayload = UpdateMemberPartialRequest
typealias MutedChannelPayload = ChannelMute
typealias MutedChannelPayloadResponse = MuteChannelResponse
typealias MutedUserPayload = UserMuteResponse
typealias MutedUsersResponse = MuteResponse
typealias MissingEventsRequestBody = SyncRequest
typealias NewLocationRequestPayload = SharedLocationOpenAPI
typealias PollOptionPayload = PollOptionResponseData
typealias PollOptionRequestBody = PollOptionInput
typealias PollOptionResponse = PollOptionResponseOpenAPI
typealias PollPayload = PollResponseData
typealias PollPayloadResponse = PollResponse
typealias PollsListPayloadResponse = QueryPollsResponse
typealias PollVoteListResponse = PollVotesResponse
typealias PollVoteOptionRequestBody = PollOptionRequest
typealias PollVotePayload = PollVoteResponseData
typealias PollVotePayloadResponse = PollVoteResponse
typealias PushPreferencePayload = PushPreferencesResponse
typealias PushPreferenceRequestPayload = PushPreferenceInput
typealias PushPreferencesPayloadResponse = UpsertPushPreferencesResponse
typealias QueryPollsRequestBody = QueryPollsRequest
typealias QueryPollVotesRequestBody = QueryPollVotesRequest
typealias ReactionRequestPayload = ReactionRequest
typealias ReminderPayload = ReminderResponseData
typealias ReminderRequestBody = CreateReminderRequest
typealias ReminderResponsePayload = UpdateReminderResponse
typealias RemindersQueryPayload = QueryRemindersResponse
typealias SortParamRequest = SortParamRequestOpenAPI
typealias SharedLocationPayload = SharedLocationResponseData
typealias StopLiveLocationRequestPayload = UpdateLiveLocationRequest
typealias ThreadDetailsPayload = ThreadResponse
typealias ThreadListPayload = QueryThreadsResponse
typealias ThreadParticipantPayload = ThreadParticipantOpenAPI
typealias ThreadPartialPayload = ThreadResponse
typealias ThreadPayload = ThreadStateResponse
typealias ThreadReadPayload = ReadStateResponse
typealias UpdatePollOptionRequest = UpdatePollOptionRequestOpenAPI
typealias UpdatePollPartialRequestBody = UpdatePollPartialRequest
typealias UpdatePollRequestBody = UpdatePollRequest
typealias UserListPayload = QueryUsersResponse
typealias UserPayload = UserResponse
typealias UserPushPreferencesPayload = [String: PushPreferencePayload?]
typealias UserRequestBody = UserRequest
typealias UserUpdateRequestBody = UpdateUserPartialRequest
typealias VoteDataRequestBody = VoteData
typealias ChannelPushPreferencesPayload = [String: [String: ChannelPushPreferencesResponse]]

extension GetApplicationResponse {
    typealias AppPayload = AppResponseFields
    typealias UploadConfigPayload = FileUploadConfig
}

extension APIError: Error {}

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
    ) -> MessageTranslationsPayload? {
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
    convenience init(devices: [DevicePayload]) {
        self.init(devices: devices, duration: "")
    }
}

extension MembersResponse {
    convenience init(members: [MemberPayload]) {
        self.init(duration: "", members: members)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            duration: try container.decodeIfPresent(String.self, forKey: .duration) ?? "",
            members: try container.decode([MemberPayload].self, forKey: .members)
        )
    }
}

extension ChannelMemberResponse {
    var member: MemberPayload? {
        self
    }

    var invite: MemberInvitePayload? {
        self
    }

    var userPayload: UserPayload? {
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
        member: MemberPayload?,
        invite: MemberInvitePayload?,
        memberRole: MemberRolePayload?
    ) {
        let payload = member ?? invite ?? memberRole
        self.init(
            archivedAt: payload?.archivedAt,
            banExpires: payload?.banExpires,
            banned: payload?.banned ?? false,
            channelRole: payload?.channelRole ?? MemberRole.member.rawChannelValue,
            createdAt: payload?.createdAt ?? Date(timeIntervalSince1970: 0),
            custom: payload?.custom ?? [:],
            deletedAt: payload?.deletedAt,
            deletedMessages: payload?.deletedMessages,
            inviteAcceptedAt: payload?.inviteAcceptedAt,
            inviteRejectedAt: payload?.inviteRejectedAt,
            invited: payload?.invited,
            isModerator: payload?.isModerator,
            notificationsMuted: payload?.notificationsMuted ?? false,
            pinnedAt: payload?.pinnedAt,
            role: payload?.role,
            shadowBanned: payload?.shadowBanned ?? false,
            status: payload?.status,
            updatedAt: payload?.updatedAt ?? Date(timeIntervalSince1970: 0),
            user: payload?.user,
            userId: payload?.userId
        )
    }

    convenience init(
        user: UserPayload?,
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

    convenience init(currentUser: CurrentUserPayload, flaggedMessageId: MessageId) {
        self.init(duration: "", itemId: flaggedMessageId)
    }
}

extension UserMuteResponse {
    var mutedUser: UserPayload {
        target?.asUserPayload ?? UserPayload(
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

    convenience init(mutedUser: UserPayload, created: Date, updated: Date) {
        self.init(createdAt: created, target: mutedUser.asUserResponse, updatedAt: updated)
    }
}

extension MuteResponse {
    var mutedUser: MutedUserPayload {
        mutes?.first ?? UserMuteResponse(
            createdAt: Date(timeIntervalSince1970: 0),
            target: nil,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    var currentUser: CurrentUserPayload {
        ownUser?.asCurrentUserPayload ?? UserPayload(
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
        ).asCurrentUserPayload
    }
}

extension OwnUserResponse {
    var asCurrentUserPayload: CurrentUserPayload {
        self
    }

    var asUserPayload: UserPayload {
        UserPayload(
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

    var mutedUsers: [MutedUserPayload] {
        mutes
    }

    var mutedChannels: [MutedChannelPayload] {
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

    var pushPreference: PushPreferencePayload? {
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
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        unreadCount: UnreadCountPayload? = nil,
        privacySettings: UserPrivacySettingsPayload? = nil,
        blockedUserIds: Set<UserId> = [],
        pushPreference: PushPreferencePayload?
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

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        var extraData = (try? [String: RawJSON](from: decoder)) ?? [:]
        extraData.removeValues(forKeys: CodingKeys.allCases.map(\.rawValue) + Self.legacyUserPayloadKeys)
        extraData = extraData.merging(custom) { _, customValue in customValue }

        self.init(
            avgResponseTime: try container.decodeIfPresent(Int.self, forKey: .avgResponseTime),
            banned: try container.decodeIfPresent(Bool.self, forKey: .banned) ?? false,
            blockedUserIds: try container.decodeIfPresent([String].self, forKey: .blockedUserIds),
            channelMutes: try container.decodeIfPresent([ChannelMute].self, forKey: .channelMutes) ?? [],
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            custom: extraData,
            deactivatedAt: try container.decodeIfPresent(Date.self, forKey: .deactivatedAt),
            deletedAt: try container.decodeIfPresent(Date.self, forKey: .deletedAt),
            devices: try container.decodeIfPresent([DeviceResponse].self, forKey: .devices) ?? [],
            id: try container.decodeIfPresent(String.self, forKey: .id) ?? "",
            image: try container.decodeIfPresent(String.self, forKey: .image),
            invisible: try container.decodeIfPresent(Bool.self, forKey: .invisible) ?? false,
            language: try container.decodeIfPresent(String.self, forKey: .language) ?? "",
            lastActive: try container.decodeIfPresent(Date.self, forKey: .lastActive),
            latestHiddenChannels: try container.decodeIfPresent([String].self, forKey: .latestHiddenChannels),
            mutes: try container.decodeIfPresent([UserMuteResponse].self, forKey: .mutes) ?? [],
            name: try container.decodeIfPresent(String.self, forKey: .name),
            online: try container.decode(Bool.self, forKey: .online),
            privacySettings: try container.decodeIfPresent(PrivacySettingsResponse.self, forKey: .privacySettings),
            pushPreferences: try container.decodeIfPresent(PushPreferencesResponse.self, forKey: .pushPreferences),
            revokeTokensIssuedBefore: try container.decodeIfPresent(Date.self, forKey: .revokeTokensIssuedBefore),
            role: try container.decode(String.self, forKey: .role),
            teams: try container.decodeIfPresent([String].self, forKey: .teams) ?? [],
            teamsRole: try container.decodeIfPresent([String: String].self, forKey: .teamsRole),
            totalUnreadCount: try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount) ?? 0,
            totalUnreadCountByTeam: try container.decodeIfPresent([String: Int].self, forKey: .totalUnreadCountByTeam),
            unreadChannels: try container.decodeIfPresent(Int.self, forKey: .unreadChannels) ?? 0,
            unreadCount: try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0,
            unreadThreads: try container.decodeIfPresent(Int.self, forKey: .unreadThreads) ?? -1,
            updatedAt: try container.decode(Date.self, forKey: .updatedAt)
        )
    }

    private static var legacyUserPayloadKeys: [String] {
        [
            "id",
            "name",
            "image",
            "role",
            "online",
            "banned",
            "created_at",
            "updated_at",
            "deactivated_at",
            "last_active",
            "invisible",
            "teams",
            "unread_channels",
            "total_unread_count",
            "unread_threads",
            "mutes",
            "channel_mutes",
            "anon",
            "devices",
            "unread_count",
            "language",
            "privacy_settings",
            "blocked_user_ids",
            "teams_role",
            "avg_response_time",
            "push_preferences"
        ]
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

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            channelMute: try container.decodeIfPresent(ChannelMute.self, forKey: .channelMute),
            channelMutes: try container.decodeIfPresent([ChannelMute].self, forKey: .channelMutes),
            duration: try container.decodeIfPresent(String.self, forKey: .duration) ?? "",
            ownUser: try container.decodeIfPresent(OwnUserResponse.self, forKey: .ownUser)
        )
    }
}

extension ChannelMute {
    var channelPayload: ChannelDetailPayload? {
        channel?.asChannelDetailPayload
    }

    var userPayload: UserPayload? {
        user?.asUserPayload
    }

    var expiresAt: Date? {
        expires
    }

    convenience init(
        mutedChannel: ChannelDetailPayload,
        user: UserPayload,
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
        mutedChannel: ChannelDetailPayload,
        user: CurrentUserPayload,
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

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let channelPayload = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        let userPayload = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        self.init(
            channel: channelPayload?.asChannelResponse,
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            expires: try container.decodeIfPresent(Date.self, forKey: .expires),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt),
            user: userPayload?.asUserResponse
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
    convenience init(drafts: [DraftPayload], next: String? = nil) {
        self.init(drafts: drafts, duration: "", next: next)
    }
}

extension GetDraftResponse {
    convenience init(draft: DraftPayload) {
        self.init(draft: draft, duration: "")
    }
}

extension DraftResponse {
    var cid: ChannelId? {
        try? ChannelId(cid: channelCid)
    }

    var channelPayload: ChannelDetailPayload? {
        channel?.asChannelDetailPayload
    }

    convenience init(
        cid: ChannelId?,
        channelPayload: ChannelDetailPayload?,
        createdAt: Date,
        message: DraftMessagePayload,
        quotedMessage: MessagePayload?,
        parentId: String?,
        parentMessage: MessagePayload?
    ) {
        self.init(
            channel: channelPayload?.asChannelResponse,
            channelCid: cid?.rawValue ?? channelPayload?.cid.rawValue ?? "",
            createdAt: createdAt,
            message: message,
            parentId: parentId,
            parentMessage: parentMessage?.asMessageResponse,
            quotedMessage: quotedMessage?.asMessageResponse
        )
    }
}

extension DraftPayloadResponseOpenAPI {
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

    var mentionedUsersPayload: [UserPayload]? {
        mentionedUsers?.map(\.asUserPayload)
    }

    var extraData: [String: RawJSON] {
        custom
    }

    var attachmentPayloads: [MessageAttachmentPayload]? {
        attachments
    }

    convenience init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        showReplyInChannel: Bool,
        mentionedUsers: [UserPayload]?,
        extraData: [String: RawJSON],
        attachments: [MessageAttachmentPayload]?,
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
        attachments: [MessageAttachmentPayload],
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
        user: UserPayload,
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
        user: CurrentUserPayload,
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
        channels: [CurrentUserChannelUnreadPayload],
        channelType: [ChannelUnreadByTypePayload],
        threads: [CurrentUserThreadUnreadPayload]
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

extension DeliveredMessagePayloadOpenAPI {
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
    convenience init(user: CurrentUserPayload, token: Token) {
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
    var asUserPayload: UserPayload {
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
    var asUserPayload: UserPayload {
        UserPayload(
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

    var asCurrentUserPayload: CurrentUserPayload {
        CurrentUserPayload(
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
    var userPayloads: [UserPayload] {
        users.map(\.asUserPayload)
    }

    convenience init(users: [UserPayload]) {
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
    var user: CurrentUserPayload {
        (try? validatedUser()) ?? UserPayload.empty.asCurrentUserPayload
    }

    convenience init(user: CurrentUserPayload) {
        self.init(duration: "", membershipDeletionTaskId: "", users: [user.id: user.asFullUserResponse])
    }

    func validatedUser() throws -> CurrentUserPayload {
        guard let user = users.first?.value else {
            throw ClientError.Unexpected("Missing updated user.")
        }
        return user.asCurrentUserPayload
    }
}

private extension Encodable {
    var rawJSON: RawJSON? {
        guard let data = try? JSONEncoder.default.encode(self) else { return nil }
        return try? JSONDecoder.default.decode(RawJSON.self, from: data)
    }
}

extension UserPayload {
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
    var asChannelDetailPayload: ChannelDetailPayload? {
        guard let cid = try? ChannelId(cid: cid) else { return nil }

        return ChannelDetailPayload(
            cid: cid,
            name: custom["name"]?.stringValue,
            imageURL: custom["image"]?.stringValue.flatMap(URL.init(string:)),
            extraData: custom.removingValues(forKeys: ["name", "image"]),
            typeRawValue: type,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            deletedAt: deletedAt,
            updatedAt: updatedAt,
            truncatedAt: truncatedAt,
            createdBy: createdBy?.asUserPayload,
            config: config?.asChannelConfig ?? .init(),
            filterTags: filterTags,
            ownCapabilities: ownCapabilities?.map(\.rawValue),
            isDisabled: disabled,
            isFrozen: frozen,
            isBlocked: blocked,
            isHidden: hidden,
            members: nil,
            memberCount: memberCount ?? 0,
            messageCount: messageCount,
            team: team,
            cooldownDuration: cooldown ?? 0
        )
    }
}

extension ChannelDetailPayload {
    var asChannelResponse: ChannelResponse? {
        var custom = extraData
        if let name {
            custom["name"] = .string(name)
        }
        if let imageURL {
            custom["image"] = .string(imageURL.absoluteString)
        }

        return ChannelResponse(
            blocked: isBlocked,
            cid: cid.rawValue,
            config: config.asChannelConfigWithInfo,
            cooldown: cooldownDuration,
            createdAt: createdAt,
            createdBy: createdBy?.asUserResponse,
            custom: custom,
            deletedAt: deletedAt,
            disabled: isDisabled,
            filterTags: filterTags,
            frozen: isFrozen,
            hidden: isHidden,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: memberCount,
            members: nil,
            messageCount: messageCount,
            ownCapabilities: ownCapabilities?.compactMap(ChannelOwnCapability.init(rawValue:)),
            team: team,
            truncatedAt: truncatedAt,
            type: typeRawValue,
            updatedAt: updatedAt
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

extension CommandOpenAPI {
    var asCommand: Command {
        .init(name: name, description: description, set: set, args: args)
    }
}

extension Command {
    var asCommandOpenAPI: CommandOpenAPI {
        .init(args: args, description: description, name: name, set: set)
    }
}

extension MessageResponse {
    var asMessagePayload: MessagePayload? {
        MessagePayload(
            id: id,
            cid: try? ChannelId(cid: cid),
            type: MessageType(rawValue: type) ?? .regular,
            user: user.asUserPayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            text: text,
            command: command,
            parentId: parentId,
            showReplyInChannel: showInChannel ?? false,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage?.asMessagePayload,
            mentionedUsers: mentionedUsers.map(\.asUserPayload),
            threadParticipants: threadParticipants?.map(\.asUserPayload) ?? [],
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            extraData: custom,
            reactionScores: reactionScores.mapKeys(MessageReactionType.init(rawValue:)),
            reactionCounts: reactionCounts.mapKeys(MessageReactionType.init(rawValue:)),
            isSilent: silent,
            isShadowed: shadowed,
            attachments: attachments,
            pinned: pinned,
            pinnedBy: pinnedBy?.asUserPayload,
            pinnedAt: pinnedAt,
            pinExpires: pinExpires,
            translations: i18n?.translated,
            originalLanguage: i18n?.originalLanguage,
            moderation: moderation,
            messageTextUpdatedAt: messageTextUpdatedAt,
            poll: poll,
            draft: draft,
            reminder: reminder,
            location: sharedLocation,
            deletedForMe: deletedForMe
        )
    }
}

extension MessagePayload {
    var asMessageResponse: MessageResponse? {
        MessageResponse(
            attachments: attachments,
            cid: cid?.rawValue ?? channel?.cid.rawValue ?? "",
            command: command,
            createdAt: createdAt,
            custom: extraData,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: 0,
            html: "",
            i18n: MessageTranslationsPayload.messageTranslations(
                translations: translations,
                originalLanguage: originalLanguage
            ),
            id: id,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: mentionedUsers.map(\.asUserResponse),
            messageTextUpdatedAt: messageTextUpdatedAt,
            moderation: moderation,
            ownReactions: [],
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy?.asUserResponse,
            poll: poll,
            pollId: poll?.id,
            quotedMessage: quotedMessage?.asMessageResponse,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts.mapKeys(\.rawValue),
            reactionGroups: reactionGroups.mapKeys(\.rawValue),
            reactionScores: reactionScores.mapKeys(\.rawValue),
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: isShadowed,
            sharedLocation: location,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text,
            threadParticipants: threadParticipants.map(\.asUserResponse),
            type: type.rawValue,
            updatedAt: updatedAt,
            user: user.asUserResponse
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
        message: MessagePayload? = nil,
        channel: ChannelDetailPayload? = nil,
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
    convenience init(reminder: ReminderPayload) {
        self.init(duration: "", reminder: reminder)
    }
}

extension QueryRemindersResponse {
    convenience init(reminders: [ReminderPayload], next: String?) {
        self.init(duration: "", next: next, reminders: reminders)
    }
}

extension SharedLocationOpenAPI {
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
    var locations: [SharedLocationPayload] {
        activeLiveLocations
    }

    convenience init(locations: [SharedLocationPayload]) {
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
        latestAnswers: [PollVotePayload?]?,
        options: [PollOptionPayload?],
        ownVotes: [PollVotePayload?],
        custom: [String: RawJSON],
        latestVotesByOption: [String: [PollVotePayload]]?,
        voteCountsByOption: [String: Int],
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        createdBy: UserPayload? = nil
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
        user: UserPayload? = nil
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
    var channelPreferences: ChannelPushPreferencesPayload {
        userChannelPreferences.mapValues { $0.compactMapValues { $0 } }
    }

    convenience init(
        userPreferences: UserPushPreferencesPayload,
        channelPreferences: ChannelPushPreferencesPayload
    ) {
        self.init(
            duration: "",
            userChannelPreferences: channelPreferences,
            userPreferences: userPreferences.compactMapValues { $0 }
        )
    }
}

extension UserPushPreferencesPayload {
    func asModel() -> [PushPreference] {
        values.compactMap { $0?.asModel() }
    }
}

extension [String: PushPreferencesResponse] {
    func asModel() -> [PushPreference] {
        values.map { $0.asModel() }
    }
}

extension ChannelPushPreferencesPayload {
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
    convenience init(duration: String, polls: [PollPayload], next: String? = nil, prev: String? = nil) {
        self.init(duration: duration, next: next, polls: polls, prev: prev)
    }
}

extension PollVoteResponse {
    convenience init(duration: String, vote: PollVotePayload? = nil) {
        self.init(duration: duration, poll: nil, vote: vote)
    }
}

extension PollVotesResponse {
    convenience init(duration: String, votes: [PollVotePayload?], next: String? = nil, prev: String? = nil) {
        self.init(duration: duration, next: next, prev: prev, votes: votes.compactMap { $0 })
    }
}

extension MessageActionRequest {
    convenience init(cid: ChannelId, messageId: MessageId, action: AttachmentAction) {
        self.init(formData: [action.name: action.value])
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
        custom[EventPayload.CodingKeys.eventType.rawValue] = nil
        self.init(event: EventRequest(
            custom: custom.isEmpty ? nil : custom,
            type: type(of: payload).eventType.rawValue
        ))
    }
}

extension SendReactionRequest {
    convenience init(enforceUnique: Bool, skipPush: Bool, reaction: ReactionRequestPayload) {
        self.init(enforceUnique: enforceUnique, reaction: reaction, skipPush: skipPush)
    }
}

extension ReactionResponse {
    var reactionType: MessageReactionType {
        MessageReactionType(rawValue: type)
    }

    var userPayload: UserPayload {
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
        user: UserPayload,
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

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var legacyExtraData = (try? [String: RawJSON](from: decoder)) ?? [:]
        legacyExtraData.removeValues(forKeys: CodingKeys.allCases.map(\.rawValue))

        let userPayload = try container.decode(UserPayload.self, forKey: .user)
        let custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        let extraData = legacyExtraData.merging(custom) { _, openAPIValue in openAPIValue }

        self.init(
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            custom: extraData,
            messageId: try container.decode(MessageId.self, forKey: .messageId),
            score: try container.decode(Int.self, forKey: .score),
            type: try container.decode(String.self, forKey: .type),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt),
            user: userPayload.asUserResponse,
            userId: try container.decodeIfPresent(UserId.self, forKey: .userId) ?? userPayload.id
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

extension FlagResponse {
    var currentUserPayload: CurrentUserPayload {
        userPayload.asCurrentUserPayload
    }

    var userPayload: UserPayload {
        UserPayload(
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

    var targetUserPayload: UserPayload {
        UserPayload(
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

extension UserPayload {
    var asCurrentUserPayload: CurrentUserPayload {
        CurrentUserPayload(
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
    var currentUser: CurrentUserPayload {
        UserPayload(
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
        ).asCurrentUserPayload
    }

    var flaggedUser: UserPayload {
        UserPayload(
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

    convenience init(currentUser: CurrentUserPayload, flaggedUser: UserPayload) {
        self.init(duration: "", itemId: flaggedUser.id)
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
    convenience init(skipPush: Bool, hardDelete: Bool, message: MessageRequestBody?) {
        self.init(
            hardDelete: hardDelete,
            message: message?.asMessageRequest,
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
    convenience init(pollId: String, vote: VoteDataRequestBody? = nil) {
        self.init(vote: vote)
    }
}

extension VoteData {
    convenience init(
        answerText: String? = nil,
        optionId: String? = nil,
        option: PollVoteOptionRequestBody? = nil
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
        options: [PollVoteOptionRequestBody?]? = nil,
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

extension UpdatePollOptionRequestOpenAPI {
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

extension MessageRequestBody {
    var asMessageRequest: MessageRequest {
        let request = MessageRequest(
            attachments: attachments.isEmpty ? nil : attachments,
            custom: extraData.isEmpty ? nil : extraData,
            id: id,
            mentionedUsers: mentionedUserIds.isEmpty ? nil : mentionedUserIds,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pollId: pollId,
            quotedMessageId: quotedMessageId,
            restrictedVisibility: restrictedVisibility,
            sharedLocation: location?.asSharedLocationOpenAPI,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
        request.type = type.flatMap { MessageRequest.MessageRequestType(rawValue: $0) }
        return request
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

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var legacyExtraData = (try? [String: RawJSON](from: decoder)) ?? [:]
        legacyExtraData.removeValues(forKeys: CodingKeys.allCases.map(\.rawValue))

        let openAPICustom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        let mergedCustom = legacyExtraData.merging(openAPICustom) { _, openAPIValue in openAPIValue }

        self.init(
            actions: try container.decodeIfPresent([Action].self, forKey: .actions),
            assetUrl: try container.decodeIfPresent(String.self, forKey: .assetUrl),
            authorIcon: try container.decodeIfPresent(String.self, forKey: .authorIcon),
            authorLink: try container.decodeIfPresent(String.self, forKey: .authorLink),
            authorName: try container.decodeIfPresent(String.self, forKey: .authorName),
            color: try container.decodeIfPresent(String.self, forKey: .color),
            custom: mergedCustom,
            fallback: try container.decodeIfPresent(String.self, forKey: .fallback),
            fields: try container.decodeIfPresent([Field].self, forKey: .fields),
            footer: try container.decodeIfPresent(String.self, forKey: .footer),
            footerIcon: try container.decodeIfPresent(String.self, forKey: .footerIcon),
            giphy: try container.decodeIfPresent(Images.self, forKey: .giphy),
            imageUrl: try container.decodeIfPresent(String.self, forKey: .imageUrl),
            ogScrapeUrl: try container.decodeIfPresent(String.self, forKey: .ogScrapeUrl),
            originalHeight: try container.decodeIfPresent(Int.self, forKey: .originalHeight),
            originalWidth: try container.decodeIfPresent(Int.self, forKey: .originalWidth),
            pretext: try container.decodeIfPresent(String.self, forKey: .pretext),
            text: try container.decodeIfPresent(String.self, forKey: .text),
            thumbUrl: try container.decodeIfPresent(String.self, forKey: .thumbUrl),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            titleLink: try container.decodeIfPresent(String.self, forKey: .titleLink)
        )
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
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

private extension NewLocationRequestPayload {
    var asSharedLocationOpenAPI: SharedLocationOpenAPI {
        SharedLocationOpenAPI(
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

    var channelDetailPayload: ChannelDetailPayload? {
        if let channelPayload = channel?.asChannelDetailPayload {
            return channelPayload
        }
        guard let cid = try? ChannelId(cid: channelCid) else { return nil }
        return ChannelDetailPayload(
            cid: cid,
            name: nil,
            imageURL: nil,
            extraData: [:],
            typeRawValue: cid.type.rawValue,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            deletedAt: nil,
            updatedAt: updatedAt,
            truncatedAt: nil,
            createdBy: createdBy?.asUserPayload,
            config: .init(),
            filterTags: nil,
            ownCapabilities: nil,
            isDisabled: false,
            isFrozen: false,
            isBlocked: false,
            isHidden: nil,
            members: nil,
            memberCount: 0,
            messageCount: nil,
            team: nil,
            cooldownDuration: 0
        )
    }

    var createdByPayload: UserPayload {
        createdBy?.asUserPayload ?? UserPayload.empty
    }

    var parentMessagePayload: MessagePayload? {
        parentMessage?.asMessagePayload ?? MessagePayload(
            id: parentMessageId,
            cid: try? ChannelId(cid: channelCid),
            type: .regular,
            user: createdByPayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            text: "",
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: replyCount ?? 0,
            extraData: [:],
            reactionScores: [:],
            reactionCounts: [:],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            channel: channelDetailPayload
        )
    }

    var latestRepliesPayload: [MessagePayload] {
        latestReplies.compactMap(\.asMessagePayload)
    }

    var readPayload: [ReadStateResponse] { read ?? [] }

    var threadParticipantPayloads: [ThreadParticipantOpenAPI] { threadParticipants ?? [] }

    convenience init(
        parentMessageId: MessageId,
        parentMessage: MessagePayload,
        channel: ChannelDetailPayload,
        createdBy: UserPayload,
        replyCount: Int,
        participantCount: Int,
        activeParticipantCount: Int,
        threadParticipants: [ThreadParticipantOpenAPI],
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        title: String?,
        latestReplies: [MessagePayload],
        read: [ReadStateResponse],
        draft: DraftPayload?,
        extraData: [String: RawJSON]
    ) {
        self.init(
            activeParticipantCount: activeParticipantCount,
            channel: channel.asChannelResponse,
            channelCid: channel.cid.rawValue,
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

    var channelDetailPayload: ChannelDetailPayload? {
        if let channelPayload = channel?.asChannelDetailPayload {
            return channelPayload
        }
        guard let cid = try? ChannelId(cid: channelCid) else { return nil }
        return ChannelDetailPayload(
            cid: cid,
            name: nil,
            imageURL: nil,
            extraData: [:],
            typeRawValue: cid.type.rawValue,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            deletedAt: nil,
            updatedAt: updatedAt,
            truncatedAt: nil,
            createdBy: createdBy?.asUserPayload,
            config: .init(),
            filterTags: nil,
            ownCapabilities: nil,
            isDisabled: false,
            isFrozen: false,
            isBlocked: false,
            isHidden: nil,
            members: nil,
            memberCount: 0,
            messageCount: nil,
            team: nil,
            cooldownDuration: 0
        )
    }

    var createdByPayload: UserPayload {
        createdBy?.asUserPayload ?? UserPayload.empty
    }

    var parentMessagePayload: MessagePayload? {
        parentMessage?.asMessagePayload ?? MessagePayload(
            id: parentMessageId,
            cid: cid,
            type: .regular,
            user: createdByPayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            text: "",
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: replyCount ?? 0,
            extraData: [:],
            reactionScores: [:],
            reactionCounts: [:],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            channel: channelDetailPayload
        )
    }

    convenience init(
        parentMessageId: MessageId,
        parentMessage: MessagePayload,
        channel: ChannelDetailPayload,
        createdBy: UserPayload,
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
            channelCid: channel.cid.rawValue,
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

extension ThreadParticipantOpenAPI {
    var userPayload: UserPayload {
        user?.asUserPayload ?? UserPayload.empty
    }

    convenience init(
        user: UserPayload,
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

private extension UserPayload {
    static var empty: UserPayload {
        UserPayload(
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
