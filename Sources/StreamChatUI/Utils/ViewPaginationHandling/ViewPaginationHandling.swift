//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

protocol ViewPaginationHandling {
    var topThreshold: Int { get set }
    var bottomThreshold: Int { get set }

    var onNewTopPage: (() -> Void)? { get set }
    var onNewBottomPage: (() -> Void)? { get set }
}
