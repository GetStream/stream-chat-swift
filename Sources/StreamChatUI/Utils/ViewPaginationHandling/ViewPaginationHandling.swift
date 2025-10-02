//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

@MainActor protocol ViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: (() -> Void)? { get set }
    var onNewBottomPage: (() -> Void)? { get set }
}

typealias StatefulViewPaginationHandlingBlock = ((_ notifyItemCount: (Int) -> Void, _ completion: @escaping @Sendable (Error?) -> Void) -> Void)
@MainActor protocol StatefulViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: StatefulViewPaginationHandlingBlock? { get set }
    var onNewBottomPage: StatefulViewPaginationHandlingBlock? { get set }

    func updateElementsCount(with newCount: Int)
}
