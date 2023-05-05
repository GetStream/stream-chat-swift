//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A decorator of the `MessagesPaginationStateHandling` to make sure it is thread safe.
class MessagesPaginationThreadSafeDecorator: MessagesPaginationStateHandling {
    let queue = DispatchQueue(label: "io.getstream.messages-pagination-state-handler")
    let decoratee: MessagesPaginationStateHandling

    init(decoratee: MessagesPaginationStateHandling) {
        self.decoratee = decoratee
    }

    var state: MessagesPaginationState {
        queue.sync {
            self.decoratee.state
        }
    }

    func start(pagination: MessagesPagination) {
        queue.sync {
            self.decoratee.start(pagination: pagination)
        }
    }

    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>) {
        queue.sync {
            self.decoratee.end(pagination: pagination, with: result)
        }
    }
}
