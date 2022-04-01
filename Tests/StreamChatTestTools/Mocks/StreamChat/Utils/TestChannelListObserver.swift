//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChannelListObserver` implementation allowing capturing the delegate calls
final class TestChannelListObserver {
    let databaseObserver: ListDatabaseObserver<ChannelId, ChannelDTO>

    var observedChanges: [ListChange<ChannelId>] = []

    init(database: DatabaseContainer_Spy) {
        databaseObserver = ListDatabaseObserver<ChannelId, ChannelDTO>(
            context: database.viewContext,
            fetchRequest: ChannelDTO.allChannelsFetchRequest,
            itemCreator: { try! ChannelId(cid: $0.cid) }
        )

        databaseObserver.onChange = { [weak self] in
            self?.observedChanges.append(contentsOf: $0)
        }

        try! databaseObserver.startObserving()
    }
}
