//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable
import StreamChat

final class DatabaseCleanupUpdater_Mock: DatabaseCleanupUpdater {
    var resetExistingChannelsData_body: (DatabaseSession) -> Void = { _ in }
    override func resetExistingChannelsData(session: DatabaseSession) {
        resetExistingChannelsData_body(session)
    }

    var refetchExistingChannelListQueries_body: () -> Void = {}
    override func refetchExistingChannelListQueries() {
        refetchExistingChannelListQueries_body()
    }
}
