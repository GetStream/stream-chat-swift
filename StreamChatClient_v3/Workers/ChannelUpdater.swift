//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

class ChannelUpdater<ExtraData: ExtraDataTypes>: Worker {
    func update(channelQuery: ChannelQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .channel(query: channelQuery)) { (result) in
            do {
                let payload = try result.get()
                self.database.write { (session) in
                    try session.saveChannel(payload: payload)
                    completion?(nil)
                }
            } catch {
                completion?(error)
            }
        }
    }

    func muteChannel(cid: ChannelId, mute: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .muteChannel(cid: cid, mute: mute)) {
            switch $0 {
            case .success:
                completion?(nil)
            case let .failure(error):
                completion?(error)
            }
        }
    }
}
