//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable
import StreamChat

final class DatabaseCleanupUpdater_Mock: DatabaseCleanupUpdater {
    var syncChannelListQueries_syncedChannelIDs: Set<ChannelId>?
    var syncChannelListQueries_completion: ((Result<Void, Error>) -> Void)?
    
    override func syncChannelListQueries(
        syncedChannelIDs: Set<ChannelId>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        syncChannelListQueries_syncedChannelIDs = syncedChannelIDs
        syncChannelListQueries_completion = completion
    }
    
    func cleanUp() {
        syncChannelListQueries_syncedChannelIDs = nil
        syncChannelListQueries_completion = nil
    }
}
