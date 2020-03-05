//
//  ClientError.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A client error.
public enum ClientError: LocalizedError, CustomDebugStringConvertible {
    /// An unexpected error.
    case unexpectedError(description: String, error: Error?)
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
    /// A response bofy is empty.
    case emptyBody(description: String)
    /// An invalid URL.
    case invalidURL(_ string: String?)
    /// An invalid URL.
    case invalidReactionType(String)
    /// A request failed with an error.
    case requestFailed(_ error: Error?)
    /// A response client error.
    case responseError(_ responseError: ClientErrorResponse)
    /// An encoding failed with an error.
    case encodingFailure(_ error: Error, object: Encodable)
    /// A decoding failed with an error.
    case decodingFailure(_ error: Error)
    /// A message with the error type.
    case errorMessage(Message)
    
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
        case .unexpectedError(let description, _):
            return "Unexpected error: \(description)"
        case .emptyAPIKey:
            return "The Client API Key is empty"
        case .emptyToken:
            return "A Client Token is empty"
        case .tokenInvalid(let description):
            return "Token is invalid: \(description)"
        case .emptyUser:
            return "The current Client user is empty"
        case .emptyConnectionId:
            return "A Web Socket connection id is empty. Authorization missed"
        case .emptyBody(let description):
            return "A request or response body data is empty: \(description)"
        case .invalidURL(let url):
            return "An invalid URL: \(url ?? "<unknown>")"
        case .invalidReactionType(let type):
            return "An invalid ReactionType: \(type)"
            
        case .requestFailed(let error):
            if let error = error {
                return "A request failed: \(error.localizedDescription)"
            }
            
            return "A request failed with unknown error"
            
        case .responseError(let error):
            return error.localizedDescription
        case .encodingFailure(let error, _):
            return "An encoding failed: \(error.localizedDescription)"
        case .decodingFailure(let error):
            return "A decoding failed: \(error.localizedDescription)"
        case .errorMessage(let message):
            return message.text
        }
    }

    public var debugDescription: String {
        switch self {
        case .unexpectedError(let description, let error):
            return "ClientError.unexpectedError(description: \(description), error: \(String(describing: error)))"
        case .emptyAPIKey:
            return "ClientError.emptyAPIKey"
        case .emptyToken:
            return "ClientError.emptyToken"
        case .tokenInvalid(let description):
            return "ClientError.tokenInvalid(\(description))"
        case .emptyUser:
            return "ClientError.emptyUser"
        case .emptyConnectionId:
            return "ClientError.emptyConnectionId"
        case .emptyBody(let description):
            return "ClientError.emptyBody(\(description))"
        case .invalidURL(let url):
            return "ClientError.invalidURL(\(url ?? "<unknown>"))"
        case .invalidReactionType(let type):
            return "ClientError.invalidReactionType(\(type))"
        case .requestFailed(let error):
            return "ClientError.requestFailed(\(String(describing: error)))"
        case .responseError(let error):
            return "ClientError.responseError(\(error))"
        case .encodingFailure(let error, let object):
            return "ClientError.encodingFailure(\(error), \(object))"
        case .decodingFailure(let error):
            return "ClientError.decodingFailure(\(error))"
        case .errorMessage(let message):
            return "ClientError.errorMessage(\(message.text))"
        }
    }
}

/// A parsed server response error.
public struct ClientErrorResponse: LocalizedError, Decodable, CustomDebugStringConvertible {
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
        return "Error #\(code): \(message)"
    }

    public var debugDescription: String {
        return "ClientErrorResponse(code: \(code), message: \"\(message)\", statusCode: \(statusCode)))."
    }
}

/// A wrapper for any Error.
public struct AnyError: Error, Equatable, CustomDebugStringConvertible {
    /// Some error.
    public let error: Error
    
    public var localizedDescription: String {
        return error.localizedDescription
    }
    
    public var debugDescription: String {
        return "AnyError(error: \(error))"
    }

    public static func == (lhs: AnyError, rhs: AnyError) -> Bool {
        return lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}

/// An encoding error
public enum EncodingError: Error, LocalizedError, CustomDebugStringConvertible {
    /// Attachment's type not supported
    case attachmentUnsupported

    public var errorDescription: String? {
        switch self {
        case .attachmentUnsupported:
            return "This attachment type is not supported"
        }
    }

    public var debugDescription: String {
        switch self {
        case .attachmentUnsupported:
            return "EncodingError.attachmentUnsupported"
        }
    }
}
