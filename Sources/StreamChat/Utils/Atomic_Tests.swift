//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
        let group = DispatchGroup()
        intAtomicValue = 0

        // Count up to numberOfCycles
        for _ in 0..<numberOfTestCycles {
            group.enter()
            DispatchQueue.random.async {
                self._intAtomicValue { $0 += 1 }
                group.leave()
            }
        }

        group.wait()
        XCTAssertEqual(intAtomicValue, numberOfTestCycles)
    }
}

// MARK: - Stress tests

extension Atomic_Tests {
    /// Increase `numberOfTestCycles` significantly to properly stress-test `Atomic`.
    var numberOfTestCycles: Int { 50 }
    
    func test_Atomic_usedWithCollection() {
        let updateGroup = DispatchGroup()
        let atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        for idx in 0..<numberOfTestCycles {
            updateGroup.enter()
            DispatchQueue.random.async {
                atomicValue.mutate { $0["\(idx)"] = idx }
                updateGroup.leave()
            }
        }
        updateGroup.wait()

        XCTAssertEqual(atomicValue.wrappedValue.count, numberOfTestCycles)
    }
    
    func test_Atomic_whenSetAndGetCalledSimultaneously() {
        let atomicValue = Atomic<[String: Int]>(wrappedValue: [:])
        
        let group = DispatchGroup()
        for idx in 0..<numberOfTestCycles {
            group.enter()
            DispatchQueue.random.async {
                atomicValue { $0["\(idx)"] = idx }
                group.leave()
            }
            
            for _ in 0...5 {
                group.enter()
                DispatchQueue.random.async {
                    _ = atomicValue.wrappedValue
                    group.leave()
                }
            }
        }
        
        group.wait()
        XCTAssertEqual(atomicValue.wrappedValue.count, numberOfTestCycles)
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
