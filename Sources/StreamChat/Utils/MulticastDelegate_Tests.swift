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

    func test_mainDelegate_isCalled() {
        let mainDelegate = TestDelegate()
        assert(mainDelegate.called == false)
        
        multicastDelegate.mainDelegate = mainDelegate
        multicastDelegate.invoke {
            $0.called = true
        }
        
        XCTAssertTrue(mainDelegate.called)
    }

    func test_mainDelegate_isRessetable() {
        let mainDelegate = TestDelegate()
        
        multicastDelegate.mainDelegate = mainDelegate
        XCTAssert(multicastDelegate.mainDelegate === mainDelegate)
        
        multicastDelegate.mainDelegate = nil
        XCTAssertNil(multicastDelegate.mainDelegate)
    }
    
    func test_additionalDelegate_isCalled_whenNoMainDelegateIsSet() {
        let additionalDelegate = TestDelegate()
        
        multicastDelegate.additionalDelegates.append(additionalDelegate)
        multicastDelegate.invoke {
            $0.called = true
        }
        
        XCTAssertTrue(additionalDelegate.called)
    }

    func test_allDelegates_areCalled() {
        let mainDelegate = TestDelegate()
        let additionalDelegate = TestDelegate()
        
        multicastDelegate.mainDelegate = mainDelegate
        multicastDelegate.additionalDelegates.append(additionalDelegate)

        multicastDelegate.invoke {
            $0.called = true
        }
        
        XCTAssertTrue(mainDelegate.called)
        XCTAssertTrue(additionalDelegate.called)
    }
}

private class TestDelegate {
    var called = false
}
