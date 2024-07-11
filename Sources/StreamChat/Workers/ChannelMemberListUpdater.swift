//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channel members query call to the backend and updates the local storage with the results.
class ChannelMemberListUpdater: Worker {
    /// Makes a channel members query call to the backend and updates the local storage with the results.
    /// - Parameters:
    ///   - query: The query used in the request.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func load(_ query: ChannelMemberListQuery, completion: ((Result<[ChatChannelMember], Error>) -> Void)? = nil) {
        fetchAndSaveChannelIfNeeded(query.cid) { [weak self] error in
            if let error {
                completion?(.failure(error))
                return
            }

            let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
            self?.apiClient.request(endpoint: membersEndpoint) { membersResult in
                switch membersResult {
                case let .success(memberListPayload):
                    var members = [ChatChannelMember]()
                    self?.database.write({ session in
                        members = try session.saveMembers(
                            payload: memberListPayload,
                            channelId: query.cid,
                            query: query
                        )
                        .map { try $0.asModel() }
                    }, completion: { error in
                        if let error = error {
                            log.error("Failed to save `ChannelMemberListQuery` related data to the database. Error: \(error)")
                            completion?(.failure(error))
                        } else {
                            completion?(.success(members))
                        }
                    })
                case let .failure(error):
                    completion?(.failure(error))
                }
            }
        }
    }
}

extension ChannelMemberListUpdater {
    func load(_ query: ChannelMemberListQuery) async throws -> [ChatChannelMember] {
        try await withCheckedThrowingContinuation { continuation in
            load(query) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func member(with userId: UserId, cid: ChannelId) async throws -> ChatChannelMember {
        let members = try await load(.channelMember(userId: userId, cid: cid))
        guard let member = members.first else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
        return member
    }
}

// MARK: - Private

private extension ChannelMemberListUpdater {
    func fetchAndSaveChannelIfNeeded(_ cid: ChannelId, completion: @escaping (Error?) -> Void) {
        checkChannelExistsLocally(with: cid) { [weak self] exists in
            exists ? completion(nil) : self?.fetchAndSaveChannel(with: cid, completion: completion)
        }
    }

    func fetchAndSaveChannel(with cid: ChannelId, completion: @escaping (Error?) -> Void) {
        let query = ChannelQuery(cid: cid)
        apiClient.request(endpoint: .updateChannel(query: query)) { [weak self] in
            switch $0 {
            case let .success(payload):
                self?.database.write({ session in
                    try session.saveChannel(payload: payload)
                }, completion: { error in
                    if let error = error {
                        log.error("Failed to save channel to the database. Error: \(error)")
                    }
                    completion(error)
                })
            case let .failure(error):
                completion(error)
            }
        }
    }

    func checkChannelExistsLocally(with cid: ChannelId, completion: @escaping (Bool) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let exists = context.channel(cid: cid) != nil
            completion(exists)
        }
    }
}
