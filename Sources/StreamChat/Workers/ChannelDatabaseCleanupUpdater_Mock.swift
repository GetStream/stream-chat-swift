//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable
import StreamChat

final class ChannelDatabaseCleanupUpdaterMock<ExtraData: ExtraDataTypes>: ChannelDatabaseCleanupUpdater<ExtraData> {
    @Atomic var cleanupChannelsData_called = false
    
    func cleanUp() {
        cleanupChannelsData_called = false
    }
    
    override func cleanupChannelsData() {
        cleanupChannelsData_called = true
    }
}
