//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Weak_Tests: StressTestCase {
    func test_value_returnsObjectWhenItIsAlive() {
        // Create an object
        let object = ChatClient.mock
        
        // Create a wrapper
        let wrapper = Weak(value: object)
        
        // Assert wrapper's value is the reference to the object
        XCTAssertTrue(wrapper.value === object)
    }
    
    func test_value_returnsNilWhenObjectIsDeallocated() {
        // Create an object
        var object: ChatClient? = ChatClient.mock
        
        // Create a wrapper
        let wrapper = Weak(value: object!)
        
        // Remove all strong refs to object
        object = nil
        
        // Assert wrapper's value is nil
        XCTAssertNil(wrapper.value)
    }
    
    func test_wrapperDoesNotRetainObject() {
        // Create an object
        var object: ChatClient? = ChatClient.mock
        
        // Create a wrapper
        let wrapper = Weak(value: object!)
        
        // Assert object can be released
        AssertAsync.canBeReleased(&object)
        
        // Access wrapper so there's no warning that it's unused
        _ = wrapper
    }
}
