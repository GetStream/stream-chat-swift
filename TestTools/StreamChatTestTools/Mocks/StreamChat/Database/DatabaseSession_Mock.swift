//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// This class allows you to wrap an existing `DatabaseSession` and adjust the behavior of its methods.
final class DatabaseSession_Mock: DatabaseSession {
    /// The wrapped session
    let underlyingSession: DatabaseSession

    /// If set to a non-nil value, the error is returned from all throwing methods of the session
    @Atomic var errorToReturn: Error?
    
    init(underlyingSession: DatabaseSession) {
        self.underlyingSession = underlyingSession
    }
    
    var markChannelAsReadParams: (cid: ChannelId, userId: UserId, at: Date)?
    var markChannelAsUnreadParams: (cid: ChannelId, userId: UserId)?
}

// Here start the boilerplate that forwards and intercepts the session calls if needed

extension DatabaseSession_Mock {
    func addReaction(
        to messageId: MessageId,
        type: MessageReactionType,
        score: Int,
        extraData: [String: RawJSON],
        localState: LocalReactionState?
    ) throws -> MessageReactionDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.addReaction(
            to: messageId,
            type: type,
            score: score,
            extraData: extraData,
            localState: localState
        )
    }
    
    func removeReaction(from messageId: MessageId, type: MessageReactionType, on version: String?) throws -> MessageReactionDTO? {
        try throwErrorIfNeeded()
        return try underlyingSession.removeReaction(from: messageId, type: type, on: version)
    }

    func saveCurrentDevice(_ deviceId: String) throws {
        try throwErrorIfNeeded()
        return try saveCurrentDevice(deviceId)
    }
    
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws -> [DeviceDTO] {
        try throwErrorIfNeeded()
        return try underlyingSession.saveCurrentUserDevices(devices, clearExisting: clearExisting)
    }
    
    func saveChannelList(payload: ChannelListPayload, query: ChannelListQuery) throws -> [ChannelDTO] {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannelList(payload: payload, query: query)
    }
    
    func saveChannel(
        payload: ChannelDetailPayload,
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannel(payload: payload, query: query)
    }
    
    func saveUser(payload: UserPayload, query: UserListQuery?) throws -> UserDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveUser(payload: payload, query: query)
    }
    
    func saveQuery(query: UserListQuery) throws -> UserListQueryDTO? {
        try throwErrorIfNeeded()
        return try underlyingSession.saveQuery(query: query)
    }
    
    func userListQuery(filterHash: String) -> UserListQueryDTO? {
        underlyingSession.userListQuery(filterHash: filterHash)
    }
    
    func user(id: UserId) -> UserDTO? {
        underlyingSession.user(id: id)
    }
    
    func deleteQuery(_ query: UserListQuery) {
        underlyingSession.deleteQuery(query)
    }

    func cleanChannels(cids: Set<ChannelId>) {
        underlyingSession.cleanChannels(cids: cids)
    }

    func removeChannels(cids: Set<ChannelId>) {
        underlyingSession.removeChannels(cids: cids)
    }
    
    func saveCurrentUser(payload: CurrentUserPayload) throws -> CurrentUserDTO {
        try throwErrorIfNeeded()
        return try saveCurrentUser(payload: payload)
    }
    
    func saveCurrentUserUnreadCount(count: UnreadCount) throws {
        try throwErrorIfNeeded()
        try saveCurrentUserUnreadCount(count: count)
    }
    
    func deleteDevice(id: DeviceId) {
        underlyingSession.deleteDevice(id: id)
    }
    
    var currentUser: CurrentUserDTO? { underlyingSession.currentUser }
    
    func createNewMessage(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        createdAt: Date?,
        extraData: [String: RawJSON]
    ) throws -> MessageDTO {
        try throwErrorIfNeeded()

        return try underlyingSession.createNewMessage(
            in: cid,
            text: text,
            pinning: pinning,
            command: command,
            arguments: arguments,
            parentMessageId: parentMessageId,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessageId,
            createdAt: createdAt,
            extraData: extraData
        )
    }
    
    func saveMessage(payload: MessagePayload, for cid: ChannelId?, syncOwnReactions: Bool) throws -> MessageDTO? {
        try throwErrorIfNeeded()
        return try? underlyingSession.saveMessage(payload: payload, for: cid, syncOwnReactions: syncOwnReactions)
    }
    
    func saveMessage(payload: MessagePayload, channelDTO: ChannelDTO, syncOwnReactions: Bool) throws -> MessageDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMessage(payload: payload, channelDTO: channelDTO, syncOwnReactions: syncOwnReactions)
    }
    
    func pin(message: MessageDTO, pinning: MessagePinning) throws {
        try throwErrorIfNeeded()
        return try underlyingSession.pin(message: message, pinning: pinning)
    }
    
    func unpin(message: MessageDTO) {
        underlyingSession.unpin(message: message)
    }
    
    func message(id: MessageId) -> MessageDTO? {
        underlyingSession.message(id: id)
    }
    
    func delete(message: MessageDTO) {
        underlyingSession.delete(message: message)
    }
    
    func preview(for cid: ChannelId) -> MessageDTO? {
        underlyingSession.preview(for: cid)
    }
    
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO? {
        underlyingSession.reaction(messageId: messageId, userId: userId, type: type)
    }
    
    func saveReaction(payload: MessageReactionPayload) throws -> MessageReactionDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveReaction(payload: payload)
    }
    
    func delete(reaction: MessageReactionDTO) {
        underlyingSession.delete(reaction: reaction)
    }
    
    func saveChannelRead(payload: ChannelReadPayload, for cid: ChannelId) throws -> ChannelReadDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannelRead(payload: payload, for: cid)
    }
    
    func markChannelAsRead(cid: ChannelId, userId: UserId, at: Date) {
        markChannelAsReadParams = (cid, userId, at)
        underlyingSession.markChannelAsRead(cid: cid, userId: userId, at: at)
    }
    
    func markChannelAsUnread(cid: ChannelId, by userId: UserId) {
        markChannelAsUnreadParams = (cid, userId)
        underlyingSession.markChannelAsUnread(cid: cid, by: userId)
    }

    func loadChannelRead(cid: ChannelId, userId: String) -> ChannelReadDTO? {
        underlyingSession.loadChannelRead(cid: cid, userId: userId)
    }
    
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO] {
        underlyingSession.loadChannelReads(for: userId)
    }
    
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        underlyingSession.saveQuery(query: query)
    }
    
    func channelListQuery(filterHash: String) -> ChannelListQueryDTO? {
        underlyingSession.channelListQuery(filterHash: filterHash)
    }
    
    func loadAllChannelListQueries() -> [ChannelListQueryDTO] {
        underlyingSession.loadAllChannelListQueries()
    }
    
    func saveChannel(
        payload: ChannelPayload,
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannel(payload: payload, query: query)
    }
    
    func channel(cid: ChannelId) -> ChannelDTO? {
        underlyingSession.channel(cid: cid)
    }
    
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) throws -> MemberDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMember(payload: payload, channelId: channelId, query: query)
    }
    
    func member(userId: UserId, cid: ChannelId) -> MemberDTO? {
        underlyingSession.member(userId: userId, cid: cid)
    }
    
    func channelMemberListQuery(queryHash: String) -> ChannelMemberListQueryDTO? {
        underlyingSession.channelMemberListQuery(queryHash: queryHash)
    }
    
    func saveQuery(_ query: ChannelMemberListQuery) throws -> ChannelMemberListQueryDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveQuery(query)
    }
    
    func attachment(id: AttachmentId) -> AttachmentDTO? {
        underlyingSession.attachment(id: id)
    }
    
    func saveAttachment(payload: MessageAttachmentPayload, id: AttachmentId) throws -> AttachmentDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveAttachment(payload: payload, id: id)
    }
    
    func createNewAttachment(attachment: AnyAttachmentPayload, id: AttachmentId) throws -> AttachmentDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.createNewAttachment(attachment: attachment, id: id)
    }

    func saveChannelMute(
        payload: MutedChannelPayload
    ) throws -> ChannelMuteDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannelMute(payload: payload)
    }
    
    func delete(query: ChannelListQuery) {
        underlyingSession.delete(query: query)
    }

    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery) throws -> MessageDTO? {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMessage(payload: payload, for: query)
    }

    func deleteQuery(_ query: MessageSearchQuery) {
        underlyingSession.deleteQuery(query)
    }
    
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO {
        underlyingSession.saveQuery(query: query)
    }

    func deleteQueuedRequest(id: String) {
        underlyingSession.deleteQueuedRequest(id: id)
    }
}

private extension DatabaseSession_Mock {
    func throwErrorIfNeeded() throws {
        guard let error = errorToReturn else { return }
        throw error
    }
}
