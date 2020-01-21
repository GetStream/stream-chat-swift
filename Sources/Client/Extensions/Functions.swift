//
//  Functions.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 21/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

// MARK: Side Effects

/// A completion block type with a `Result`.
public typealias Completion<T, E: Error> = (Result<T, E>) -> Void

/// Performs side effect work for a success result before of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doBefore: a side effect will be executed before the original completion block.
public func doBefore<T, E: Error>(_ completion: @escaping Completion<T, E>, _ doBefore: @escaping (T) -> Void) -> Completion<T, E> {
    return addSideEffect(for: completion, doBefore: doBefore)
}

/// Performs side effect work for a success result after of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doAfter: a side effect will be executed after the original completion block.
public func doAfter<T, E: Error>(_ completion: @escaping Completion<T, E>, _ doAfter: @escaping (T) -> Void) -> Completion<T, E> {
    return addSideEffect(for: completion, doAfter: doAfter)
}

/// Performs side effect work for a success result before and after of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doBefore: a side effect will be executed before the original completion block.
///   - doAfter: a side effect will be executed after the original completion block.
public func addSideEffect<T, E: Error>(for completion: @escaping Completion<T, E>,
                                 doBefore: @escaping (T) -> Void = { _ in },
                                 doAfter: @escaping (T) -> Void = { _ in }) -> Completion<T, E> {
    return { result in
        guard let value = try? result.get() else {
            completion(result)
            return
        }
        
        doBefore(value)
        completion(result)
        doAfter(value)
    }
}
