//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channels query call to the backend and updates the local storage with the results.
class ChannelListUpdater: Worker {
    /// Makes a channels query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelListQuery: The channels query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(
        channelListQuery: ChannelListQuery,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        fetch(channelListQuery: channelListQuery) { [weak self] in
            switch $0 {
            case let .success(channelListPayload):
                let isInitialFetch = channelListQuery.pagination.cursor == nil && channelListQuery.pagination.offset == 0
                var initialActions: ((DatabaseSession) -> Void)?
                if isInitialFetch {
                    initialActions = { session in
                        let filterHash = channelListQuery.filter.filterHash
                        guard let queryDTO = session.channelListQuery(filterHash: filterHash) else { return }
                        queryDTO.channels.removeAll()
                    }
                }

                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: channelListQuery,
                    initialActions: initialActions,
                    completion: completion
                )
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    func prefill(
        channels: [ChatChannel],
        for query: ChannelListQuery,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        var savedChannels: [ChatChannel] = []
        database.write { session in
            let queryDTO = session.saveQuery(query: query)
            queryDTO.channels.removeAll()

            savedChannels = channels.compactMapLoggingError { channel in
                let payload = channel.asPrefillPayload()
                let channelDTO = try session.saveChannel(payload: payload, query: nil, cache: nil)
                queryDTO.channels.insert(channelDTO)
                return try channelDTO.asModel()
            }
        } completion: { error in
            if let error {
                completion?(.failure(error))
            } else {
                completion?(.success(savedChannels))
            }
        }
    }

    func refreshLoadedChannels(for query: ChannelListQuery, channelCount: Int, completion: @escaping (Result<Set<ChannelId>, Error>) -> Void) {
        guard channelCount > 0 else {
            completion(.success(Set()))
            return
        }
        
        var allPages = [ChannelListQuery]()
        let pageSize = query.pagination.pageSize > 0 ? query.pagination.pageSize : .channelsPageSize
        for offset in stride(from: 0, to: channelCount, by: pageSize) {
            var pageQuery = query
            pageQuery.pagination = Pagination(pageSize: .channelsPageSize, offset: offset)
            allPages.append(pageQuery)
        }
        refreshLoadedChannels(for: allPages, refreshedChannelIds: Set(), completion: completion)
    }
    
    func refreshLoadedChannels(for query: ChannelListQuery, channelCount: Int) async throws -> Set<ChannelId> {
        try await withCheckedThrowingContinuation { continuation in
            refreshLoadedChannels(for: query, channelCount: channelCount) { result in
                continuation.resume(with: result)
            }
        }
    }
        
    private func refreshLoadedChannels(for pageQueries: [ChannelListQuery], refreshedChannelIds: Set<ChannelId>, completion: @escaping (Result<Set<ChannelId>, Error>) -> Void) {
        guard let nextQuery = pageQueries.first else {
            completion(.success(refreshedChannelIds))
            return
        }
        
        let remaining = pageQueries.dropFirst()
        fetch(channelListQuery: nextQuery) { [weak self] result in
            switch result {
            case .success(let channelListPayload):
                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: nextQuery,
                    completion: { writeResult in
                        switch writeResult {
                        case .success(let writtenChannels):
                            self?.refreshLoadedChannels(
                                for: Array(remaining),
                                refreshedChannelIds: refreshedChannelIds.union(writtenChannels.map(\.cid)),
                                completion: completion
                            )
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Starts watching the channels with the given ids and updates the channels in the local storage.
    ///
    /// - Parameters:
    ///   - ids: The channel ids.
    ///   - completion: The callback once the request is complete.
    func startWatchingChannels(withIds ids: [ChannelId], completion: ((Error?) -> Void)? = nil) {
        var query = ChannelListQuery(filter: .in(.cid, values: ids))
        query.options = .all

        fetch(channelListQuery: query) { [weak self] in
            switch $0 {
            case let .success(payload):
                self?.database.write { session in
                    session.saveChannelList(payload: payload, query: nil)
                } completion: { _ in
                    completion?(nil)
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }

    /// Fetches the given query from the API and returns results via completion.
    ///
    /// - Parameters:
    ///   - channelListQuery: The query to fetch from the API.
    ///   - completion: The completion to call with the results.
    func fetch(
        channelListQuery: ChannelListQuery,
        completion: @escaping (Result<ChannelListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .channels(query: channelListQuery),
            completion: completion
        )
    }

    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }

    /// Links a channel to the given query.
    func link(channel: ChatChannel, with query: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.insert(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }

    /// Unlinks a channel to the given query.
    func unlink(channel: ChatChannel, with query: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.remove(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }
}

extension DatabaseSession {
    func getChannelWithQuery(cid: ChannelId, query: ChannelListQuery) -> (ChannelDTO, ChannelListQueryDTO)? {
        guard let queryDTO = channelListQuery(filterHash: query.filter.filterHash) else {
            log.debug("Channel list query has not yet created \(query)")
            return nil
        }

        guard let channelDTO = channel(cid: cid) else {
            log.debug("Channel \(cid) cannot be found in database.")
            return nil
        }

        return (channelDTO, queryDTO)
    }
}

private extension ChannelListUpdater {
    func writeChannelListPayload(
        payload: ChannelListPayload,
        query: ChannelListQuery,
        initialActions: ((DatabaseSession) -> Void)? = nil,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        var channels: [ChatChannel] = []
        database.write { session in
            initialActions?(session)
            channels = session.saveChannelList(payload: payload, query: query).compactMap { try? $0.asModel() }
        } completion: { error in
            if let error = error {
                log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                completion?(.failure(error))
            } else {
                completion?(.success(channels))
            }
        }
    }
}

extension ChannelListUpdater {
    @discardableResult func update(channelListQuery: ChannelListQuery) async throws -> [ChatChannel] {
        try await withCheckedThrowingContinuation { continuation in
            update(channelListQuery: channelListQuery) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadChannels(query: ChannelListQuery, pagination: Pagination) async throws -> [ChatChannel] {
        try await update(channelListQuery: query.withPagination(pagination))
    }
    
    func loadNextChannels(
        query: ChannelListQuery,
        limit: Int,
        loadedChannelsCount: Int
    ) async throws -> [ChatChannel] {
        let pagination = Pagination(pageSize: limit, offset: loadedChannelsCount)
        return try await update(channelListQuery: query.withPagination(pagination))
    }
}

private extension ChannelListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}

private extension ChatChannel {
    func asPrefillPayload() -> ChannelPayload {
        ChannelPayload(
            channel: ChannelDetailPayload(
                cid: cid,
                name: name,
                imageURL: imageURL,
                extraData: extraData,
                typeRawValue: cid.type.rawValue,
                lastMessageAt: lastMessageAt,
                createdAt: createdAt,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                truncatedAt: truncatedAt,
                createdBy: createdBy?.asPayload(),
                config: config,
                filterTags: Array(filterTags),
                ownCapabilities: ownCapabilities.map(\.rawValue),
                isDisabled: isDisabled,
                isFrozen: isFrozen,
                isBlocked: isBlocked,
                isHidden: isHidden,
                members: nil,
                memberCount: memberCount,
                messageCount: messageCount,
                team: team,
                cooldownDuration: cooldownDuration
            ),
            watcherCount: watcherCount,
            watchers: lastActiveWatchers.map { $0.asPayload() },
            members: lastActiveMembers.map { $0.asPayload() },
            membership: membership?.asPayload(),
            messages: latestMessages.map { $0.asPayload() },
            pendingMessages: pendingMessages.map { $0.asPayload() },
            pinnedMessages: pinnedMessages.map { $0.asPayload() },
            channelReads: reads.map { $0.asPayload() },
            isHidden: isHidden,
            draft: draftMessage?.asPayload(),
            activeLiveLocations: activeLiveLocations.map { $0.asPayload() },
            pushPreference: pushPreference?.asPayload()
        )
    }
}

private extension ChatUser {
    func asPayload() -> UserPayload {
        UserPayload(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRole,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
            deactivatedAt: userDeactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: false,
            isBanned: isBanned,
            teams: Array(teams),
            language: language?.languageCode,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}

private extension ChatChannelMember {
    func asPayload() -> MemberPayload {
        MemberPayload(
            user: asUserPayload(),
            userId: id,
            role: memberRole,
            createdAt: memberCreatedAt,
            updatedAt: memberUpdatedAt,
            banExpiresAt: banExpiresAt,
            isBanned: isBannedFromChannel,
            isShadowBanned: isShadowBannedFromChannel,
            isInvited: isInvited,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt,
            notificationsMuted: notificationsMuted,
            extraData: memberExtraData
        )
    }

    private func asUserPayload() -> UserPayload {
        UserPayload(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRole,
            createdAt: userCreatedAt,
            updatedAt: userUpdatedAt,
            deactivatedAt: userDeactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: false,
            isBanned: isBanned,
            teams: Array(teams),
            language: language?.languageCode,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}

private extension ChatChannelRead {
    func asPayload() -> ChannelReadPayload {
        ChannelReadPayload(
            user: user.asPayload(),
            lastReadAt: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            unreadMessagesCount: unreadMessagesCount,
            lastDeliveredAt: lastDeliveredAt,
            lastDeliveredMessageId: lastDeliveredMessageId
        )
    }
}

private extension ChatMessage {
    func asPayload(depth: Int = 0) -> MessagePayload {
        MessagePayload(
            id: id,
            cid: cid,
            type: type,
            user: author.asPayload(),
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            text: text,
            command: command,
            args: arguments,
            parentId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            quotedMessageId: quotedMessage?.id,
            quotedMessage: depth < 1 ? quotedMessage?.asPayload(depth: depth + 1) : nil,
            mentionedUsers: mentionedUsers.map { $0.asPayload() },
            threadParticipants: threadParticipants.map { $0.asPayload() },
            replyCount: replyCount,
            extraData: extraData,
            latestReactions: latestReactions.map { $0.asPayload(messageId: id) },
            ownReactions: currentUserReactions.map { $0.asPayload(messageId: id) },
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups.mapValues { $0.asPayload() },
            isSilent: isSilent,
            isShadowed: isShadowed,
            attachments: allAttachments.compactMap { $0.asPayload() },
            channel: nil,
            pinned: isPinned,
            pinnedBy: pinDetails?.pinnedBy.asPayload(),
            pinnedAt: pinDetails?.pinnedAt,
            pinExpires: pinDetails?.expiresAt,
            translations: translations,
            originalLanguage: originalLanguage?.languageCode,
            moderation: moderationDetails?.asPayload(),
            moderationDetails: moderationDetails?.asPayload(),
            messageTextUpdatedAt: textUpdatedAt,
            poll: poll?.asPayload(),
            draft: draftReply?.asPayload(),
            reminder: reminder?.asPayload(cid: cid, messageId: id),
            location: sharedLocation?.asPayload(),
            member: MemberInfoPayload(channelRole: channelRole),
            deletedForMe: deletedForMe
        )
    }
}

private extension ChatMessageReaction {
    func asPayload(messageId: MessageId) -> MessageReactionPayload {
        MessageReactionPayload(
            type: type,
            score: score,
            messageId: messageId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            user: author.asPayload(),
            extraData: extraData
        )
    }
}

private extension ChatMessageReactionGroup {
    func asPayload() -> MessageReactionGroupPayload {
        MessageReactionGroupPayload(
            sumScores: sumScores,
            count: count,
            firstReactionAt: firstReactionAt,
            lastReactionAt: lastReactionAt
        )
    }
}

private extension AnyChatMessageAttachment {
    func asPayload() -> MessageAttachmentPayload? {
        guard let rawPayload = try? JSONDecoder.stream.decode(RawJSON.self, from: payload) else {
            return nil
        }

        return MessageAttachmentPayload(type: type, payload: rawPayload)
    }
}

private extension DraftMessage {
    func asPayload(depth: Int = 0) -> DraftPayload {
        DraftPayload(
            cid: cid,
            channelPayload: nil,
            createdAt: createdAt,
            message: DraftMessagePayload(
                id: id,
                text: text,
                command: command,
                args: arguments,
                showReplyInChannel: showReplyInChannel,
                mentionedUsers: mentionedUsers.map { $0.asPayload() },
                extraData: extraData,
                attachments: attachments.compactMap { $0.asPayload() },
                isSilent: isSilent
            ),
            quotedMessage: depth < 1 ? quotedMessage?.asPayload(depth: depth + 1) : nil,
            parentId: threadId,
            parentMessage: nil
        )
    }
}

private extension MessageReminderInfo {
    func asPayload(cid: ChannelId?, messageId: MessageId) -> ReminderPayload? {
        guard let cid else { return nil }
        return ReminderPayload(
            channelCid: cid,
            messageId: messageId,
            remindAt: remindAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension SharedLocation {
    func asPayload() -> SharedLocationPayload {
        SharedLocationPayload(
            channelId: channelId.rawValue,
            messageId: messageId,
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
            updatedAt: updatedAt,
            endAt: endAt,
            createdByDeviceId: createdByDeviceId
        )
    }
}

private extension PushPreference {
    func asPayload() -> PushPreferencePayload {
        PushPreferencePayload(
            chatLevel: level.rawValue,
            disabledUntil: disabledUntil
        )
    }
}

private extension MessageModerationDetails {
    func asPayload() -> MessageModerationDetailsPayload {
        MessageModerationDetailsPayload(
            originalText: originalText,
            action: action.rawValue,
            textHarms: textHarms,
            imageHarms: imageHarms,
            blocklistMatched: blocklistMatched,
            semanticFilterMatched: semanticFilterMatched,
            platformCircumvented: platformCircumvented
        )
    }
}

private extension Poll {
    func asPayload() -> PollPayload {
        PollPayload(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt,
            createdById: createdBy?.id ?? "",
            description: pollDescription ?? "",
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            name: name,
            updatedAt: updatedAt ?? createdAt,
            voteCount: voteCount,
            latestAnswers: latestAnswers.map { Optional($0.asPayload()) },
            options: options.map { Optional($0.asPayload()) },
            ownVotes: ownVotes.map { Optional($0.asPayload()) },
            custom: extraData,
            latestVotesByOption: Dictionary(
                uniqueKeysWithValues: options.map { option in
                    (option.id, option.latestVotes.map { $0.asPayload() })
                }
            ),
            voteCountsByOption: voteCountsByOption ?? [:],
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            votingVisibility: votingVisibility?.rawValue,
            createdBy: createdBy?.asPayload()
        )
    }
}

private extension PollOption {
    func asPayload() -> PollOptionPayload {
        PollOptionPayload(id: id, text: text, custom: extraData)
    }
}

private extension PollVote {
    func asPayload() -> PollVotePayload {
        PollVotePayload(
            createdAt: createdAt,
            id: id,
            optionId: optionId,
            pollId: pollId,
            updatedAt: updatedAt,
            answerText: answerText,
            isAnswer: isAnswer,
            userId: user?.id,
            user: user?.asPayload()
        )
    }
}
