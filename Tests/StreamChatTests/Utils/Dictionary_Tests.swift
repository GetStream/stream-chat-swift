//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Dictionary_Tests: XCTestCase {
    func test_mapKeys() {
        // Declare key transformation closure.
        let keyTransform: (String) -> String = {
            [$0, $0].joined(separator: " ")
        }
        
        // Create array of keys with values.
        let keysAndValues = [
            ("like", 4),
            ("love", 3),
            ("cat", 1)
        ]
        
        // Create array of mapped keys with values.
        let mappedKeysAndValues = keysAndValues.map {
            (keyTransform($0), $1)
        }
        
        // Create dict with initial keys and values.
        let initial = Dictionary(uniqueKeysWithValues: keysAndValues)
        
        // Create dict with mapped keys and values.
        let expected = Dictionary(uniqueKeysWithValues: mappedKeysAndValues)
        
        // Assert `mapKeys` work correctly.
        XCTAssertEqual(initial.mapKeys(keyTransform), expected)
    }
}
