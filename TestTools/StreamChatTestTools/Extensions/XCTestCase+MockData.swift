//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {
    public static func mockData(fromJSONFile name: String) -> Data {
        let file = "\(Bundle.testTools.pathToJSONsFolder)\(name)"
        guard let url = Bundle.testTools.url(forResource: file, withExtension: "json") else {
            XCTFail("\n❌ Mock file \"\(file).json\" not found in bundle \(Bundle.testTools.bundleURL.lastPathComponent)")
            return .init()
        }
        
        return try! Data(contentsOf: url)
    }
}
