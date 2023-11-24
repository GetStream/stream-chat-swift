//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol ViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: ((@escaping () -> Void) -> Void)? { get set }
    var onNewBottomPage: ((@escaping () -> Void) -> Void)? { get set }
}
