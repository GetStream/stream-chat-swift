//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

extension UITableView {
    public func reload<C: Differentiable>(
        previousSnapshot: [C],
        newSnapshot: [C],
        with animation: @autoclosure () -> RowAnimation,
        onNewData: ([C]) -> Void
    ) {
        let changeset = StagedChangeset(
            source: previousSnapshot,
            target: newSnapshot
        )
        reload(
            using: changeset,
            with: animation(),
            setData: onNewData
        )
    }
}

#endif
