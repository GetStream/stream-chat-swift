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
    /// - Parameters:
    ///   - completion: a client completion block.
    func map<T: Decodable>(_ map: (Success) -> T) -> Result<T, ClientError> {
        if let value = try? get() {
            return .success(map(value))
        }
        
        return .failure(error ?? .unexpectedError(nil, error))
    }
    
    /// Catches an error in the result and send it to the error handler to map it to a success result.
    /// - Parameter errorHandler: an error handler.
    func catchError(_ errorHandler: (Failure) -> Result<Success, ClientError>) -> Result<Success, ClientError> {
        if let error = error {
            return errorHandler(error)
        }
        
        return self
    }
}

public extension Result where Success: Collection, Failure == ClientError {
    /// Map values from the result to the first value. If array is empty, will map to an error.
    /// - Parameter notFoundError: a not forund client error.
    func first(orError notFoundError: ClientError) -> Result<Success.Element, ClientError> {
        if let values = try? get() {
            if let first = values.first {
                return .success(first)
            }
            
            return .failure(notFoundError)
        }
        
        return .failure(error ?? .unexpectedError(nil, error))
    }
}
