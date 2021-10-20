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

    func test_invoke_shouldCallMainAndAdditionalDelegate() {
        let testMainDelegate = TestDelegate()
        let testAdditionalDelegate = TestDelegate()
        assert(testMainDelegate.called == false)
        assert(testAdditionalDelegate.called == false)

        multicastDelegate.set(mainDelegate: testMainDelegate)
        multicastDelegate.add(additionalDelegate: testAdditionalDelegate)

        multicastDelegate.invoke {
            $0.called = true
        }
        
        XCTAssertTrue(testMainDelegate.called)
        XCTAssertTrue(testAdditionalDelegate.called)
    }

    func test_setMainDelegate_shouldSetMainDelegate() {
        let testMainDelegate = TestDelegate()

        multicastDelegate.set(mainDelegate: testMainDelegate)

        XCTAssertTrue(multicastDelegate.mainDelegate === testMainDelegate)
    }

    func test_setMainDelegate_whenAlreadySet_shouldReplaceMainDelegate() {
        let testMainDelegate1 = TestDelegate()
        let testMainDelegate2 = TestDelegate()

        multicastDelegate.set(mainDelegate: testMainDelegate1)
        multicastDelegate.set(mainDelegate: testMainDelegate2)

        XCTAssertTrue(multicastDelegate.mainDelegate === testMainDelegate2)
    }

    func test_setMainDelegate_whenNilProvided_shouldRemoveMainDelegate() {
        let testMainDelegate = TestDelegate()

        multicastDelegate.set(mainDelegate: testMainDelegate)
        multicastDelegate.set(mainDelegate: nil)

        XCTAssertNil(multicastDelegate.mainDelegate)
    }

    func test_addAdditionalDelegate_shouldAddDelegate() {
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.add(additionalDelegate: testDelegate1)
        multicastDelegate.add(additionalDelegate: testDelegate2)

        XCTAssertEqual(multicastDelegate.additionalDelegates.count, 2)
        XCTAssertTrue(multicastDelegate.additionalDelegates.contains(where: { $0 === testDelegate1 }))
        XCTAssertTrue(multicastDelegate.additionalDelegates.contains(where: { $0 === testDelegate2 }))
    }

    func test_removeAdditionalDelegate_shouldRemoveDelegate() {
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.add(additionalDelegate: testDelegate1)
        multicastDelegate.add(additionalDelegate: testDelegate2)
        
        XCTAssertEqual(multicastDelegate.additionalDelegates.count, 2)
        
        multicastDelegate.remove(additionalDelegate: testDelegate1)

        XCTAssert(multicastDelegate.additionalDelegates.first === testDelegate2)
        XCTAssertEqual(multicastDelegate.additionalDelegates.count, 1)
    }

    func test_removeAll_shouldRemoveMainAndAllAdditionalDelegates() {
        let mainDelegate = TestDelegate()
        let testDelegate1 = TestDelegate()
        let testDelegate2 = TestDelegate()

        multicastDelegate.set(mainDelegate: mainDelegate)
        multicastDelegate.add(additionalDelegate: testDelegate1)
        multicastDelegate.add(additionalDelegate: testDelegate2)

        XCTAssertNotNil(multicastDelegate.mainDelegate)
        XCTAssertFalse(multicastDelegate.additionalDelegates.isEmpty)

        multicastDelegate.removeAll()

        XCTAssertNil(multicastDelegate.mainDelegate)
        XCTAssertTrue(multicastDelegate.additionalDelegates.isEmpty)
    }
}

private class TestDelegate {
    var called = false
}
