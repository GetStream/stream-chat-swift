//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol ViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: (() -> Void)? { get set }
    var onNewBottomPage: (() -> Void)? { get set }
}

typealias StatefulViewPaginationHandlingBlock = (((Int) -> Void, @escaping (Error?) -> Void) -> Void)
protocol StatefulViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: StatefulViewPaginationHandlingBlock? { get set }
    var onNewBottomPage: StatefulViewPaginationHandlingBlock? { get set }

    func updateElementsCount(with newCount: Int)
}
