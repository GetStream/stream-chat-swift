//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class TestChannelObserver {
    let databaseObserver: StateLayerDatabaseObserver<EntityResult, ChatChannel, ChannelDTO>

    var observedChanges: [EntityChange<ChatChannel>] = []

    init(cid: ChannelId, database: DatabaseContainer) {
        databaseObserver = StateLayerDatabaseObserver(
            database: database,
            fetchRequest: ChannelDTO.fetchRequest(for: cid),
            itemCreator: { try $0.asModel() }
        )

        try! databaseObserver.startObserving(onContextDidChange: { [weak self] _, change in
            self?.observedChanges.append(change)
        })
    }
}
