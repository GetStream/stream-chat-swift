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
    func load(_ query: ChannelMemberListQuery, completion: ((Error?) -> Void)? = nil) {
        fetchAndSaveChannelIfNeeded(query.cid) { [weak self] error in
            guard error == nil else {
                completion?(error)
                return
            }

            var filter: [String: RawJSON]?
            if let data = try? JSONEncoder.default.encode(query.filter) {
                filter = try? JSONDecoder.default.decode([String: RawJSON].self, from: data)
            }
            
            let sort = query.sort.map { sortingKey in
                SortParam(direction: sortingKey.direction, field: sortingKey.key.rawValue)
            }
            
            let request = QueryMembersRequest(
                type: query.cid.type.rawValue,
                filterConditions: filter ?? [:],
                id: query.cid.id,
                limit: query.pagination.pageSize,
                offset: query.pagination.offset,
                sort: sort
            )
            
            self?.api.queryMembers(payload: request, completion: { [weak self] membersResult in
                switch membersResult {
                case let .success(memberListPayload):
                    self?.database.write({ session in
                        session.saveMembers(payload: memberListPayload, channelId: query.cid, query: query)
                    }, completion: { error in
                        if let error = error {
                            log.error("Failed to save `ChannelMemberListQuery` related data to the database. Error: \(error)")
                        }
                        completion?(error)
                    })
                case let .failure(error):
                    completion?(error)
                }
            })
        }
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
        api.getOrCreateChannel(
            type: query.apiPath,
            channelGetOrCreateRequest: ChannelGetOrCreateRequest(),
            clientId: nil, // TODO: check this.
            requiresConnectionId: true
        ) { [weak self] result in
            switch result {
            case let .success(payload):
                self?.database.write({ session in
                    _ = try session.saveChannel(payload: payload.toResponseFields, query: nil, cache: nil)
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
