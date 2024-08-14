//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An object which represents a `ChatChannel`.
public class Chat {
    private let channelUpdater: ChannelUpdater
    private let client: ChatClient
    private let databaseContainer: DatabaseContainer
    private let eventNotificationCenter: EventNotificationCenter
    private let eventSender: EventSender
    private let memberUpdater: ChannelMemberUpdater
    private let messageUpdater: MessageUpdater
    private let stateBuilder: StateBuilder<ChatState>
    private let typingEventsSender: TypingEventsSender
    
    init(
        channelQuery: ChannelQuery,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>],
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        eventNotificationCenter = client.eventNotificationCenter
        databaseContainer = client.databaseContainer
        channelUpdater = environment.channelUpdaterBuilder(
            client.channelRepository,
            client.messageRepository,
            client.makeMessagesPaginationStateHandler(),
            client.databaseContainer,
            client.apiClient
        )
        memberUpdater = environment.memberUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        eventSender = environment.eventSenderBuilder(
            client.databaseContainer,
            client.apiClient
        )
        messageUpdater = environment.messageUpdaterBuilder(
            client.config.isLocalStorageEnabled,
            client.messageRepository,
            client.databaseContainer,
            client.apiClient
        )
        typingEventsSender = environment.typingEventsSenderBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder { [channelUpdater] in
            environment.chatStateBuilder(
                channelQuery,
                messageOrdering,
                memberSorting,
                channelUpdater,
                client,
                environment
            )
        }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the channel.
    @MainActor public lazy var state: ChatState = stateBuilder.build()
    
    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Important: Resets ``ChatState/messages``, ``ChatState/members``, and ``ChatState/watchers`` in ``ChatState``.
    ///
    /// - Note: When watching is enabled for the channel, then channel updates are delivered
    ///  through web-socket events and there is no need to call ``get(watch:)`` for fetching
    ///  the latest state multiple times during the app's lifetime.
    ///
    /// - Parameter watch: True, if server-side events should be enabled in addition
    /// to fetching state from the server. See ``watch()`` for more information
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get(watch: Bool) async throws {
        let query = await state.channelQuery.withOptions(forWatching: watch)
        let payload = try await channelUpdater.update(
            channelQuery: query,
            memberSorting: state.memberSorting
        )
        client.syncRepository.startTrackingChat(self)
        // cid is retrieved from the server when we are creating new channels or there is no local state present
        guard query.cid != payload.channel.cid else { return }
        await state.setChannelId(payload.channel.cid)
    }
    
    /// Start watching the channel which enables server-side events.
    ///
    /// Watching queries the channel state and returns members, watchers and messages, and notifies the server to start sending events when anything in this channel changes.
    ///
    /// Please refer to [Watching a Channel](https://getstream.io/chat/docs/ios-swift/watch_channel/?language=swift) for additional information.
    ///
    /// - Note: Creating an instance of `Chat` starts watching the channel automatically.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func watch() async throws {
        try await channelUpdater.startWatching(cid: cid, isInRecoveryMode: false)
        client.syncRepository.startTrackingChat(self)
    }
    
    /// Stop watching the channel which disables server-side events.
    ///
    /// Please refer to [Watching a Channel](https://getstream.io/chat/docs/ios-swift/watch_channel/?language=swift) for additional information.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func stopWatching() async throws {
        try await channelUpdater.stopWatching(cid: cid)
        client.syncRepository.stopTrackingChat(self)
    }
    
    // MARK: - Deleting the Channel
    
    /// Deletes the channel.
    ///
    /// This marks the channel as deleted and hides all the messages.
    ///
    /// - Note: If you recreate this channel, it will show up empty. Recovering old messages is not supported.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func delete() async throws {
        try await channelUpdater.deleteChannel(cid: cid)
    }
    
    // MARK: - Disabling/Freezing the Channel
    
    /// Freezes the channel which disallows sending new messages and adding or deleting reactions.
    ///
    /// Sending a message to a frozen channel will result in a error. Sending and deleting
    /// reactions to frozen channels will result in a 403 (Not Allowed) error. User roles
    /// with the `UseFrozenChannel` permission are still able to use frozen channels as if they
    /// weren't frozen. By default no user role has the `UseFrozenChannel` permission.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func freeze() async throws {
        try await channelUpdater.freezeChannel(true, cid: cid)
    }
    
    /// Removes the frozen channel restriction and enables sending new messages and adding or deleting reactions.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unfreeze() async throws {
        try await channelUpdater.freezeChannel(false, cid: cid)
    }
    
    // MARK: - Invites
    
    /// Accepts a pending invite and adds the current user as a member to the channel.
    ///
    /// - Note: Unread counts are not incremented for the channel for which the user is a member of but has a pending invite.
    /// - Note: Pending invites can be queried by setting the ``Filter`` to `.equal("invite", to: "pending")`.
    ///
    /// - Parameter systemMessage: A system message to be added after accepting the invite.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func acceptInvite(with systemMessage: String? = nil) async throws {
        try await channelUpdater.acceptInvite(cid: cid, message: systemMessage)
    }
    
    /// Invite users to the channel.
    ///
    /// Upon invitation, the invited user will receive a notification that they were invited to the this channel.
    ///
    /// - Parameter members: An array of user ids that will be invited to the channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func inviteMembers(_ members: [UserId]) async throws {
        try await channelUpdater.inviteMembers(cid: cid, userIds: Set(members))
    }
    
    /// Rejects a pending invite and does not add the current user as a member of the channel.
    ///
    /// - Note: Pending invites can be queried by setting the ``Filter`` to `.equal("invite", to: "pending")`.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func rejectInvite() async throws {
        try await channelUpdater.rejectInvite(cid: cid)
    }
    
    // MARK: - Members
    
    /// Adds given users as members.
    ///
    /// - Note: You can only add up to 100 members at once.
    ///
    /// - Parameters:
    ///   - members: An array of user ids that will be added to the channel.
    ///   - systemMessage: A system message to be added after adding members.
    ///   - hideHistory: If true, the previous history is available for added members, otherwise they do not see the history. The default value is false.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func addMembers(
        _ members: [UserId],
        systemMessage: String? = nil,
        hideHistory: Bool = false
    ) async throws {
        let currentUserId = client.authenticationRepository.currentUserId
        try await channelUpdater.addMembers(
            currentUserId: currentUserId,
            cid: cid,
            userIds: Set(members),
            message: systemMessage,
            hideHistory: hideHistory
        )
    }
    
    /// Removes given users from the channel.
    ///
    /// - Parameters:
    ///   - members: An array of user ids that will be removed from the channel.
    ///   - systemMessage: A system message to be added after removing members.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func removeMembers(_ members: [UserId], systemMessage: String? = nil) async throws {
        let currentUserId = client.authenticationRepository.currentUserId
        try await channelUpdater.removeMembers(
            currentUserId: currentUserId,
            cid: cid,
            userIds: Set(members),
            message: systemMessage
        )
    }
    
    /// Loads channel members for the specified pagination parameters and updates ``ChatState/members``.
    ///
    /// - Note: Channel member sorting keys are set when creating the ``Chat`` instance.
    /// It is also possible to create separate ``MemberList`` objects if needed with different filtering options. See ``ChatClient/makeMemberList(with:)``.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channel members for the pagination request.
    @discardableResult public func loadMembers(with pagination: Pagination) async throws -> [ChatChannelMember] {
        try await memberList.loadMembers(with: pagination)
    }
    
    /// Loads more channel members and updates ``ChatState/members``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channel members for the pagination request.
    @discardableResult public func loadMoreMembers(limit: Int? = nil) async throws -> [ChatChannelMember] {
        try await memberList.loadMoreMembers(limit: limit)
    }
    
    // MARK: - Member Moderation
    
    /// Bans the specified member from the channel.
    ///
    /// When the channel member is banned, they will not be allowed to post messages until the ban is removed
    /// or expired.
    ///
    /// Learn more about [banning and moderation tools](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#ban).
    ///
    ///  - Note: Channel watchers cannot be banned.
    ///  - Note: In most cases, only admins or moderators are allowed to ban other users from the channel.
    ///
    /// - Parameters:
    ///   - userId: The user id of the channel member.
    ///   - reason: The reason that the ban was created.
    ///   - timeoutInMinutes: The number of minutes the user should be banned for. Nil means that the user is banned forever or until the user is unbanned explicitly.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func banMember(
        _ userId: UserId,
        reason: String? = nil,
        timeout timeoutInMinutes: Int? = nil
    ) async throws {
        try await memberUpdater.banMember(
            userId,
            in: cid,
            shadow: false,
            for: timeoutInMinutes,
            reason: reason
        )
    }
    
    /// Shadow bans the specified member from the channel.
    ///
    /// When the channel member is shadow banned, they will still be allowed to post messages, but any message
    /// sent during the ban will only be visible to the author of the message and invisible to other users of the app.
    ///
    /// Learn more about [shadow banning and moderation tools](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#shadow-ban).
    ///
    /// - Parameters:
    ///   - userId: The user id of the channel member.
    ///   - reason: The reason that the ban was created.
    ///   - timeoutInMinutes: The number of minutes the user should be banned for. Nil means that the user is banned forever or until the user is unbanned explicitly.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func shadowBanMember(
        _ userId: UserId,
        reason: String? = nil,
        timeout timeoutInMinutes: Int? = nil
    ) async throws {
        try await memberUpdater.banMember(
            userId,
            in: cid,
            shadow: true,
            for: timeoutInMinutes,
            reason: reason
        )
    }
    
    /// Removes the channel member from the ban list.
    ///
    /// - Parameter userId: The user id of the channel member.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unbanMember(_ userId: UserId) async throws {
        try await memberUpdater.unbanMember(userId, in: cid)
    }
    
    // MARK: - Messages
    
    /// Deletes the specified message.
    ///
    /// Messages can be soft deleted or hard deleted. Note that deleting a message doesn't delete its attachments.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to delete.
    ///   - hard: True, if the message should be permanently deleted. The default value is false. The recommend approach is to always do a soft delete (hard = false).
    ///   You can control the UI Visibility of the deleted message in the client side.
    ///
    /// - Warning: If you hard delete the message, the message will be permanently lost since it will be erased from the backend's database.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func deleteMessage(_ messageId: MessageId, hard: Bool = false) async throws {
        try await messageUpdater.deleteMessage(messageId: messageId, hard: hard)
    }
    
    /// Resends a failed message.
    ///
    /// The ``sendMessage(with:attachments:replyTo:mentions:pinning:extraData:silent:skipPushNotification:skipEnrichURL:messageId:)`` method can fail but the message is not discarded. Failed messages are kept locally and can be retried.
    ///
    /// - Parameter messageId: The id of the message to resend.
    ///
    /// - Throws: An error while sending a message to the Stream API.
    /// - Returns: An instance of `ChatMessage` which was resent.
    @discardableResult public func resendMessage(_ messageId: MessageId) async throws -> ChatMessage {
        let messageSender = try client.backgroundWorker(of: MessageSender.self)
        try await messageUpdater.resendMessage(with: messageId)
        return try await messageSender.waitForAPIRequest(messageId: messageId)
    }
    
    /// Resends a failed attachment.
    ///
    /// - Parameter attachment: The id of the attachment.
    ///
    /// - Throws: An error while sending a message to the Stream API.
    /// - Returns: The uploaded attachment with additional information like remote and thumbnail URLs.
    @discardableResult public func resendAttachment(_ attachment: AttachmentId) async throws -> UploadedAttachment {
        let attachmentQueueUploader = try client.backgroundWorker(of: AttachmentQueueUploader.self)
        try await messageUpdater.resendAttachment(with: attachment)
        return try await attachmentQueueUploader.waitForAPIRequest(attachmentId: attachment)
    }
    
    /// Invokes the ephemeral action specified by the attachment.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message with the action.
    ///   - action: The ephemeral action to be invoked.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func sendMessageAction(in messageId: MessageId, action: AttachmentAction) async throws {
        try await messageUpdater.dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
    }
    
    /// Sends a message to channel.
    ///
    /// The send message method waits until the network request has finished to Stream API.
    ///
    /// - Note: If sending a message fails, the message is not discarded. Failed messages are kept locally and can be retried.
    /// - SeeAlso: Replying to an existing message: ``reply(to:text:showReplyInChannel:attachments:quote:mentions:pinning:extraData:silent:skipPushNotification:skipEnrichURL:messageId:)``.
    /// - SeeAlso: Editing an existing message: ``updateMessage(_:with:attachments:extraData:skipEnrichURL:)``.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: An id of the quoted message.
    ///   - mentions: An array of mentioned user ids.
    ///   - pinning: If pinning configuration is set, the message is pinned to the channel.
    ///   - extraData: Additional extra data of the message object.
    ///   - silent: If true, the message doesn't increase the unread messages count and mark a channel as unread.
    ///   - skipPushNotification: If true, skips sending push notification to channel members.
    ///   - skipEnrichURL: If true, the url preview won't be attached to the message.
    ///   - messageId: A custom id for the sent message. By default, it is automatically generated by Stream.
    ///
    /// - Throws: An error while sending a message to the Stream API.
    /// - Returns: An instance of `ChatMessage` which was delivered to the channel.
    @discardableResult
    public func sendMessage(
        with text: String,
        attachments: [AnyAttachmentPayload] = [],
        quote quotedMessageId: MessageId? = nil,
        mentions: [UserId] = [],
        pinning: MessagePinning? = nil,
        extraData: [String: RawJSON] = [:],
        silent: Bool = false,
        skipPushNotification: Bool = false,
        skipEnrichURL: Bool = false,
        messageId: MessageId? = nil
    ) async throws -> ChatMessage {
        Task { try await stopTyping() } // errors explicitly ignored
        let localMessage = try await channelUpdater.createNewMessage(
            in: cid,
            messageId: messageId,
            text: text,
            pinning: pinning,
            isSilent: silent,
            command: nil,
            arguments: nil,
            attachments: attachments,
            mentionedUserIds: mentions,
            quotedMessageId: quotedMessageId,
            skipPush: skipPushNotification,
            skipEnrichUrl: skipEnrichURL,
            extraData: extraData
        )
        // Important to set up the waiter immediately
        async let sentMessage = try await waitForAPIRequest(localMessage: localMessage)
        eventNotificationCenter.process(NewMessagePendingEvent(message: localMessage))
        return try await sentMessage
    }
    
    /// Edits the specified message in the channel.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to edit.
    ///   - text: Text of the message.
    ///   - attachments: An array of the attachments for the message.
    ///   - extraData: Additional extra data of the message object.
    ///   - skipEnrichURL: If true, the url preview won't be attached to the message.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `ChatMessage` which was updated.
    @discardableResult public func updateMessage(
        _ messageId: MessageId,
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        extraData: [String: RawJSON]? = nil,
        skipEnrichURL: Bool = false
    ) async throws -> ChatMessage {
        Task { try await stopTyping() } // errors explicitly ignored
        let localMessage = try await messageUpdater.editMessage(
            messageId: messageId,
            text: text,
            skipEnrichUrl: skipEnrichURL,
            attachments: attachments,
            extraData: extraData
        )
        return try await waitForAPIRequest(localMessage: localMessage)
    }
    
    // MARK: - Message Pagination
    
    /// Loads messages for the specified pagination parameters and updates ``ChatState/messages``.
    ///
    /// - Important: If `pagination.parameter` is nil, then loaded messages are reset.
    /// - Important: Calling ``get(watch:)`` resets ``ChatState/messages``.
    ///
    /// - Parameters:
    ///   - message: The parent message id which has replies.
    ///   - pagination: The pagination configuration which includes a limit and a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of messages for the pagination.
    @discardableResult public func loadMessages(with pagination: MessagesPagination) async throws -> [ChatMessage] {
        try await channelUpdater.loadMessages(with: state.channelQuery, pagination: pagination)
    }
    
    // MARK: -
    
    /// Loads older messages before the specified message to ``ChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the message from which older messages are loaded. If nil, the id of the oldest loaded message in ``ChatState/messages`` is used.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadMessages(before messageId: MessageId?, limit: Int? = nil) async throws {
        try await channelUpdater.loadMessages(
            before: messageId,
            limit: limit,
            channelQuery: state.channelQuery,
            loaded: state.messages
        )
    }
    
    /// Loads newer messages after the specified message to ``ChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the message from which newer messages are loaded.  If nil, the id of the newest loaded message in ``ChatState/messages`` is used.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadMessages(after messageId: MessageId?, limit: Int? = nil) async throws {
        try await channelUpdater.loadMessages(
            after: messageId,
            limit: limit,
            channelQuery: state.channelQuery,
            loaded: state.messages
        )
    }
    
    /// Loads messages around the given message id to ``ChatState/messages``.
    ///
    /// Useful for jumping to a message which hasn't been loaded yet.
    ///
    /// - Important: Jumping to a message resets the ``ChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the middle message in the loaded list of messages.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadMessages(around messageId: MessageId, limit: Int? = nil) async throws {
        try await channelUpdater.loadMessages(
            around: messageId,
            limit: limit,
            channelQuery: state.channelQuery,
            loaded: state.messages
        )
    }
    
    /// Loads more older messages and updates ``ChatState/messages``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadOlderMessages(limit: Int? = nil) async throws {
        try await loadMessages(before: nil, limit: limit)
    }
    
    /// Loads more newer messages and updates ``ChatState/messages``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadNewerMessages(limit: Int? = nil) async throws {
        try await loadMessages(after: nil, limit: limit)
    }
    
    // MARK: - Message Local State
    
    /// Access a message which is available locally by its id.
    ///
    /// - Note: This method does a local lookup of the message and returns a message present in ``ChatState/messages``.
    ///
    /// - Parameter messageId: The id of the message which is available locally.
    ///
    /// - Returns: An instance of the locally available chat message
    @MainActor public func localMessage(for messageId: MessageId) -> ChatMessage? {
        let dataStore = DataStore(client: client)
        let message = dataStore.message(id: messageId)
        return message?.cid == state.cid ? message : nil
    }
    
    /// Returns an observable message state for the specified message.
    ///
    /// If the message is not available locally then a request is made for retrieving the message. Otherwise it returns the message state for the local message state.
    ///
    /// - Note: Chat keeps a weak reference to the returned object. Calling the function multiple times
    /// with the same messageId might return the same instance of the ``MessageState``.
    ///
    /// - Parameter messageId: The message id for observing the state.
    ///
    /// - Returns: An instance of `MessageState` which conforms to the `ObservableObject`.
    public func messageState(for messageId: MessageId) async throws -> MessageState {
        try await state.messageState(
            for: messageId,
            provider: { messageId in
                if let localMessage = await localMessage(for: messageId) {
                    return localMessage
                } else {
                    return try await messageUpdater.getMessage(cid: cid, messageId: messageId)
                }
            }
        )
    }
    
    // MARK: - Message Flagging
    
    /// Flags the specified message and forwards it for moderation.
    ///
    /// - Note: Any user is allowed to flag a message.
    ///
    /// - Parameters:
    /// - messageId: The id of the message to be flagged.
    /// - reason: A reason why the user was flagged.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func flagMessage(
        _ messageId: MessageId,
        reason: String? = nil
    ) async throws {
        try await messageUpdater.flagMessage(
            true,
            with: messageId,
            in: cid,
            reason: reason
        )
    }
    
    /// Removes the flag from the specified message.
    ///
    /// - Parameter messageId: The id of the message to be unflagged.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unflagMessage(_ messageId: MessageId) async throws {
        try await messageUpdater.flagMessage(false, with: messageId, in: cid, reason: nil)
    }
    
    // MARK: - Message Rich Content
    
    /// Retrieve the link attachment preview for the specified URL.
    ///
    /// - Returns: The data present in the [Open Graph metadata](https://ogp.me).
    /// - Throws: An error while communicating with the Stream API.
    public func enrichURL(_ url: URL) async throws -> LinkAttachmentPayload {
        try await channelUpdater.enrichUrl(url)
    }
    
    // MARK: - Message Pinning
    
    /// Pins the message to the channel until the specified date.
    ///
    /// - Note: To pin the message user has to have `PinMessage` permission.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to be pinned.
    ///   - pinning: The pinning expiration information. Supports an infinite expiration, setting a date, or the amount of time a message is pinned.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `ChatMessage` which was pinned.
    @discardableResult public func pinMessage(
        _ messageId: MessageId,
        pinning: MessagePinning
    ) async throws -> ChatMessage {
        try await messageUpdater.pinMessage(messageId: messageId, pinning: pinning)
    }
    
    /// Removes the message from the channel's pinned messages.
    ///
    /// - Note: To unpin the message user has to have `PinMessage` permission.
    ///
    /// - Parameter messageId: The id of the message to unpin.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `ChatMessage` which was unpinned.
    @discardableResult public func unpinMessage(_ messageId: MessageId) async throws -> ChatMessage {
        try await messageUpdater.unpinMessage(messageId: messageId)
    }
    
    /// Loads pinned messages for the specified pagination options, sorting order, and limit.
    ///
    /// - Parameters:
    ///   - pagination: The pagination option used for retrieving pinned messages. If nil, most recently pinned messages are returned.
    ///   - sort: The sorting order for pinned messages. The default value is descending by `pinned_at` field.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of pinned messages for the specified pagination.
    public func loadPinnedMessages(
        with pagination: PinnedMessagesPagination? = nil,
        sort: [Sorting<PinnedMessagesSortingKey>] = [],
        limit: Int = .messagesPageSize
    ) async throws -> [ChatMessage] {
        let query = PinnedMessagesQuery(
            pageSize: limit,
            sorting: sort,
            pagination: pagination
        )
        return try await channelUpdater.loadPinnedMessages(in: cid, query: query)
    }
    
    // MARK: - Message Reactions and Pagination
    
    /// Removes a reaction with a specified type from a message.
    /// - Parameters:
    ///   - messageId: The id of the message to remove the reaction from.
    ///   - type: The type that describes a message reaction. Common examples are: “like”, “love”, “smile”, etc. An user can have only 1 reaction of each type per message.
    public func deleteReaction(
        from messageId: MessageId,
        with type: MessageReactionType
    ) async throws {
        try await messageUpdater.deleteReaction(type, messageId: messageId)
    }
    
    /// Adds a reaction to the specified message.
    ///
    /// - Note: Custom data for reactions is limited to 1 KB.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to send the reaction.
    ///   - type: The type that describes a message reaction. Common examples are: “like”, “love”, “smile”, etc. An user can have only 1 reaction of each type per message.
    ///   - score: The score of the reaction for cumulative reactions (example: n number of claps).
    ///   - enforceUnique: If `true`, the added reaction will replace all reactions the user has (if any) on this message.
    ///   - extraData: The reaction's extra data.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func sendReaction(
        to messageId: MessageId,
        with type: MessageReactionType,
        score: Int = 1,
        enforceUnique: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) async throws {
        try await messageUpdater.addReaction(
            type,
            score: score,
            enforceUnique: enforceUnique,
            extraData: extraData,
            messageId: messageId
        )
    }
    
    /// Loads reactions for the specified message and pagination parameters.
    ///
    /// All the currently loaded reactions can be accessed through ``MessageState/reactions``.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to load reactions.
    ///   - pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of reactions for given limit and offset.
    @discardableResult public func loadReactions(
        for messageId: MessageId,
        pagination: Pagination
    ) async throws -> [ChatMessageReaction] {
        try await messageUpdater.loadReactions(
            cid: cid,
            messageId: messageId,
            pagination: pagination
        )
    }
    
    /// Loads more reactions and updates ``MessageState/reactions``.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to load reactions.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of reactions for the next page.
    @discardableResult public func loadMoreReactions(
        for messageId: MessageId,
        limit: Int? = nil
    ) async throws -> [ChatMessageReaction] {
        let offset = try await messageState(for: messageId).reactions.count
        let pagination = Pagination(pageSize: limit ?? 25, offset: offset)
        return try await messageUpdater.loadReactions(
            cid: cid,
            messageId: messageId,
            pagination: pagination
        )
    }
    
    // MARK: - Message Reading
    
    /// Marks all the unread messages in the channel as read.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func markRead() async throws {
        guard let channel = await state.channel else { throw ClientError.ChannelNotCreatedYet() }
        try await readStateHandler.markRead(channel)
    }
    
    /// Marks all the messages after and including the specified message as unread.
    ///
    /// - Parameter messageId: The id of the first message that will be marked as unread.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func markUnread(from messageId: MessageId) async throws {
        guard let channel = await state.channel else { throw ClientError.ChannelNotCreatedYet() }
        try await readStateHandler.markUnread(from: messageId, in: channel)
    }
    
    // MARK: - Message Replies and Pagination
    
    /// Sends a message as reply to an existing message.
    ///
    /// Replied messages show up as separate threads.
    ///
    /// - Note: If sending a message fails, the message is not discarded. Failed messages are kept locally and can be retried.
    ///
    /// - Parameters:
    ///   - parentMessageId: The id of the message to send a reply to.
    ///   - text: Text of the message.
    ///   - showReplyInChannel: If `true`, the message is also visible in the channel, not only
    ///   in the response thread.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: The id of the quoted message.
    ///   - mentions: An array of mentioned user ids
    ///   - pinning: If pinning configuration is set, the message is pinned to the channel.
    ///   - extraData: Additional extra data of the message object.
    ///   - silent: If true, the message doesn't increase the unread messages count and mark a channel as unread.
    ///   - skipPushNotification: If true, skips sending push notification to channel members.
    ///   - skipEnrichURL: If true, the url preview won't be attached to the message.
    ///   - messageId: A custom id for the sent message. By default, it is automatically generated by Stream.
    ///
    /// - Throws: An error while sending a message to the Stream API.
    /// - Returns: An instance of `ChatMessage` which was delivered to the reply thread.
    @discardableResult public func reply(
        to parentMessageId: MessageId,
        text: String,
        showReplyInChannel: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        quote quotedMessageId: MessageId? = nil,
        mentions: [UserId] = [],
        pinning: MessagePinning? = nil,
        extraData: [String: RawJSON] = [:],
        silent: Bool = false,
        skipPushNotification: Bool = false,
        skipEnrichURL: Bool = false,
        messageId: MessageId? = nil
    ) async throws -> ChatMessage {
        Task { try await stopTyping() } // errors explicitly ignored
        let localMessage = try await messageUpdater.createNewReply(
            in: cid,
            messageId: messageId,
            text: text,
            pinning: pinning,
            command: nil,
            arguments: nil,
            parentMessageId: parentMessageId,
            attachments: attachments,
            mentionedUserIds: mentions,
            showReplyInChannel: showReplyInChannel,
            isSilent: silent,
            quotedMessageId: quotedMessageId,
            skipPush: skipPushNotification,
            skipEnrichUrl: skipEnrichURL,
            extraData: extraData
        )
        async let sentMessage = try await waitForAPIRequest(localMessage: localMessage)
        eventNotificationCenter.process(NewMessagePendingEvent(message: localMessage))
        return try await sentMessage
    }
    
    /// Loads replies of the specified message and pagination parameters and updates ``MessageState/replies``.
    ///
    /// - Parameters:
    ///   - messageId: The parent message id which has replies.
    ///   - pagination: The pagination configuration which includes a limit and a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of messages for the pagination.
    @discardableResult public func loadReplies(
        for messageId: MessageId,
        pagination: MessagesPagination
    ) async throws -> [ChatMessage] {
        let messageState = try await messageState(for: messageId)
        return try await messageUpdater.loadReplies(
            for: messageId,
            pagination: pagination,
            cid: cid,
            paginationStateHandler: messageState.replyPaginationHandler
        )
    }

    // MARK: -
    
    /// Loads more replies before the specified reply id and updates ``MessageState/replies``.
    ///
    /// - Parameters:
    ///   - replyId: The message id of the reply from which older messages are loaded. If nil, the oldest currently loaded message id in ``MessageState/replies`` is used.
    ///   - parentMessageId: The parent message id which has replies.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadReplies(
        before replyId: MessageId?,
        for parentMessageId: MessageId,
        limit: Int? = nil
    ) async throws {
        let messageState = try await messageState(for: parentMessageId)
        return try await messageUpdater.loadReplies(
            for: parentMessageId,
            before: replyId,
            limit: limit,
            cid: cid,
            paginationStateHandler: messageState.replyPaginationHandler
        )
    }
    
    /// Loads more replies after the specified reply id and updates ``MessageState/replies``.
    ///
    /// - Parameters:
    ///   - replyId: The message id of the reply from which newer messages are loaded. If nil, the newest currently loaded message id in ``MessageState/replies`` is used.
    ///   - parentMessageId: The parent message id which has replies.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadReplies(
        after replyId: MessageId?,
        for parentMessageId: MessageId,
        limit: Int? = nil
    ) async throws {
        let messageState = try await messageState(for: parentMessageId)
        return try await messageUpdater.loadReplies(
            for: parentMessageId,
            after: replyId,
            limit: limit,
            cid: cid,
            paginationStateHandler: messageState.replyPaginationHandler
        )
    }
    
    /// Loads replies around the specified reply id to ``MessageState/replies``.
    ///
    /// - Note: Passing in the parent message id as replyId loads oldest replies.
    ///
    /// - Parameters:
    ///   - replyId: The message id of the reply around which older and newer messages are loaded.
    ///   - parentMessageId: The parent message id which has replies.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadReplies(
        around replyId: MessageId,
        for parentMessageId: MessageId,
        limit: Int? = nil
    ) async throws {
        let messageState = try await messageState(for: parentMessageId)
        return try await messageUpdater.loadReplies(
            for: parentMessageId,
            around: replyId,
            limit: limit,
            cid: cid,
            paginationStateHandler: messageState.replyPaginationHandler
        )
    }
    
    /// Loads more older replies and updates ``MessageState/replies``.
    ///
    /// - Parameters:
    ///   - parentMessageId: The parent message id which has replies.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadOlderReplies(for parentMessageId: MessageId, limit: Int? = nil) async throws {
        try await loadReplies(before: nil, for: parentMessageId, limit: limit)
    }
    
    /// Loads more newer replies and updates ``MessageState/replies``.
    ///
    /// - Parameters:
    ///   - parentMessageId: The parent message id which has replies.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadNewerReplies(for parentMessageId: MessageId, limit: Int? = nil) async throws {
        try await loadReplies(after: nil, for: parentMessageId, limit: limit)
    }
    
    // MARK: - Message Translations
    
    /// Translates the message to the given language.
    ///
    /// The translated text can be retrieved with `message.translations[language]`.
    ///
    /// - Note: The translated message is automatically inserted into ``ChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to be translated.
    ///   - language: The language message text should be translated to.
    ///
    /// - Throws: An error while communicating with the Stream API
    @discardableResult public func translateMessage(
        _ messageId: MessageId,
        to language: TranslationLanguage
    ) async throws -> ChatMessage {
        try await messageUpdater.translate(messageId: messageId, to: language)
    }
    
    // MARK: - Muting or Hiding the Channel
    
    /// Mutes the channel which disables push notifications and unread count for new messages.
    ///
    /// By default, mutes stay in place indefinitely until the user removes it.
    ///
    /// - Note: The list of muted channels and their expiration time is returned when the user connects.
    ///
    /// - Parameter expiration: The duration of mute in milliseconds.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func mute(expiration: Int? = nil) async throws {
        try await channelUpdater.muteChannel(true, cid: cid, expiration: expiration)
    }
    
    /// Unmutes the channel which enables push notifications and unread count changes for new messages.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unmute() async throws {
        try await channelUpdater.muteChannel(false, cid: cid)
    }
    
    /// Hide the channel which removes if from the query channel requests for that user until a new message is added.
    ///
    /// Hiding a channel is only available to members of that channel. Hidden channels may still have unread messages
    /// and you may wish to mark the channel as read prior to hiding it.
    ///
    /// Optionally you can also clear the entire message history of that channel for the user. This way,
    /// when a new message is received, it will be the only one present in the channel.
    ///
    /// - Note: You can retrieve the list of hidden channels using the `hidden` query parameter (``FilterKey/hidden``).
    ///
    /// - Parameter clearHistory: If true, the whole channel history is deleted. The default value is false.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func hide(clearHistory: Bool = false) async throws {
        try await channelUpdater.hideChannel(cid: cid, clearHistory: clearHistory)
    }
    
    /// Shows a previously hidden channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func show() async throws {
        try await channelUpdater.showChannel(cid: cid)
    }
    
    // MARK: - Sending and Listening to Events
    
    /// Subscribes to web-socket events of a single type which is a channel specific event in this channel.
    ///
    /// - Note: The handler is always called on the main thread.
    /// - Important: Subscribing to events not related to this channel, like ``ConnectionStatusUpdated``, does not trigger the handler.
    /// - SeeAlso: ``ChatClient.subscribe(toEvent:handler:)`` for subscribing to client events.
    ///
    /// - Parameters:
    ///   - event: The event type to subscribe to (e.g. ``MessageNewEvent``).
    ///   - handler: The handler closure which is called when the event happens.
    ///
    /// - Returns: A cancellable instance, which you use when you end the subscription. Deallocation of the result will tear down the subscription stream.
    public func subscribe<E>(
        toEvent event: E.Type,
        handler: @escaping (E) -> Void
    ) -> AnyCancellable where E: Event {
        eventNotificationCenter.subscribe(
            to: event,
            handler: { [weak self] event in
                self?.dispatchSubscribeHandler(event, callback: handler)
            }
        )
    }
    
    /// Subscribes to all the web-socket events of this channel.
    ///
    /// - SeeAlso: ``ChatClient.subscribe(handler:)`` for subscribing to client events.
    ///
    /// - Parameter handler: The handler closure which is called when the event happens.
    ///
    /// - Returns: A cancellable instance, which you use when you end the subscription. Deallocation of the result will tear down the subscription stream.
    public func subscribe(_ handler: @escaping (Event) -> Void) -> AnyCancellable {
        eventNotificationCenter.subscribe(
            handler: { [weak self] event in
                self?.dispatchSubscribeHandler(event, callback: handler)
            }
        )
    }
    
    /// Sends a custom event to the channel.
    ///
    /// Please refer to [Custom Events](https://getstream.io/chat/docs/ios-swift/custom_events/?language=swift) for additional details.
    ///
    /// - Parameter payload: The custom event payload to be sent.
    public func sendEvent<EventPayload>(_ payload: EventPayload) async throws where EventPayload: CustomEventPayload {
        try await eventSender.sendEvent(payload, to: cid)
    }
    
    // MARK: - Throttling and Slow Mode
    
    /// Enables slow mode which limits how often members can post new messages to the channel.
    ///
    /// Slow mode helps reduce noise on a channel by limiting users to a maximum of 1 message per cooldown interval.
    /// The cooldown interval is configurable and can be anything between 1 and 120 seconds. If you enable slow mode
    /// and set the cooldown interval to 30 seconds a user will be able to post at most 1 message every 30 seconds.
    ///
    /// - Note: Moderators and admins are not restricted by the cooldown period and can post messages as usual.
    /// - Note: When a user posts a message during the cooldown period, the API returns an error message. You can
    /// avoid hitting the APIs and instead show such limitation on the send message UI directly. When slow mode is
    /// enabled, channels include a `cooldown` field containing the current cooldown period in seconds.
    ///
    /// - Parameter cooldownDuration: The time interval in seconds in which a user will be able to post at most 1 message.
    ///
    /// - Throws: An error while communicating with the Stream API or when setting an invalid duration.
    public func enableSlowMode(cooldownDuration: Int) async throws {
        guard cooldownDuration >= 1, cooldownDuration <= 120 else {
            throw ClientError.InvalidCooldownDuration()
        }
        try await channelUpdater.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
    }
    
    /// Disables slow mode which removes the limits of how often members can post new messages to the channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func disableSlowMode() async throws {
        try await channelUpdater.enableSlowMode(cid: cid, cooldownDuration: 0)
    }
    
    // MARK: - Truncating the Channel
    
    /// Truncates messages from the channel.
    ///
    /// Truncating the channel removes all of the messages but does not affect the channel data or channel members.
    ///
    /// - SeeAlso: If you want to delete both channel and message data then use the ``delete()`` method instead.
    ///
    /// - Parameters:
    ///   - systemMessage: A system message to be added after truncating the channel.
    ///   - hardDelete: If true, messages are deleted, otherwise messages are hidden. The default value is set to true.
    ///   - skipPush: If true, push notification is not sent to channel members, otherwise push notification is sent. The default value is set to false.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func truncate(
        systemMessage: String? = nil,
        hardDelete: Bool = true,
        skipPush: Bool = false
    ) async throws {
        try await channelUpdater.truncateChannel(
            cid: cid,
            skipPush: skipPush,
            hardDelete: hardDelete,
            systemMessage: systemMessage
        )
    }
    
    // MARK: - Typing Indicator
    
    /// Sends a `typing.start` event in this channel to the server.
    ///
    /// Keystroke events are throttled and `stopTyping(parentMessageId:)` is automatically called after a couple of seconds from the last keystroke event.
    ///
    /// - Parameter parentMessageId: A message id of the message in a thread the user is replying to.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func keystroke(parentMessageId: MessageId? = nil) async throws {
        try await typingEventsSender.keystroke(in: cid, parentMessageId: parentMessageId)
    }
    
    /// Sends a `typing.stop` event in this channel to the server.
    ///
    /// - Note: The stop typing event is automatically sent after a few seconds since the last keystroke. Use this method only when it is required to send the event at a different time.
    ///
    /// - Parameter parentMessageId: A message id of the message in a thread the user is replying to.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func stopTyping(parentMessageId: MessageId? = nil) async throws {
        try await typingEventsSender.stopTyping(in: cid, parentMessageId: parentMessageId)
    }
    
    // MARK: - Updating the Channel
    
    /// The update operation updates all of the channel data.
    ///
    /// - Warning: Any data that is present on the channel and is not included in a full update will be **deleted**.
    ///
    /// - Parameters:
    ///   - name: - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - members: A list of members for the channel.
    ///   - invites: A list of users who will get invites.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func update(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId> = [],
        invites: Set<UserId> = [],
        extraData: [String: RawJSON] = [:]
    ) async throws {
        try await channelUpdater.update(
            channelPayload: .init(
                cid: cid,
                name: name,
                imageURL: imageURL,
                team: team,
                members: members,
                invites: invites,
                extraData: extraData
            )
        )
    }
    
    /// The update operation updates only specified fields and retain existing channel data.
    ///
    /// A partial update can be used to set and unset specific fields when it is necessary to retain additional
    /// custom data fields on the object (a patch style update).
    ///
    /// - Parameters:
    ///   - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - members: A list of members for the channel.
    ///   - invites: A list of users who will get invites.
    ///   - extraData: Extra data for the channel.
    ///   - unsetProperties: A list of properties to reset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func updatePartial(
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: [UserId] = [],
        invites: [UserId] = [],
        extraData: [String: RawJSON] = [:],
        unsetProperties: [String] = []
    ) async throws {
        try await channelUpdater.updatePartial(
            channelPayload: .init(
                cid: cid,
                name: name,
                imageURL: imageURL,
                team: team,
                members: Set(members),
                invites: Set(invites),
                extraData: extraData
            ),
            unsetProperties: unsetProperties
        )
    }
    
    // MARK: - Uploading and Deleting Files
    
    /// Deletes the file associated with the given URL in the channel.
    ///
    /// - Parameter url: The URL of the file to be deleted.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func deleteFile(at url: URL) async throws {
        try await channelUpdater.deleteFile(in: cid, url: url.absoluteString)
    }
    
    /// Deletes the image associated with the given URL in the channel.
    ///
    /// - Parameter url: The URL of the image to be deleted.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func deleteImage(at url: URL) async throws {
        try await channelUpdater.deleteImage(in: cid, url: url.absoluteString)
    }
    
    /// Uploads the given file to CDN and returns an attachment containing the remote URL.
    ///
    /// - Note: The maximum file size is 100 MB.
    /// - Note: This functionality defaults to using the Stream CDN. The used CDN can be configured.
    ///
    /// - Parameters:
    ///   - localFileURL: The URL to a local file.
    ///   - type: The attachment type.
    ///   - progress: The uploading progress handler.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: Returns an uploaded attachment containing the remote url and the attachment metadata.
    public func uploadAttachment(
        with localFileURL: URL,
        type: AttachmentType,
        progress: ((Double) -> Void)? = nil
    ) async throws -> UploadedAttachment {
        try await channelUpdater.uploadFile(
            type: type,
            localFileURL: localFileURL,
            cid: cid,
            progress: progress
        )
    }
    
    // MARK: - Watcher Pagination
    
    /// Loads watchers for the specified pagination parameters and updates ``ChatState/watchers``.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and a cursor or an offset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of watchers for the pagination.
    @discardableResult public func loadWatchers(with pagination: Pagination) async throws -> [ChatUser] {
        try await channelUpdater.channelWatchers(for: .init(cid: cid, pagination: pagination))
    }

    /// Loads more watchers and updates ``ChatState/watchers``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded watchers.
    @discardableResult public func loadMoreWatchers(limit: Int? = nil) async throws -> [ChatUser] {
        let count = await state.watchers.count
        let pagination = Pagination(pageSize: limit ?? .channelWatchersPageSize, offset: count)
        return try await loadWatchers(with: pagination)
    }
}

// MARK: - Internal

extension Chat {
    @MainActor var cid: ChannelId {
        get throws {
            guard let cid = state.cid else { throw ClientError.ChannelNotCreatedYet() }
            return cid
        }
    }
    
    func dispatchSubscribeHandler<E>(_ event: E, callback: @escaping (E) -> Void) where E: Event {
        Task.mainActor {
            guard let cid = try? self.cid else { return }
            guard EventNotificationCenter.channelFilter(cid: cid, event: event) else { return }
            callback(event)
        }
    }
    
    var memberList: MemberList {
        get async throws {
            guard let memberList = await state.memberList else { throw ClientError.ChannelNotCreatedYet() }
            return memberList
        }
    }
    
    var readStateHandler: ReadStateHandler {
        get async throws {
            guard let handler = await state.readStateHandler else { throw ClientError.ChannelNotCreatedYet() }
            return handler
        }
    }
    
    /// Depending on the local state we use different workers.
    func waitForAPIRequest(localMessage: ChatMessage) async throws -> ChatMessage {
        switch localMessage.localState {
        case .pendingSend:
            let messageSender = try client.backgroundWorker(of: MessageSender.self)
            return try await messageSender.waitForAPIRequest(messageId: localMessage.id)
        case .pendingSync:
            let messageEditor = try client.backgroundWorker(of: MessageEditor.self)
            return try await messageEditor.waitForAPIRequest(messageId: localMessage.id)
        default:
            return localMessage
        }
    }
}

// MARK: - Environment

extension Chat {
    struct Environment {
        var chatStateBuilder: @MainActor(
            _ channelQuery: ChannelQuery,
            _ messageOrder: MessageOrdering,
            _ memberSorting: [Sorting<ChannelMemberListSortingKey>],
            _ channelUpdater: ChannelUpdater,
            _ client: ChatClient,
            _ environment: Chat.Environment
        ) -> ChatState = { @MainActor in
            ChatState(
                channelQuery: $0,
                messageOrder: $1,
                memberSorting: $2,
                channelUpdater: $3,
                client: $4,
                environment: $5
            )
        }
        
        var channelUpdaterBuilder: (
            _ channelRepository: ChannelRepository,
            _ messageRepository: MessageRepository,
            _ paginationStateHandler: MessagesPaginationStateHandling,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelUpdater = ChannelUpdater.init

        var eventSenderBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> EventSender = EventSender.init
        
        var memberUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberUpdater = ChannelMemberUpdater.init

        var messageUpdaterBuilder: (
            _ isLocalStorageEnabled: Bool,
            _ messageRepository: MessageRepository,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init
        
        var readStateHandlerBuilder: (
            _ authenticationRepository: AuthenticationRepository,
            _ channelUpdater: ChannelUpdater,
            _ messageRepository: MessageRepository
        ) -> ReadStateHandler = ReadStateHandler.init
        
        var typingEventsSenderBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> TypingEventsSender = TypingEventsSender.init
    }
}
