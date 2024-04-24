//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public protocol Spy: AnyObject {
    var spyState: SpyState { get }
}

public extension Spy {
    func clear() {
        spyState.clear()
    }
    
    func record(function: String = #function) {
        spyState.record(function)
    }

    func numberOfCalls(on function: String) -> Int {
        spyState.recordedFunctions.reduce(0) { $0 + ($1 == function ? 1 : 0) }
    }
    
    var recordedFunctions: [String] {
        spyState.recordedFunctions
    }
}

public final class SpyState {
    private let queue = DispatchQueue(label: "io.getstream.testtools.spystate")
    private var _recordedFunctions: [String] = []
    
    public init() {}
    
    func clear() {
        queue.sync { _recordedFunctions.removeAll() }
    }
    
    func record(_ function: String) {
        queue.sync { _recordedFunctions.append(function) }
    }
    
    var recordedFunctions: [String] {
        queue.sync { _recordedFunctions }
    }
}

extension String {
    public func wasCalled(on spy: Spy, times: Int? = nil) -> Bool {
        let function = self
        let wasCalled = spy.recordedFunctions.contains(function)

        guard wasCalled, let times = times else {
            return wasCalled
        }

        let callCount = spy.numberOfCalls(on: function)
        return callCount == times
    }

    public func wasNotCalled(on spy: Spy) -> Bool {
        !wasCalled(on: spy)
    }
}

public func XCTAssertCall(_ function: String, on spy: Spy, times: Int? = nil, file: StaticString = #filePath, line: UInt = #line) {
    if function.wasCalled(on: spy, times: times) {
        XCTAssertTrue(true, file: file, line: line)
        return
    }

    XCTFail("\(function) was called \(spy.numberOfCalls(on: function)) times", file: file, line: line)
}

public func XCTAssertNotCall(_ function: String, on spy: Spy, file: StaticString = #filePath, line: UInt = #line) {
    if function.wasNotCalled(on: spy) {
        XCTAssertTrue(true, file: file, line: line)
        return
    }

    XCTFail("\(function) was called \(spy.numberOfCalls(on: function)) times", file: file, line: line)
}
