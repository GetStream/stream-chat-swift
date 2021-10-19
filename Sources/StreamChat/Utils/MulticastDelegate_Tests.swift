//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MulticastDelegate_Tests: XCTestCase {
    fileprivate var multicastDelegate: MulticastDelegate<TestDelegate>!
    
    override func setUp() {
        super.setUp()
        
        multicastDelegate = .init()
    }

    func test_invoke_shouldCallDelegate() {
        let testDelegate = TestDelegate()
        assert(testDelegate.called == false)
        
        multicastDelegate.add(testDelegate)
        multicastDelegate.invoke {
            $0.called = true
        }
        
        XCTAssertTrue(testDelegate.called)
    }

    func test_add_shouldAddDelegate() {
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.add(testDelegate1)
        multicastDelegate.add(testDelegate2)

        XCTAssertEqual(multicastDelegate.delegates.count, 2)
        XCTAssertTrue(multicastDelegate.delegates.contains(where: { $0 === testDelegate1 }))
        XCTAssertTrue(multicastDelegate.delegates.contains(where: { $0 === testDelegate2 }))
    }

    func test_remove_shouldRemoveDelegate() {
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.add(testDelegate1)
        multicastDelegate.add(testDelegate2)
        
        XCTAssertEqual(multicastDelegate.delegates.count, 2)
        
        multicastDelegate.remove(testDelegate1)

        XCTAssert(multicastDelegate.delegates.first === testDelegate2)
        XCTAssertEqual(multicastDelegate.delegates.count, 1)
    }

    func test_removeAll_shouldRemoveAllDelegates() {
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.add(testDelegate1)
        multicastDelegate.add(testDelegate2)

        XCTAssertEqual(multicastDelegate.delegates.count, 2)

        multicastDelegate.removeAll()

        XCTAssertEqual(multicastDelegate.delegates.count, 0)
    }
}

private class TestDelegate {
    var called = false
}
