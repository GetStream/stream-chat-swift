//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

final class CooldownTracker_Tests: XCTestCase {
    var sut: CooldownTracker!

    override func setUp() {
        super.setUp()
        sut = CooldownTracker(timer: Timer_Mock.self)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_onChangeIsExecutedProperly_whenCooldownTrackerIsStarts() {
        // GIVEN
        let cooldownTime = 3
        var triggerCounter = 0

        // WHEN
        sut.start(with: cooldownTime) { currentTime in
            XCTAssertEqual(cooldownTime - triggerCounter, currentTime)
            
            triggerCounter += 1
        }
        
        // THEN
        XCTAssertEqual(cooldownTime + 1, triggerCounter)
    }
}
