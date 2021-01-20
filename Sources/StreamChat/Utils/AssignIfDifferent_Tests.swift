//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

class AssignIfDifferent_Tests: StressTestCase {
    func test_assignIfDifferent_onlyAssignsIfDifferent() {
        class TestClass {
            var value: Int! {
                didSet {
                    if oldValue == value {
                        XCTFail("Same value is assigned!")
                    }
                }
            }
        }
        
        let value = Int.random(in: 0...1000)
        let item = TestClass()
        item.value = value
        
        // Call assignIfDifferent with the same value
        // `didSet` will fail if it is assigned again
        assignIfDifferent(item, \.value, value)
        
        let newValue = Int.random(in: value...value * 2)
        
        // Call assignIfDifferent with a different value
        assignIfDifferent(item, \.value, newValue)
        
        // It should be assigned
        XCTAssertEqual(item.value, newValue)
    }
}
