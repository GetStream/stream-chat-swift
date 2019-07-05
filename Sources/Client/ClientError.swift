//
//  ClientError.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A client error.
public enum ClientError: Error {
    case unexpectedError
    case emptyToken
    case emptyUser
    case emptyClientId
    case emptyConnectionId
    case emptyBody
    case invalidURL(_ string: String?)
    case requestFailed(_ error: Error?)
    case responseError(_ responseError: ClientErrorResponse)
    case encodingFailure(_ error: Error, object: Encodable)
    case decodingFailure(_ error: Error)
}

/// A parsed server response error.
public struct ClientErrorResponse: Decodable {
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
