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
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws {
        try throwErrorIfNeeded()
        try underlyingSession.saveCurrentUserDevices(devices, clearExisting: clearExisting)
    }
    
    func saveChannel<ExtraData>(
        payload: ChannelDetailPayload<ExtraData>,
        query: _ChannelListQuery<ExtraData.Channel>?
    ) throws -> ChannelDTO where ExtraData: ExtraDataTypes {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannel(payload: payload, query: query)
    }
    
    func saveUser<ExtraData>(payload: UserPayload<ExtraData>, query: _UserListQuery<ExtraData>?) throws -> UserDTO
        where ExtraData: UserExtraData {
        try throwErrorIfNeeded()
        return try underlyingSession.saveUser(payload: payload, query: query)
    }
    
    func saveQuery<ExtraData>(query: _UserListQuery<ExtraData>) throws -> UserListQueryDTO? where ExtraData: UserExtraData {
        try throwErrorIfNeeded()
        return try underlyingSession.saveQuery(query: query)
    }
    
    func user(id: UserId) -> UserDTO? {
        underlyingSession.user(id: id)
    }
    
    func deleteQuery<ExtraData>(_ query: _UserListQuery<ExtraData>) where ExtraData: UserExtraData {
        underlyingSession.deleteQuery(query)
    }
    
    func saveCurrentUser<ExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO
        where ExtraData: ExtraDataTypes {
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
    
    func createNewMessage<ExtraData>(
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
        extraData: ExtraData
    ) throws -> MessageDTO where ExtraData: MessageExtraData {
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
            extraData: extraData
        )
    }
    
    func saveMessage<ExtraData>(payload: MessagePayload<ExtraData>, for cid: ChannelId?) throws -> MessageDTO
        where ExtraData: ExtraDataTypes {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMessage(payload: payload, for: cid)
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
    
    func saveReaction<ExtraData>(payload: MessageReactionPayload<ExtraData>) throws -> MessageReactionDTO
        where ExtraData: ExtraDataTypes {
        try throwErrorIfNeeded()
        return try underlyingSession.saveReaction(payload: payload)
    }
    
    func delete(reaction: MessageReactionDTO) {
        underlyingSession.delete(reaction: reaction)
    }
    
    func saveChannelRead<ExtraData>(payload: ChannelReadPayload<ExtraData>, for cid: ChannelId) throws -> ChannelReadDTO
        where ExtraData: ExtraDataTypes {
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
    
    func saveChannel<ExtraData>(
        payload: ChannelPayload<ExtraData>,
        query: _ChannelListQuery<ExtraData.Channel>?
    ) throws -> ChannelDTO where ExtraData: ExtraDataTypes {
        try throwErrorIfNeeded()
        return try underlyingSession.saveChannel(payload: payload, query: query)
    }
    
    func channel(cid: ChannelId) -> ChannelDTO? {
        underlyingSession.channel(cid: cid)
    }
    
    func saveMember<ExtraData>(
        payload: MemberPayload<ExtraData>,
        channelId: ChannelId,
        query: _ChannelMemberListQuery<ExtraData>?
    ) throws -> MemberDTO where ExtraData: UserExtraData {
        try throwErrorIfNeeded()
        return try underlyingSession.saveMember(payload: payload, channelId: channelId, query: query)
    }
    
    func member(userId: UserId, cid: ChannelId) -> MemberDTO? {
        underlyingSession.member(userId: userId, cid: cid)
    }
    
    func channelMemberListQuery(queryHash: String) -> ChannelMemberListQueryDTO? {
        underlyingSession.channelMemberListQuery(queryHash: queryHash)
    }
    
    func saveQuery<ExtraData>(_ query: _ChannelMemberListQuery<ExtraData>) throws -> ChannelMemberListQueryDTO
        where ExtraData: UserExtraData {
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

    func saveChannelMute<ExtraData>(
        payload: MutedChannelPayload<ExtraData>
    ) throws -> ChannelMuteDTO where ExtraData: ExtraDataTypes {
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
}

private extension DatabaseSessionMock {
    func throwErrorIfNeeded() throws {
        guard let error = errorToReturn else { return }
        throw error
    }
}
