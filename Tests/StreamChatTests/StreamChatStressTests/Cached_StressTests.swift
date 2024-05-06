//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class Cached_Tests: StressTestCase {
    let queue = DispatchQueue(label: "io.getstream.tests.cached")
    var counter: Int!
    @Cached var value: Int!

    override func setUp() {
        super.setUp()

        counter = 0
        _value = Cached()

        _value.computeValue = { [unowned self] in
            // Return the current counter value and increase the counter
            queue.sync {
                let value = counter
                counter += 1
                return value
            }
        }
    }

    override func tearDown() {
        super.tearDown()
        counter = nil
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
    
    func test_resetAndRead_whenRunningConcurrently() {
        _value.computeValue = { Int.max }
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            self._value.reset()
            _ = self.value
        }
        XCTAssertEqual(value, Int.max)
    }
    
    func test_exclusiveAccess_whenComputeValueTriggersReset() throws {
        // 1. `EntityDatabaseObserver.item` was accessed but since the cached value was nil, `computeValue` was called
        // 2. Compute value for the `EntityDatabaseObserver.item` triggered CoreData object change
        // 3. CoreData change was picked up by the `EntityDatabaseObserver` which ended up calling `item.reset()`
        // Result: Crash because computeValue was called from the Atomic's mutate function and therefore all the code was
        // triggered from the mutate. `item.reset()` triggered another mutate and then Swift's runtime crashed the app
        // because it requires exclusive access (`mutate` uses inout parameters!).
        // This test would crash if `computeValue` is called within `mutate`.
        let loader = ExclusiveAccessTriggeringLoader(computeValueResult: 1)
        let result = loader.readValue()
        XCTAssertEqual(result, 1)
    }
}

private extension Cached_Tests {
    /// Triggers crash if `computeValue` is called from `mutate(_:)`.
    final class ExclusiveAccessTriggeringLoader {
        @Cached private var value: Int?

        init(computeValueResult: Int) {
            _value.computeValue = { [weak self] in
                self?.simulateComputeValueTriggeringCoreDataChangeWhichLeadsToCallingResetOnTheSameProperty()
                return computeValueResult
            }
        }

        func readValue() -> Int? {
            value
        }

        private func simulateComputeValueTriggeringCoreDataChangeWhichLeadsToCallingResetOnTheSameProperty() {
            // Simulates the case of a CoreData change which in turn ended up calling reset on the item
            _value.reset()
        }
    }
}
