//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

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
}

extension String {
    func wasCalled(on spy: Spy, times: Int? = nil) -> Bool {
        let function = self
        let wasCalled = spy.recordedFunctions.contains(function)

        guard wasCalled, let times = times else {
            return wasCalled
        }

        let callCount = spy.recordedFunctions.reduce(0) { $0 + ($1 == function ? 1 : 0) }
        return callCount == times
    }

    func wasNotCalled(on spy: Spy, times: Int? = nil) -> Bool {
        !wasCalled(on: spy, times: times)
    }
}
