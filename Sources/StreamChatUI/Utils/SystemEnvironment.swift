//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

enum SystemEnvironment {
    static var isTests: Bool {
        #if TESTS
        return NSClassFromString("XCTest") != nil
        #else
        return false
        #endif
    }
}
