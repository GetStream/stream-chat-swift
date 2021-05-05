//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable
import StreamChat

final class ChannelListCleanupUpdaterMock<ExtraData: ExtraDataTypes>: ChannelListCleanupUpdater<ExtraData> {
    @Atomic var cleanupChannelList_called = false
    
    func cleanUp() {
        cleanupChannelList_called = false
    }
    
    override func cleanupChannelList() {
        cleanupChannelList_called = true
    }
}
