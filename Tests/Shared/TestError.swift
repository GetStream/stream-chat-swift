//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Uniquely identifiable error that can be used in tests.
struct TestError: Error, Equatable {
    let id = UUID()
}
