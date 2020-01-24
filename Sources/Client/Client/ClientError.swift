//
//  ClientError.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A client error.
public enum ClientError: LocalizedError {
    /// An unexpected error.
    case unexpectedError(String?, Error?)
    /// The API Key is empty.
    case emptyAPIKey
    /// A token is empty.
    case emptyToken
    /// A token is invalid.
    case tokenInvalid(description: String)
    /// The current user is empty.
    case emptyUser
    /// A connection id is empty.
    case emptyConnectionId
    /// A channel id is empty.
    case emptyChannelId
    /// A response bofy is empty.
    case emptyBody(description: String)
    /// An invalid URL.
    case invalidURL(_ string: String?)
    /// A request failed with an error.
    case requestFailed(Error?)
    /// A response client error.
    case responseError(ClientErrorResponse)
    /// An encoding failed with an error.
    case encodingFailure(Error, object: Encodable)
    /// A decoding failed with an error.
    case decodingFailure(Error)
    /// A message with the error type.
    case errorMessage(Message)
    /// A device token is empty.
    case emptyDeviceToken
    
    case channelsSearchQueryEmpty
    case channelsSearchFilterEmpty
    
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
    
    public var errorDescription: String? {
        switch self {
        case let .unexpectedError(description, error):
            let errorDescription: String
            
            if let description = description {
                errorDescription = "Unexpected error: \(description)"
            } else if let error = error {
                errorDescription = "Unexpected error: \(error)"
            } else {
                errorDescription = "Unexpected error"
            }
            
            return errorDescription
            
        case .emptyAPIKey: return "The Client API Key is empty"
        case .emptyToken: return "A Client Token is empty"
        case .tokenInvalid(let description): return "Token is invalid: \(description)"
        case .emptyUser: return "The user is empty"
        case .emptyConnectionId: return "A Web Socket connection id is empty. Authorization missed"
        case .emptyChannelId: return "A channel id is empty. Probably the channel is a direct message channel without id."
        case .emptyBody(let description): return "A request or response body data is empty: \(description)"
        case .invalidURL(let url): return "An invalid URL: \(url ?? "<unknown>")"
            
        case .requestFailed(let error):
            if let error = error {
                return "A request failed: \(error)"
            }
            
            return "A request failed with unknown error"
            
        case .responseError(let error): return "A response failed: \(error)"
        case .encodingFailure(let error, let object): return "A encoding failed: \(error) for object: \(object)"
        case .decodingFailure(let error): return "A decoding failed: \(error)"
        case .errorMessage(let message): return message.text
        case .emptyDeviceToken: return "A device token is empty"
            
        case .channelsSearchQueryEmpty: return "A channels search query is empty"
        case .channelsSearchFilterEmpty: return "Filter can't be an empty for the message search"
        }
    }
}

/// A parsed server response error.
public struct ClientErrorResponse: LocalizedError, Decodable {
    static let tokenExpiredErrorCode = 40
    
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
    
    public var errorDescription: String? {
        return "Client JSON Error \(code): \(message) (Status code: \(statusCode))."
    }
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

/// An encoding error
public enum EncodingError: Error {
    /// Field with this value can't be encoded
    case valueUnsupported
}
