//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Cached_Tests: XCTestCase {
    private var counter: Int = 0
    @Cached private var value: Int?
    
    override func setUpWithError() throws {
        _value = Cached()
    }
    
    override func tearDownWithError() throws {
        counter = 0
    }
    
    func test_resetAndRead_whenRunningConcurrently() {
        _value.computeValue = { Int.max }
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            self._value.reset()
            _ = self.value
        }
        XCTAssertEqual(value, Int.max)
    }
    
    func test_reentrance_whenComputeValueTriggersAnotherMutate() throws {
        // We had a crash which followed these steps:
        // 1. `EntityDatabaseObserver.item` was accessed but since the cached value was nil, `computeValue` was called
        // 2. Compute value for the `EntityDatabaseObserver.item` triggered CoreData object change
        // 3. CoreData change was picked up by the `EntityDatabaseObserver` which ended up calling `item.reset()`
        // Crash because computeValue was called from the Atomic's mutate function and therefore all the code was triggered from the mutate. `item.reset()` triggered another mutate and then Swift's runtime crashed the app because it requires exclusive access (`mutate` uses inout parameters!).
        let loader = Loader()
        let result = loader.start()
        XCTAssertEqual(result, 1)
    }
}

extension Cached_Tests {
    final class Loader {
        @Cached private var value: Int?
        
        init() {
            _value.computeValue = { [weak self] in
                self?.noteSomethingChangedWhichCausesToResetTheValue()
                return 1
            }
        }
        
        func start() -> Int {
            value ?? 0
        }
        
        func noteSomethingChangedWhichCausesToResetTheValue() {
            // Simulates the case of a CoreData change which in turn ended up calling reset on the item
            _value.reset()
        }
    }
}
