//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class TestChannelObserver {
    let databaseObserver: EntityDatabaseObserver<ChatChannel, ChannelDTO>

    var observedChanges: [EntityChange<ChatChannel>] = []

    init(cid: ChannelId, database: DatabaseContainer) {
        databaseObserver = .init(
            context: database.viewContext,
            fetchRequest: ChannelDTO.fetchRequest(for: cid),
            itemCreator: { try $0.asModel() }
        )

        databaseObserver.onChange { [weak self] change in
            self?.observedChanges.append(change)
        }

        try! databaseObserver.startObserving()
    }
}
