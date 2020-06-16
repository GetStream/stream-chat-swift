//
// Atomic_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class Atomic_Tests: XCTestCase {
    @Atomic var stringAtomicValue: String?
    @Atomic var intAtomicValue: Int = 0
    
    func test_Atomic_asPropertyWrapper() {
        stringAtomicValue = nil
        XCTAssertEqual(stringAtomicValue, nil)
        
        stringAtomicValue = "Luke"
        XCTAssertEqual(stringAtomicValue, "Luke")
        
        _stringAtomicValue { value in
            XCTAssertEqual(value, "Luke")
            value = nil
        }
        XCTAssertEqual(stringAtomicValue, nil)
    }
    
    func test_Atomic_usedAsCounter() {
        intAtomicValue = 0
        
        // Count up to numberOfCycles
        for _ in 0 ..< numberOfStressTestCycles {
            DispatchQueue.random.async {
                self._intAtomicValue { $0 += 1 }
            }
        }
        AssertAsync.willBeEqual(intAtomicValue, numberOfStressTestCycles)
        
        // Count down to zero
        for _ in 0 ..< numberOfStressTestCycles {
            DispatchQueue.random.async {
                self._intAtomicValue { $0 -= 1 }
            }
        }
        AssertAsync.willBeEqual(intAtomicValue, 0)
    }
}

// MARK: - Stress tests

extension Atomic_Tests {
    /// Increase `numberOfStressTestCycles` significantly to properly stress-test `Atomic`.
    var numberOfStressTestCycles: Int { 50 }
    
    func test_Atomic_underHeavyLoad() {
        for _ in 0 ..< 100 {
            test_Atomic_usedAsCounter()
            test_Atomic_usedWithCollection()
            test_Atomic_whenSetAndGetCalledSimultaneously()
            test_Atomic_whenCalledFromMainThred()
        }
    }
    
    func test_Atomic_usedWithCollection() {
        var atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        for idx in 0 ..< numberOfStressTestCycles {
            DispatchQueue.random.async {
                atomicValue.mutate { $0["\(idx)"] = idx }
            }
        }
        
        AssertAsync.willBeEqual(atomicValue.wrappedValue.count, numberOfStressTestCycles)
    }
    
    func test_Atomic_whenSetAndGetCalledSimultaneously() {
        var atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        let readGroup = DispatchGroup()
        for idx in 0 ..< numberOfStressTestCycles {
            DispatchQueue.random.async {
                atomicValue { $0["\(idx)"] = idx }
            }
            
            for _ in 0 ... 5 {
                readGroup.enter()
                DispatchQueue.random.async {
                    _ = atomicValue.wrappedValue
                    readGroup.leave()
                }
            }
        }
        
        AssertAsync.willBeEqual(atomicValue.wrappedValue.count, numberOfStressTestCycles)
        
        // Wait until all reading is done to prevent bad access
        readGroup.wait()
    }
    
    func test_Atomic_whenCalledFromMainThred() {
        var value = Atomic<[String: Int]>(wrappedValue: [:])
        
        for idx in 0 ..< numberOfStressTestCycles {
            value { $0["\(idx)"] = idx }
            value.wrappedValue = ["random": 2020]
            _ = value.wrappedValue
        }
        
        XCTAssertEqual(value.wrappedValue, ["random": 2020])
    }
}

private extension DispatchQueue {
    private static let queueIdKey = DispatchSpecificKey<String>()
    private static let testQueueId = UUID().uuidString
    
    /// Returns one of the existing global Dispatch queues.
    static var random: DispatchQueue {
        let allQoS: [DispatchQoS.QoSClass] = [
            .userInteractive,
            .userInitiated,
            .default
        ]
        return DispatchQueue.global(qos: allQoS.randomElement()!)
    }
    
    /// Creates a queue which can be later identified.
    static var testQueue: DispatchQueue {
        let queue = DispatchQueue(label: "Test queue")
        queue.setSpecific(key: Self.queueIdKey, value: testQueueId)
        return queue
    }
    
    /// Checks if the current queue is the queue created by `DispatchQueue.testQueue`.
    static var isTestQueue: Bool {
        DispatchQueue.getSpecific(key: queueIdKey) == testQueueId
    }
}
