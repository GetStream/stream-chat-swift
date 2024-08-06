//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChannelListObserver` implementation allowing capturing the delegate calls
final class TestChannelListObserver {
    let databaseObserver: StateLayerDatabaseObserver<ListResult, ChannelId, ChannelDTO>

    var observedChanges: [ListChange<ChannelId>] = []

    init(database: DatabaseContainer_Spy) {
        databaseObserver = StateLayerDatabaseObserver<ListResult, ChannelId, ChannelDTO>(
            database: database,
            fetchRequest: ChannelDTO.allChannelsFetchRequest,
            itemCreator: { try! ChannelId(cid: $0.cid) },
            itemReuseKeyPaths: nil
        )

        try! databaseObserver.startObserving(onContextDidChange: { [weak self] _, changes in
            self?.observedChanges.append(contentsOf: changes)
        })
    }
}
