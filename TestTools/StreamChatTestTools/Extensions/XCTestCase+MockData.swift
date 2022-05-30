//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {
    public static func mockData(fromJSONFile name: String) -> Data {
        XCTestCase.mockData(fromFile: "\(Bundle.testTools.pathToJSONsFolder)\(name)", bundle: .testTools)
    }
}
