//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class Atomic_Tests: StressTestCase {
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
        for _ in 0..<numberOfTestCycles {
            DispatchQueue.random.async {
                self._intAtomicValue { $0 += 1 }
            }
        }
        AssertAsync.willBeEqual(intAtomicValue, numberOfTestCycles)
        
        // Count down to zero
        for _ in 0..<numberOfTestCycles {
            DispatchQueue.random.async {
                self._intAtomicValue { $0 -= 1 }
            }
        }
        AssertAsync.willBeEqual(intAtomicValue, 0)
    }
}

// MARK: - Stress tests

extension Atomic_Tests {
    /// Increase `numberOfTestCycles` significantly to properly stress-test `Atomic`.
    var numberOfTestCycles: Int { 50 }
    
    func test_Atomic_usedWithCollection() {
        let atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        for idx in 0..<numberOfTestCycles {
            DispatchQueue.random.async {
                atomicValue.mutate { $0["\(idx)"] = idx }
            }
        }
        
        AssertAsync.willBeEqual(atomicValue.wrappedValue.count, numberOfTestCycles)
    }
    
    func test_Atomic_whenSetAndGetCalledSimultaneously() {
        let atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        let readGroup = DispatchGroup()
        for idx in 0..<numberOfTestCycles {
            DispatchQueue.random.async {
                atomicValue { $0["\(idx)"] = idx }
            }
            
            for _ in 0...5 {
                readGroup.enter()
                DispatchQueue.random.async {
                    _ = atomicValue.wrappedValue
                    readGroup.leave()
                }
            }
        }
        
        AssertAsync.willBeEqual(atomicValue.wrappedValue.count, numberOfTestCycles)
        
        // Wait until all reading is done to prevent bad access
        readGroup.wait()
    }
    
    func test_Atomic_whenCalledFromMainThred() {
        let value = Atomic<[String: Int]>(wrappedValue: [:])
        
        for idx in 0..<numberOfTestCycles {
            value { $0["\(idx)"] = idx }
            value.wrappedValue = ["random": 2020]
            _ = value.wrappedValue
        }
        
        XCTAssertEqual(value.wrappedValue, ["random": 2020])
    }
}
