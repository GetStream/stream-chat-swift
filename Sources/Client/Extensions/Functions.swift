//
//  Functions.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 21/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// A did update block type.
public typealias OnUpdate<T> = (T) -> Void

/// A completion block type with a `Result`.
public typealias ResultCompletion<T, E: Error> = (Result<T, E>) -> Void

// MARK: Side Effects

/// Performs side effect work for a success result before of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doBefore: a side effect will be executed before the original completion block.
public func doBefore<T, E: Error>(_ completion: @escaping ResultCompletion<T, E>,
                                  _ doBefore: @escaping (T) -> Void) -> ResultCompletion<T, E> {
    `do`(for: completion, doBefore: doBefore)
}

/// Performs side effect work for a success result after of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doAfter: a side effect will be executed after the original completion block.
public func doAfter<T, E: Error>(_ completion: @escaping ResultCompletion<T, E>,
                                 _ doAfter: @escaping (T) -> Void) -> ResultCompletion<T, E> {
    `do`(for: completion, doAfter: doAfter)
}

/// Performs side effect work for a success result before and after of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - doBefore: a side effect will be executed before the original completion block.
///   - doAfter: a side effect will be executed after the original completion block.
public func `do`<T, E: Error>(for completion: @escaping ResultCompletion<T, E>,
                              doBefore: @escaping (T) -> Void = { _ in },
                              doAfter: @escaping (T) -> Void = { _ in }) -> ResultCompletion<T, E> {
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

/// Performs side effect work for a failure result before of the original completion block.
/// - Parameters:
///   - completion: an original completion block.
///   - onError: a side effect with an error will be executed before the original completion block.
public func onError<T, E: Error>(_ completion: @escaping ResultCompletion<T, E>,
                                 _ onError: @escaping (E) -> Void) -> ResultCompletion<T, E> {
    return { result in
        if let error = result.error {
            onError(error)
        }
        
        completion(result)
    }
}
