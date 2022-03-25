//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatChannel {
    func meets(_ filter: Filter<ChannelListFilterScope>) throws -> Bool {
        // This is a work in progress.
        // The idea is that in a further iteration we provide a runtime evaluation of the filter to determine
        // if the channel matches the filter. This is a costly operation, and it is recommended to avoid it.
        // The recommended approach is to pass `filterBlock` when initializing a `ChatChannelListController`
        //
        // This default implementation is the same we had in ChatChannelListVC's conformance of the deprecated methods
        // from ChatChannelListControllerDelegate, so no changes are expected for the end user.
        membership != nil
    }
}
