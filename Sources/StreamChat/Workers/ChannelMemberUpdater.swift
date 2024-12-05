//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes channel member related calls to the backend.
class ChannelMemberUpdater: Worker {
    /// Updates the channel member with additional information.
    /// - Parameters:
    ///   - userId: The user id of the member.
    ///   - cid: The channel which the member should be updated.
    ///   - updates: The additional information.
    ///   - unset: The properties to be unset/cleared.
    func partialUpdate(
        userId: UserId,
        in cid: ChannelId,
        updates: MemberUpdatePayload?,
        unset: [String]?,
        completion: @escaping ((Result<ChatChannelMember, Error>) -> Void)
    ) {
        apiClient.request(
            endpoint: .partialMemberUpdate(
                userId: userId,
                cid: cid,
                updates: updates,
                unset: unset
            )
        ) { result in
            switch result {
            case .success(let response):
                self.database.write { session in
                    let member = try session.saveMember(payload: response.channelMember, channelId: cid).asModel()
                    completion(.success(member))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func pinMemberChannel(
        _ isPinned: Bool,
        userId: UserId,
        cid: ChannelId,
        completion: @escaping (Error?) -> Void
    ) {
        partialUpdate(
            userId: userId,
            in: cid,
            updates: isPinned ? MemberUpdatePayload(pinned: true) : nil,
            unset: isPinned ? nil : [MemberUpdatePayload.CodingKeys.pinned.rawValue],
            completion: { completion($0.error) }
        )
    }
    
    func pinMemberChannel(
        _ isPinned: Bool,
        userId: UserId,
        cid: ChannelId
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            pinMemberChannel(isPinned, userId: userId, cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func archiveMemberChannel(
        _ isArchived: Bool,
        userId: UserId,
        cid: ChannelId,
        completion: @escaping (Error?) -> Void
    ) {
        partialUpdate(
            userId: userId,
            in: cid,
            updates: isArchived ? MemberUpdatePayload(archived: true) : nil,
            unset: isArchived ? nil : [MemberUpdatePayload.CodingKeys.archived.rawValue],
            completion: { completion($0.error) }
        )
    }
    
    func archiveMemberChannel(
        _ isArchived: Bool,
        userId: UserId,
        cid: ChannelId
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            archiveMemberChannel(isArchived, userId: userId, cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    /// Bans the user in the channel.
    /// - Parameters:
    ///   - userId: The user identifier to ban.
    ///   - cid: The channel identifier to ban in.
    ///   - shadow: If true, it performs a shadow ban.
    ///   - timeoutInMinutes: The # of minutes the user should be banned for.
    ///   - reason: The ban reason.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        shadow: Bool,
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .banMember(userId, cid: cid, shadow: shadow, timeoutInMinutes: timeoutInMinutes, reason: reason)
        ) {
            completion?($0.error)
        }
    }

    /// Unbans the user in the channel.
    /// - Parameters:
    ///   - userId: The user identifier to unban.
    ///   - cid: The channel identifier to unban in.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func unbanMember(
        _ userId: UserId,
        in cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .unbanMember(userId, cid: cid)) {
            completion?($0.error)
        }
    }
}

extension ChannelMemberUpdater {
    func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        shadow: Bool,
        for timeoutInMinutes: Int?,
        reason: String?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            banMember(
                userId,
                in: cid,
                shadow: shadow,
                for: timeoutInMinutes,
                reason: reason
            ) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func unbanMember(_ userId: UserId, in cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unbanMember(userId, in: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
}
