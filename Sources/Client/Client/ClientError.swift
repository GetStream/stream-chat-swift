//
//  ClientError.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A client error.
public enum ClientError: LocalizedError, CustomDebugStringConvertible, Equatable {
    
    /// An unexpected error.
    case unexpectedError(description: String, error: Error?)
    /// The API Key is empty.
    case emptyAPIKey
    /// A token is empty.
    case emptyToken
    /// A token is invalid.
    case invalidToken(description: String)
    /// A token is expired.
    case expiredToken
    /// The current user is empty.
    case emptyUser
    /// A connection id is empty.
    case emptyConnectionId
    /// A channel id is empty.
    case emptyChannelId
    /// A message id is empty.
    case emptyMessageId
    /// A response bofy is empty.
    case emptyBody(description: String)
    /// An invalid URL.
    case invalidURL(_ string: String?)
    /// An invalid URL.
    case invalidReactionType(String)
    /// A request failed with an error.
    case requestFailed(Error?)
    /// A response client error.
    case responseError(ClientErrorResponse)
    /// A websocket disconnect error.
    case websocketDisconnectError(Swift.Error)
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
        case .unexpectedError(let description, _):
            return "Unexpected error: \(description)"
        case .emptyAPIKey:
            return "Client API Key is empty."
                + " Please use `Client.config = .init(apiKey:) before using Client to setup your api key correctly."
        case .emptyToken:
            return "A Client Token is empty"
        case .invalidToken(let description):
            return "Token is invalid: \(description)"
        case .expiredToken:
            return "The token was expired"
        case .emptyUser:
            return "The current Client user is empty"
        case .emptyConnectionId:
            return "Web Socket connection id is empty. Authorization missed. Please call set(user:) and wait for its completion."
        case .emptyChannelId:
            return "A channel id is empty"
        case .emptyMessageId:
            return "A message id is empty"
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
        case .websocketDisconnectError(let error):
            return error.localizedDescription
        case .encodingFailure(let error, _):
            return "An encoding failed: \(error.localizedDescription)"
        case .decodingFailure(let error):
            return "A decoding failed: \(error.localizedDescription)"
        case .errorMessage(let message):
            return message.text
        case .emptyDeviceToken:
            return "A device token is empty"
            
        case .channelsSearchQueryEmpty:
            return "A channels search query is empty"
        case .channelsSearchFilterEmpty:
            return "Filter can't be an empty for the message search"
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
        case .expiredToken:
            return "ClientError.expiredToken"
        case .invalidToken(let description):
            return "ClientError.tokenInvalid(\(description))"
        case .emptyUser:
            return "ClientError.emptyUser"
        case .emptyConnectionId:
            return "ClientError.emptyConnectionId"
        case .emptyChannelId:
            return "ClientError.emptyChannelId"
        case .emptyMessageId:
            return "ClientError.emptyMessageId"
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
        case .websocketDisconnectError(let error):
            return "ClientError.websocketDisconnectError(\(error)"
        case .encodingFailure(let error, let object):
            return "ClientError.encodingFailure(\(error), \(object))"
        case .decodingFailure(let error):
            return "ClientError.decodingFailure(\(error))"
        case .errorMessage(let message):
            return "ClientError.errorMessage(\(message.text))"
        case .emptyDeviceToken:
            return "ClientError.emptyDeviceToken"
        case .channelsSearchQueryEmpty:
            return "ClientError.channelsSearchQueryEmpty"
        case .channelsSearchFilterEmpty:
            return "ClientError.channelsSearchFilterEmpty"
        }
    }
    
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        lhs.debugDescription == rhs.debugDescription
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
    
    public init(_ error: Error) {
        self.error = error
    }
    
    public var localizedDescription: String {
        return error.localizedDescription
    }
    
    public var debugDescription: String {
        return "AnyError(error: \(error))"
    }
    
    public static func == (lhs: AnyError, rhs: AnyError) -> Bool {
        lhs.error.localizedDescription == rhs.error.localizedDescription
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
