//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {
    public static func mockData(fromFile name: String) -> Data {
        XCTestCase.mockData(fromFile: name, bundle: .testTools)
    }
}
