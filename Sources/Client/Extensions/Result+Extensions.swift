//
//  Result+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Result {
    /// Get the error from the result if it failed.
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

public extension Result where Failure == ClientError, Success: Decodable {
    /// Map the result to a client completion result type.
    /// - Parameters:
    ///   - completion: a client completion block.
    func map<T: Decodable>(_ map: (Success) -> T) -> Result<T, ClientError> {
        if let value = try? get() {
            return .success(map(value))
        }
        
        return .failure(error ?? .unexpectedError(nil, error))
    }
}
