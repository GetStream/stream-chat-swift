//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// This class allows you to wrap an existing `DatabaseSession` and adjust the behavior of its methods.
class DatabaseSessionMock: DatabaseSession {
    /// The wrapped session
    let underlyingSession: DatabaseSession

    /// If set to a non-nil value, the error is returned from all throwing methods of the session
    @Atomic var errorToReturn: Error?
    
    init(underlyingSession: DatabaseSession) {
        self.underlyingSession = underlyingSession
    }
}

// Here start the boilerplate that forwards and intercepts the session calls if needed

extension DatabaseSessionMock {
    func saveCurrentDevice(_ deviceId: String) throws {
        try throwErrorIfNeeded()
        return try saveCurrentDevice(deviceId)
    }
    
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws -> [DeviceDTO] {
        try throwErrorIfNeeded()
        return try underlyingSession.saveCurrentUserDevices(devices, clearExisting: clearExisting)
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
    
    func user(id: UserId) -> UserDTO? {
        underlyingSession.user(id: id)
    }
    
    func deleteQuery(_ query: UserListQuery) {
        underlyingSession.deleteQuery(query)
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
    
    func saveMessage(payload: MessagePayload, channelDTO: ChannelDTO) throws -> MessageDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMessage(payload: payload, channelDTO: channelDTO)
    }

    func saveMessage(payload: MessagePayload, for cid: ChannelId?) throws -> MessageDTO? {
        try throwErrorIfNeeded()
        return try? underlyingSession.saveMessage(payload: payload, for: cid)
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
    
    func saveChannelRead(
        cid: ChannelId,
        userId: UserId,
        lastReadAt: Date,
        unreadMessageCount: Int
    ) throws -> ChannelReadDTO {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannelRead(
            cid: cid,
            userId: userId,
            lastReadAt: lastReadAt,
            unreadMessageCount: unreadMessageCount
        )
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

    func loadChannelMutes(for cid: ChannelId) -> [ChannelMuteDTO] {
        underlyingSession.loadChannelMutes(for: cid)
    }

    func loadChannelMutes(for userId: UserId) -> [ChannelMuteDTO] {
        underlyingSession.loadChannelMutes(for: userId)
    }

    func loadChannelMute(cid: ChannelId, userId: String) -> ChannelMuteDTO? {
        underlyingSession.loadChannelMute(cid: cid, userId: userId)
    }
    
    func deleteChannels(query: ChannelListQuery) throws {
        try underlyingSession.deleteChannels(query: query)
    }

    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery) throws -> MessageDTO? {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMessage(payload: payload, for: query)
    }

    func deleteQuery(_ query: MessageSearchQuery) {
        underlyingSession.deleteQuery(query)
    }
}

private extension DatabaseSessionMock {
    func throwErrorIfNeeded() throws {
        guard let error = errorToReturn else { return }
        throw error
    }
}
