//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public final class MockFunc<In, Out> {
    public var calls: [In] = []
    public var result: (In) -> Out = { _ in fatalError() }

    public init() {}

    public init(result: @escaping (In) -> Out) {
        self.result = result
    }

    public var count: Int {
        calls.count
    }

    public var called: Bool {
        !calls.isEmpty
    }

    public static func mock(for: (In) throws -> Out) -> MockFunc {
        MockFunc()
    }

    public func call(with input: In) {
        calls.append(input)
    }
    
    public var input: In {
        calls[count - 1]
    }
    
    public var output: Out {
        result(input)
    }

    public func callAndReturn(_ input: In) -> Out {
        call(with: input)
        return output
    }
}

extension MockFunc {
    public func returns(_ value: Out) {
        result = { _ in value }
    }

    public func succeeds<T, Error>(_ value: T)
        where Out == Result<T, Error> {
        result = { _ in .success(value) }
    }

    public func fails<T, Error>(_ error: Error)
        where Out == Result<T, Error> {
        result = { _ in .failure(error) }
    }
}
