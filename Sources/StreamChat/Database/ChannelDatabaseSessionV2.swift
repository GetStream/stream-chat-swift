//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

protocol ChannelDatabaseSessionV2 {
    /// Creates `ChannelDTO` objects for the given channel payloads and `query`. ignores items that could not be saved
    @discardableResult
    func saveChannelList(
        payload: ChannelsResponse?,
        query: ChannelListQuery?
    ) -> [ChannelDTO]
    
    @discardableResult
    func saveChannel(
        payload: ChannelResponse,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO
    
    @discardableResult
    func saveChannel(
        payload: ChannelResponse
    ) throws -> ChannelDTO
    
    @discardableResult
    func saveChannel(
        payload: ChannelStateResponseFields,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO
    
    @discardableResult
    func saveUser(
        payload: UserObject,
        query: UserListQuery?,
        cache: PreWarmedCache?
    ) throws -> UserDTO
    
    @discardableResult
    func saveUser(
        payload: UserObject
    ) throws -> UserDTO
    
    @discardableResult
    func saveMember(
        payload: ChannelMember,
        channelId: ChannelId,
        query: ChannelMemberListQuery?,
        cache: PreWarmedCache?
    ) throws -> MemberDTO
    
    @discardableResult
    func saveMessage(
        payload: Message,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO
    
    @discardableResult
    func saveChannelRead(
        payload: Read?,
        for cid: String?,
        cache: PreWarmedCache?
    ) throws -> ChannelReadDTO
    
    @discardableResult
    func saveReaction(
        payload: Reaction?,
        cache: PreWarmedCache?
    ) throws -> MessageReactionDTO
    
    @discardableResult
    func saveAttachment(
        payload: Attachment?,
        id: AttachmentId
    ) throws -> AttachmentDTO
    
    @discardableResult
    func saveMessage(
        payload: Message,
        for cid: ChannelId?,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO
    
    @discardableResult
    func saveCurrentUser(payload: OwnUser) throws -> CurrentUserDTO
    
    @discardableResult
    func saveMembers(
        payload: MembersResponse,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) -> [MemberDTO]
    
    @discardableResult
    func saveCurrentUserDevices(
        _ devices: [Device],
        clearExisting: Bool
    ) throws -> [DeviceDTO]
    
    func saveMessages(
        messagesPayload: GetRepliesResponse,
        for cid: ChannelId?,
        syncOwnReactions: Bool
    ) -> [MessageDTO]
    
    func saveReactions(
        payload: GetReactionsResponse
    ) -> [MessageReactionDTO]
    
    @discardableResult
    func saveMessageSearch(
        payload: SearchResponse,
        for query: MessageSearchQuery
    ) -> [MessageDTO]
    
    @discardableResult
    func saveUsers(payload: UsersResponse, query: UserListQuery?) -> [UserDTO]
    
    @discardableResult
    func saveChannelMute(payload: ChannelMute?) throws -> ChannelMuteDTO
    
    @discardableResult
    func saveMessage(payload: Message, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO
}

extension NSManagedObjectContext {
    func saveChannelList(
        payload: ChannelsResponse?,
        query: ChannelListQuery?
    ) -> [ChannelDTO] {
        guard let payload else { return [] }
        let cache = payload.getPayloadToModelIdMappings(context: self)

        // The query will be saved during `saveChannel` call
        // but in case this query does not have any channels,
        // the query won't be saved, which will cause any future
        // channels to not become linked to this query
        if let query = query {
            _ = saveQuery(query: query)
        }

        return payload.channels.compactMapLoggingError { channelPayload in
            try saveChannel(payload: channelPayload, query: query, cache: cache)
        }
    }

    @discardableResult
    func saveChannel(
        payload: ChannelResponse,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO {
        let cid = try ChannelId(cid: payload.cid)
        let dto = ChannelDTO.loadOrCreate(cid: cid, context: self, cache: cache)

        dto.name = payload.custom?["name"]?.stringValue
        // TODO: revisit this.
        dto.imageURL = URL(string: payload.custom?["image"]?.stringValue ?? "")
        do {
            dto.extraData = try JSONEncoder.default.encode(payload.custom)
        } catch {
            log.error(
                "Failed to decode extra payload for Channel with cid: <\(dto.cid)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }
        dto.typeRawValue = payload.type
        if let config = payload.config?.asDTO(context: self, cid: dto.cid) {
            dto.config = config
        }
        if let ownCapabilities = payload.ownCapabilities {
            dto.ownCapabilities = ownCapabilities
        }
        dto.createdAt = payload.createdAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.defaultSortingAt = (payload.lastMessageAt ?? payload.createdAt)?.bridgeDate ?? Date().bridgeDate
        dto.lastMessageAt = payload.lastMessageAt?.bridgeDate
        dto.memberCount = Int64(clamping: payload.memberCount ?? 0)

        // Because `truncatedAt` is used, client side, for both truncation and channel hiding cases, we need to avoid using the
        // value returned by the Backend in some cases.
        //
        // Whenever our Backend is not returning a value for `truncatedAt`, we simply do nothing. It is possible that our
        // DTO already has a value for it if it has been hidden in the past, but we are not touching it.
        //
        // Whenever we do receive a value from our Backend, we have 2 options:
        //  1. If we don't have a value for `truncatedAt` in the DTO -> We set the date from the payload
        //  2. If we have a value for `truncatedAt` in the DTO -> We pick the latest date.
        if let newTruncatedAt = payload.truncatedAt {
            let canUpdateTruncatedAt = dto.truncatedAt.map { $0.bridgeDate < newTruncatedAt } ?? true
            if canUpdateTruncatedAt {
                dto.truncatedAt = newTruncatedAt.bridgeDate
            }
        }

        dto.isFrozen = payload.frozen

        // Backend only returns a boolean for hidden state
        // on channel query and channel list query
        if let isHidden = payload.hidden {
            dto.isHidden = isHidden
        }

        dto.cooldownDuration = payload.cooldown ?? 0
        dto.team = payload.team

        if let createdByPayload = payload.createdBy {
            let creatorDTO = try saveUser(payload: createdByPayload, query: nil, cache: cache)
            dto.createdBy = creatorDTO
        }

        try payload.members?.forEach { memberPayload in
            if let memberPayload, let cid = try? ChannelId(cid: payload.cid) {
                let member = try saveMember(payload: memberPayload, channelId: cid, query: nil, cache: cache)
                dto.members.insert(member)
            }
        }

        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.channels.insert(dto)
        }

        return dto
    }
    
    @discardableResult
    func saveChannel(
        payload: ChannelResponse
    ) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil, cache: nil)
    }

    func saveChannel(
        payload: ChannelStateResponseFields,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO {
        guard let channel = payload.channel else { throw ClientError.Unknown() }
        let dto = try saveChannel(payload: channel, query: query, cache: cache)

        let readsArray = try payload.read?.compactMap {
            try saveChannelRead(payload: $0, for: payload.channel?.cid, cache: cache)
        } ?? []
        let reads = Set(readsArray)
        dto.reads.subtracting(reads).forEach { delete($0) }
        dto.reads = reads

        try payload.messages.forEach { _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true, cache: cache) }
        
        if dto.needsPreviewUpdate(payload), let payloadCid = payload.channel?.cid, let cid = try? ChannelId(cid: payloadCid) {
            dto.previewMessage = preview(for: cid)
        }

        dto.updateOldestMessageAt(payload: payload)

        try payload.pinnedMessages.forEach {
            _ = try saveMessage(payload: $0, channelDTO: dto, syncOwnReactions: true, cache: cache)
        }

        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        try payload.members.forEach {
            if let item = $0, let cidValue = payload.channel?.cid, let cid = try? ChannelId(cid: cidValue) {
                let member = try saveMember(payload: item, channelId: cid, query: nil, cache: cache)
                dto.members.insert(member)
            }
        }

        if let membership = payload.membership {
            if let cidValue = payload.channel?.cid, let cid = try? ChannelId(cid: cidValue) {
                let membership = try saveMember(payload: membership, channelId: cid, query: nil, cache: cache)
                dto.membership = membership
            }
        } else {
            dto.membership = nil
        }

        dto.watcherCount = Int64(clamping: payload.watcherCount ?? 0)

        if let watchers = payload.watchers {
            // We don't call `removeAll` on watchers since user could've requested
            // a different page
            try watchers.forEach {
                let user = try saveUser(payload: $0, query: nil, cache: cache)
                dto.watchers.insert(user)
            }
        }
        // We don't reset `watchers` array if it's missing
        // since that can mean that user didn't request watchers
        // This is done in `ChannelUpdater.channelWatchers` func

        return dto
    }
}

extension ChannelConfigWithInfo {
    func asDTO(context: NSManagedObjectContext, cid: String) -> ChannelConfigDTO {
        let request = NSFetchRequest<ChannelConfigDTO>(entityName: ChannelConfigDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid)

        let dto: ChannelConfigDTO
        if let loadedDto = ChannelConfigDTO.load(by: request, context: context).first {
            dto = loadedDto
        } else {
            dto = NSEntityDescription.insertNewObject(into: context, for: request)
        }

        dto.reactionsEnabled = reactions
        dto.typingEventsEnabled = typingEvents
        dto.readEventsEnabled = readEvents
        dto.connectEventsEnabled = connectEvents
        dto.uploadsEnabled = uploads
        dto.repliesEnabled = replies
        dto.quotesEnabled = quotes
        dto.searchEnabled = search
        dto.mutesEnabled = mutes
        dto.urlEnrichmentEnabled = urlEnrichment
        dto.messageRetention = messageRetention
        dto.maxMessageLength = Int32(maxMessageLength)
        dto.createdAt = createdAt.bridgeDate
        dto.updatedAt = updatedAt.bridgeDate
        dto.commands = NSOrderedSet(array: commands.compactMap { $0?.asDTO(context: context) })
        return dto
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveUser(
        payload: UserObject
    ) throws -> UserDTO {
        try saveUser(payload: payload, query: nil, cache: nil)
    }
    
    @discardableResult
    func saveUser(
        payload: UserObject,
        query: UserListQuery?,
        cache: PreWarmedCache?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self, cache: cache)

        dto.name = payload.custom?["name"]?.stringValue
        dto.imageURL = URL(string: payload.custom?["image"]?.stringValue ?? "")
        dto.isBanned = payload.banned ?? false
        dto.isOnline = payload.online ?? false
        dto.lastActivityAt = payload.lastActive?.bridgeDate
        dto.userCreatedAt = (payload.createdAt ?? Date()).bridgeDate
        dto.userRoleRaw = payload.role ?? "member"
        dto.userUpdatedAt = (payload.updatedAt ?? Date()).bridgeDate
        dto.userDeactivatedAt = payload.deactivatedAt?.bridgeDate
        dto.language = payload.language

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.custom ?? [:])
        } catch {
            log.error(
                "Failed to decode extra payload for User with id: <\(payload.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        dto.teams = payload.teams ?? []

        // payloadHash doesn't cover the query
        if let query = query, let queryDTO = try saveQuery(query: query) {
            queryDTO.users.insert(dto)
        }
        return dto
    }
    
    func saveMember(
        payload: ChannelMember,
        channelId: ChannelId,
        query: ChannelMemberListQuery?,
        cache: PreWarmedCache?
    ) throws -> MemberDTO {
        let dto = MemberDTO.loadOrCreate(userId: payload.userId ?? .newUniqueId, channelId: channelId, context: self, cache: cache)

        // Save user-part of member first
        if let userPayload = payload.user {
            dto.user = try saveUser(payload: userPayload, query: nil, cache: cache)
        }

        // Save member specific data
        dto.channelRoleRaw = payload.channelRole

        dto.memberCreatedAt = payload.createdAt.bridgeDate
        dto.memberUpdatedAt = payload.updatedAt.bridgeDate
        dto.isBanned = payload.banned
        dto.isShadowBanned = payload.shadowBanned
        dto.banExpiresAt = payload.banExpires?.bridgeDate
        dto.isInvited = payload.invited ?? false
        dto.inviteAcceptedAt = payload.inviteAcceptedAt?.bridgeDate
        dto.inviteRejectedAt = payload.inviteRejectedAt?.bridgeDate

        if let query = query {
            let queryDTO = try saveQuery(query)
            queryDTO.members.insert(dto)
        }

        if let channelDTO = channel(cid: channelId) {
            channelDTO.members.insert(dto)
        }

        return dto
    }
}

extension NSManagedObjectContext {
    func saveMessage(
        payload: Message,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        let cid = try ChannelId(cid: channelDTO.cid)
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self, cache: cache)

        if dto.localMessageState == .pendingSend || dto.localMessageState == .pendingSync {
            return dto
        }

        dto.cid = payload.cid
        dto.text = payload.text
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.type = payload.type
        dto.command = payload.command
//        dto.args = payload.args //TODO: what is this?
        dto.parentMessageId = payload.parentId
        dto.showReplyInChannel = payload.showInChannel ?? false
        dto.replyCount = Int32(payload.replyCount)

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.custom)
        } catch {
            log.error(
                "Failed to decode extra payload for Message with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        dto.isSilent = payload.silent
        dto.isShadowed = payload.shadowed
        // Due to backend not working as advertised
        // (sending `shadowed: true` flag to the shadow banned user)
        // we have to implement this workaround to get the advertised behavior
        // info on slack: https://getstream.slack.com/archives/CE5N802GP/p1635785568060500
        // TODO: Remove the workaround once backend bug is fixed
        if currentUser?.user.id == payload.user?.id {
            dto.isShadowed = false
        }

        dto.pinned = payload.pinned
        dto.pinExpires = payload.pinExpires?.bridgeDate
        dto.pinnedAt = payload.pinnedAt?.bridgeDate
        if let pinnedByUser = payload.pinnedBy {
            dto.pinnedBy = try saveUser(payload: pinnedByUser, query: nil, cache: cache)
        }

        if dto.pinned && !channelDTO.pinnedMessages.contains(dto) {
            channelDTO.pinnedMessages.insert(dto)
        } else {
            channelDTO.pinnedMessages.remove(dto)
        }

        if let quotedMessageId = payload.quotedMessageId,
           let quotedMessage = message(id: quotedMessageId) {
            // In case we do not have a fully formed quoted message in the payload,
            // we check for quotedMessageId. This can happen in the case of nested quoted messages.
            dto.quotedMessage = quotedMessage
        } else if let quotedMessage = payload.quotedMessage {
            dto.quotedMessage = try saveMessage(
                payload: quotedMessage,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: cache
            )
        } else {
            dto.quotedMessage = nil
        }

        if let payloadUser = payload.user {
            let user = try saveUser(payload: payloadUser, query: nil, cache: cache)
            dto.user = user
        }

        dto.reactionScores = payload.reactionScores
        // TODO: check why was this scores.
        dto.reactionCounts = payload.reactionCounts

        // If user edited their message to remove mentioned users, we need to get rid of it
        // as backend does
        dto.mentionedUsers = try Set(payload.mentionedUsers.map {
            let user = try saveUser(payload: $0, query: nil, cache: cache)
            return user
        })

        // If user participated in thread, but deleted message later, we need to get rid of it if backends does
        let threadParticipants = try payload.threadParticipants?.map {
            try saveUser(payload: $0, query: nil, cache: cache)
        } ?? []
        dto.threadParticipants = NSOrderedSet(array: threadParticipants)

        channelDTO.lastMessageAt = max(channelDTO.lastMessageAt?.bridgeDate ?? payload.createdAt, payload.createdAt).bridgeDate
        
        dto.channel = channelDTO

        dto.latestReactions = payload
            .latestReactions
            .compactMap { try? saveReaction(payload: $0, cache: cache) }
            .map(\.id)

        if syncOwnReactions {
            dto.ownReactions = payload
                .ownReactions
                .compactMap { try? saveReaction(payload: $0, cache: cache) }
                .map(\.id)
        }

        let attachments: Set<AttachmentDTO> = try Set(
            payload.attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: payload.id, index: index)
                let dto = try saveAttachment(payload: attachment, id: id)
                return dto
            }
        )
        dto.attachments = attachments

        // Only insert message into Parent's replies if not already present.
        // This in theory would not be needed since replies is a Set, but
        // it will trigger an FRC update, which will cause the message to disappear
        // in the Message List if there is already a message with the same ID.
        if let parentMessageId = payload.parentId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self),
           !parentMessageDTO.replies.contains(dto) {
            parentMessageDTO.replies.insert(dto)
        }

        dto.translations = payload.i18n
        dto.originalLanguage = payload.i18n?["language"] as? String
        
//        if let moderationDetailsPayload = payload.moderationDetails {
//            dto.moderationDetails = MessageModerationDetailsDTO.create(
//                from: moderationDetailsPayload,
//                context: self
//            )
//        } else {
//            dto.moderationDetails = nil
//        }

        // Calculate reads if the message is authored by the current user.
        if payload.user?.id == currentUser?.user.id {
            dto.reads = Set(
                channelDTO.reads.filter {
                    $0.lastReadAt.bridgeDate >= payload.createdAt && $0.user.id != payload.user?.id
                }
            )
        }

        // Refetch channel preview if the current preview has changed.
        //
        // The current message can stop being a valid preview e.g.
        // if it didn't pass moderation and obtained `error` type.
        if payload.id == channelDTO.previewMessage?.id {
            channelDTO.previewMessage = preview(for: cid)
        }

        return dto
    }
}

extension ChannelDTO {
    func needsPreviewUpdate(_ payload: ChannelStateResponseFields) -> Bool {
        guard let first = payload.messages.first, let last = payload.messages.last else { return false }

        let newestMessage = first.createdAt > last.createdAt ? first : last
        
        guard let preview = previewMessage else {
            return true
        }

        return newestMessage.createdAt > preview.createdAt.bridgeDate
    }
    
    func updateOldestMessageAt(payload: ChannelStateResponseFields) {
        guard let payloadOldestMessageAt = payload.messages.map(\.createdAt).min() else { return }
        let isOlderThanCurrentOldestMessage = payloadOldestMessageAt < (oldestMessageAt?.bridgeDate ?? Date.distantFuture)
        if isOlderThanCurrentOldestMessage {
            oldestMessageAt = payloadOldestMessageAt.bridgeDate
        }
    }
}

extension NSManagedObjectContext {
    func saveChannelRead(
        payload: Read?,
        for cid: String?,
        cache: PreWarmedCache?
    ) throws -> ChannelReadDTO {
        guard let payload, let user = payload.user, let cid else { throw ClientError.Unknown() }
        
        let channelId = try ChannelId(cid: cid)
        let dto = ChannelReadDTO.loadOrCreate(cid: channelId, userId: user.id, context: self, cache: cache)

        dto.user = try saveUser(payload: user, query: nil, cache: cache)

        dto.lastReadAt = payload.lastRead.bridgeDate
        dto.lastReadMessageId = payload.lastReadMessageId
        dto.unreadMessageCount = Int32(payload.unreadMessages)

        return dto
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveReaction(
        payload: Reaction?,
        cache: PreWarmedCache?
    ) throws -> MessageReactionDTO {
        guard let payload, let user = payload.user, let messageDTO = message(id: payload.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: payload?.messageId ?? "")
        }

        let dto = MessageReactionDTO.loadOrCreate(
            message: messageDTO,
            type: MessageReactionType(rawValue: payload.type),
            user: try saveUser(payload: user, query: nil, cache: cache),
            context: self,
            cache: cache
        )

        dto.score = Int64(clamping: payload.score)
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.extraData = try JSONEncoder.default.encode(payload.custom)
        dto.localState = nil
        dto.version = nil

        return dto
    }
}

extension NSManagedObjectContext {
    func saveAttachment(
        payload: Attachment?,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let payload, let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)

        dto.attachmentType = payload.type
        dto.data = try JSONEncoder.default.encode(payload)
        dto.message = messageDTO

        dto.localURL = nil
        dto.localState = nil

        return dto
    }
}

extension NSManagedObjectContext {
    func saveMessage(
        payload: Message,
        for cid: ChannelId?,
        syncOwnReactions: Bool = true,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        guard let cid else {
            throw ClientError.MessagePayloadSavingFailure("""
            `cid` must be provided to sucessfuly save the message payload.
            - `cid` value: \(String(describing: cid))
            """)
        }

        var channelDTO: ChannelDTO?
        channelDTO = ChannelDTO.load(cid: cid, context: self)

        guard let channel = channelDTO else {
            let description = "Should never happen, a channel should have been fetched."
            log.assertionFailure(description)
            throw ClientError.MessagePayloadSavingFailure(description)
        }

        return try saveMessage(payload: payload, channelDTO: channel, syncOwnReactions: syncOwnReactions, cache: cache)
    }
}

extension NSManagedObjectContext {
    func saveCurrentUser(payload: OwnUser) throws -> CurrentUserDTO {
        let dto = CurrentUserDTO.loadOrCreate(context: self)
        dto.user = try saveUser(payload: payload, query: nil, cache: nil)
        dto.isInvisible = payload.invisible ?? false

        let mutedUsers = try payload.mutes.compactMap {
            if let user = $0?.user {
                return try saveUser(payload: user, query: nil, cache: nil)
            } else {
                return nil
            }
        }
        dto.mutedUsers = Set(mutedUsers)

        let channelMutes = Set(
            try payload.channelMutes.map { try saveChannelMute(payload: $0) }
        )
        dto.channelMutes.subtracting(channelMutes).forEach { delete($0) }
        dto.channelMutes = channelMutes

        try saveCurrentUserUnreadCount(
            count: UnreadCount(
                channels: payload.unreadChannels,
                messages: payload.totalUnreadCount
            )
        )

        _ = try saveCurrentUserDevices(payload.devices, clearExisting: true)

        return dto
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveChannelMute(payload: ChannelMute?) throws -> ChannelMuteDTO {
        guard let currentUser = currentUser, let payload, let mutedChannel = payload.channel else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        let cid = try ChannelId(cid: mutedChannel.cid)
        let channel = try saveChannel(payload: mutedChannel, query: nil, cache: nil)
        let dto = ChannelMuteDTO.loadOrCreate(cid: cid, context: self)
        dto.channel = channel
        dto.currentUser = currentUser
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate

        return dto
    }
}

extension NSManagedObjectContext {
    func saveCurrentUserDevices(_ devices: [Device], clearExisting: Bool) throws -> [DeviceDTO] {
        guard let currentUser = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        if clearExisting {
            currentUser.devices.removeAll()
            if !devices.contains(where: { $0.id == currentUser.currentDevice?.id }) {
                currentUser.currentDevice = nil
            }
        }

        let deviceDTOs = devices.map { device -> DeviceDTO in
            let dto = DeviceDTO.loadOrCreate(id: device.id, context: self)
            dto.createdAt = device.createdAt.bridgeDate
            dto.user = currentUser
            return dto
        }

        return deviceDTOs
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveUser(
        payload: OwnUser,
        query: UserListQuery?,
        cache: PreWarmedCache?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self, cache: cache)

        dto.name = payload.custom?["name"]?.stringValue
        dto.imageURL = URL(string: payload.custom?["image"]?.stringValue ?? "")
        dto.isBanned = payload.banned
        dto.isOnline = payload.online
        dto.lastActivityAt = payload.lastActive?.bridgeDate
        dto.userCreatedAt = payload.createdAt.bridgeDate
        dto.userRoleRaw = payload.role
        dto.userUpdatedAt = payload.updatedAt.bridgeDate
        dto.userDeactivatedAt = payload.deactivatedAt?.bridgeDate
        dto.language = payload.language

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.custom)
        } catch {
            log.error(
                "Failed to decode extra payload for User with id: <\(payload.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        dto.teams = payload.teams ?? []

        // payloadHash doesn't cover the query
        if let query = query, let queryDTO = try saveQuery(query: query) {
            queryDTO.users.insert(dto)
        }
        return dto
    }
}

extension NSManagedObjectContext {
    func saveMembers(
        payload: MembersResponse,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) -> [MemberDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.members.compactMapLoggingError {
            if let member = $0 {
                return try saveMember(payload: member, channelId: channelId, query: query, cache: cache)
            } else {
                return nil
            }
        }
    }
}

extension NSManagedObjectContext {
    func saveMessages(
        messagesPayload: GetRepliesResponse,
        for cid: ChannelId?,
        syncOwnReactions: Bool = true
    ) -> [MessageDTO] {
        let cache = messagesPayload.getPayloadToModelIdMappings(context: self)
        return messagesPayload.messages.compactMapLoggingError {
            try saveMessage(payload: $0, for: cid, syncOwnReactions: syncOwnReactions, cache: cache)
        }
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveReactions(payload: GetReactionsResponse) -> [MessageReactionDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.reactions.compactMapLoggingError {
            try saveReaction(payload: $0, cache: cache)
        }
    }
}

extension NSManagedObjectContext {
    func saveMessageSearch(payload: SearchResponse, for query: MessageSearchQuery) -> [MessageDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.results.compactMapLoggingError {
            if let message = $0?.message {
                return try saveMessage(
                    payload: message.toMessage,
                    for: query,
                    cache: cache
                )
            } else {
                return nil
            }
        }
    }
}

extension NSManagedObjectContext {
    func saveMessage(payload: Message, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO {
        let cid = try ChannelId(cid: payload.cid)
        let messageDTO = try saveMessage(payload: payload, for: cid, cache: cache)
        messageDTO.searches.insert(saveQuery(query: query))
        return messageDTO
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveUsers(payload: UsersResponse, query: UserListQuery?) -> [UserDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.users.compactMapLoggingError {
            if let user = $0?.toUser {
                return try saveUser(payload: user, query: query, cache: cache)
            } else {
                return nil
            }
        }
    }
}
