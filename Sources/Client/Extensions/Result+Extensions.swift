//
//  Result+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Result {
    
    /// Get a value from the result.
    var value: Success? {
        if case .success(let successValue) = self {
            return successValue
        }
        
        return nil
    }
    
    /// Get an error from the result if it failed.
    var error: Failure? {
        if case .failure(let error) = self {
            return error
        }
        
        return nil
    }
    
    /// Returns true if the result was success.
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        
        return false
    }
}

public extension Result where Success: Decodable, Failure == ClientError {
    
    /// Map the result to a client completion result type.
    /// - Parameter keyPath: a key path to the success type for mapping.
    func map<T: Decodable>(to keyPath: KeyPath<Success, T>) -> Result<T, Failure> {
        map { $0[keyPath: keyPath] }
    }
    
    /// Map the result to a client completion result type.
    /// - Parameter completion: a client completion block.
    func map<T: Decodable>(_ map: (Success) -> T) -> Result<T, Failure> {
        if let value = try? get() {
            return .success(map(value))
        }
        
        return .failure(error ?? .unexpectedError(description: error?.localizedDescription ?? #function,
                                                  error: error))
    }
    
    /// Catches an error in the result and send it to the error handler to map it to a success result.
    /// - Parameter errorHandler: an error handler.
    func catchError(_ errorHandler: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        if let error = error {
            return errorHandler(error)
        }
        
        return self
    }
}

public extension Result where Success: Collection, Failure == ClientError {
    
    /// Map values from the result to the first value. If array is empty, will map to an error.
    /// - Parameter notFoundError: a not forund client error.
    func first(orError notFoundError: Failure) -> Result<Success.Element, Failure> {
        if let values = try? get() {
            if let first = values.first {
                return .success(first)
            }
            
            return .failure(notFoundError)
        }
        
        return .failure(error
            ?? .unexpectedError(description: error?.localizedDescription ?? #function, error: error))
    }
    
    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    /// - Parameter keyPath: a key path to the success collection type for compact mapping.
    func compactMap<T>(to keyPath: KeyPath<Success.Element, T>) -> Result<[T], Failure> {
        compactMap { $0[keyPath: keyPath] }
    }
    
    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    /// - Parameter transform: A closure that accepts an element of this sequence as its argument and returns an optional value.
    func compactMap<T>(_ transform: (Success.Element) throws -> T?) -> Result<[T], Failure> {
        if let values = try? get() {
            return .success((try? values.compactMap(transform)) ?? [])
        }
        
        return .failure(error ?? .unexpectedError(description: error?.localizedDescription ?? #function,
                                                  error: error))
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    func forEach(_ body: (Success.Element) throws -> Void) rethrows {
        if let values = self.value {
            try values.forEach(body)
        }
    }
}
