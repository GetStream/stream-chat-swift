//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable
import StreamChat

final class DatabaseCleanupUpdater_Mock: DatabaseCleanupUpdater {
    var syncChannelListQueries_syncedChannelIDs: Set<ChannelId>?
    
    override func syncChannelListQueries(syncedChannelIDs: Set<ChannelId>) {
        syncChannelListQueries_syncedChannelIDs = syncedChannelIDs
    }
    
    func cleanUp() {
        syncChannelListQueries_syncedChannelIDs = nil
    }
}
