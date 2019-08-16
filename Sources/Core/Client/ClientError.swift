//
//  ClientError.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A client error.
public enum ClientError: Error {
    /// An unexpected error.
    case unexpectedError
    /// A token is empty.
    case emptyToken
    /// The current user is empty.
    case emptyUser
    /// A client id is empty.
    case emptyClientId
    /// A connection id is empty.
    case emptyConnectionId
    /// A response bofy is empty.
    case emptyBody
    /// An invalid URL.
    case invalidURL(_ string: String?)
    /// A request failed with an error.
    case requestFailed(_ error: Error?)
    /// A response client error.
    case responseError(_ responseError: ClientErrorResponse)
    /// An encoding failed with an error.
    case encodingFailure(_ error: Error, object: Encodable)
    /// A decoding failed with an error.
    case decodingFailure(_ error: Error)
    
    /// Internal error.
    public var error: Error? {
        switch self {
        case .requestFailed(let error):
            return error
        case .responseError(let error):
            return error
        case .encodingFailure(let error, _):
            return error
        case .decodingFailure(let error):
            return error
        default:
            return nil
        }
    }
}

/// A parsed server response error.
public struct ClientErrorResponse: Error, Decodable {
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case statusCode = "StatusCode"
    }
    
    /// An error code.
    public let code: Int
    /// A message.
    public let message: String
    /// A status code.
    public let statusCode: Int
}

/// A wrapper for any Error.
public struct AnyError: Error, Equatable {
    /// Some error.
    public let error: Error
    
    public var localizedDescription: String {
        return error.localizedDescription
    }
    
    public static func == (lhs: AnyError, rhs: AnyError) -> Bool {
        return lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}
