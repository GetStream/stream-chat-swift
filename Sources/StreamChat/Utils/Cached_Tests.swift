//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class Cached_Tests: StressTestCase {
    var counter: Int!
    @Cached var value: Int!
    
    override func setUp() {
        super.setUp()
        
        counter = 0
        _value = Cached()
        
        _value.computeValue = { [weak self] in
            // Return the current counter value and increase the counter
            defer { self?.counter += 1 }
            return self?.counter ?? 0
        }
    }
    
    func test_valueIsCached() {
        // Assert the value gets cached
        for _ in 0...10 {
            XCTAssertEqual(value, 0)
        }
    }
    
    func test_valueIsRecomputed_whenResetCalled() {
        XCTAssertEqual(value, 0)
        
        // Reset the cached value
        _value.reset()
        
        // Assert a value gets computed
        for _ in 0...10 {
            XCTAssertEqual(value, 1)
        }
    }
    
    /// This test doesn't really check the results, it just checks the program doesn't crash.
    func test_cachedWorksCorrentlyInMulthithreadedEnvironment() {
        let group = DispatchGroup()
        for _ in 0...1000 {
            group.enter()
            DispatchQueue.random.async {
                _ = self.value
                group.leave()
            }
            
            group.enter()
            DispatchQueue.random.async {
                self._value.reset()
                group.leave()
            }
        }
        group.wait()
    }
}
