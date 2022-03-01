//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channel members query call to the backend and updates the local storage with the results.
class ChannelMemberListUpdater: Worker {
    /// Makes a channel members query call to the backend and updates the local storage with the results.
    /// - Parameters:
    ///   - query: The query used in the request.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func load(_ query: ChannelMemberListQuery, completion: ((Error?) -> Void)? = nil) {
        fetchAndSaveChannelIfNeeded(query.cid) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            let membersEndpoint: Endpoint<ChannelMemberListPayload> = .channelMembers(query: query)
            self.apiClient.request(endpoint: membersEndpoint) { membersResult in
                switch membersResult {
                case let .success(memberListPayload):
                    self.database.write({ session in
                        try memberListPayload.members.forEach {
                            try session.saveMember(
                                payload: $0,
                                channelId: query.cid,
                                query: query
                            )
                        }
                    }, completion: { error in
                        if let error = error {
                            log.error("Failed to save `ChannelMemberListQuery` related data to the database. Error: \(error)")
                        }
                        completion?(error)
                    })
                case let .failure(error):
                    completion?(error)
                }
            }
        }
    }
}

// MARK: - Private

private extension ChannelMemberListUpdater {
    func fetchAndSaveChannelIfNeeded(_ cid: ChannelId, completion: @escaping (Error?) -> Void) {
        checkChannelExistsLocally(with: cid) { exists in
            exists ? completion(nil) : self.fetchAndSaveChannel(with: cid, completion: completion)
        }
    }
    
    func fetchAndSaveChannel(with cid: ChannelId, completion: @escaping (Error?) -> Void) {
        let query = ChannelQuery(cid: cid)
        apiClient.request(endpoint: .updateChannel(query: query)) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
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
