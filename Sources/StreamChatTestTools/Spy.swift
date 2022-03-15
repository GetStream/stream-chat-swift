//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public protocol Spy: AnyObject {
    var recordedFunctions: [String] { get set }
}

public extension Spy {
    func clear() {
        recordedFunctions.removeAll()
    }

    func record(function: String = #function) {
        recordedFunctions.append(function)
    }

    func numberOfCalls(on function: String) -> Int {
        recordedFunctions.reduce(0) { $0 + ($1 == function ? 1 : 0) }
    }
}

extension String {
    func wasCalled(on spy: Spy, times: Int? = nil) -> Bool {
        let function = self
        let wasCalled = spy.recordedFunctions.contains(function)

        guard wasCalled, let times = times else {
            return wasCalled
        }

        let callCount = spy.numberOfCalls(on: function)
        return callCount == times
    }

    func wasNotCalled(on spy: Spy) -> Bool {
        !wasCalled(on: spy)
    }
}

func XCTAssertCall(_ function: String, on spy: Spy, times: Int? = nil, file: StaticString = #filePath, line: UInt = #line) {
    if function.wasCalled(on: spy, times: times) {
        XCTAssertTrue(true, file: file, line: line)
        return
    }

    XCTFail("\(function) was called \(spy.numberOfCalls(on: function)) times", file: file, line: line)
}

func XCTAssertNotCall(_ function: String, on spy: Spy, file: StaticString = #filePath, line: UInt = #line) {
    if function.wasNotCalled(on: spy) {
        XCTAssertTrue(true, file: file, line: line)
        return
    }

    XCTFail("\(function) was called \(spy.numberOfCalls(on: function)) times", file: file, line: line)
}
