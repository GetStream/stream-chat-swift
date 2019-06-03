//
//  ClientError.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

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

public struct ClientErrorResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case statusCode = "StatusCode"
    }
    
    public let code: Int
    public let message: String
    public let statusCode: Int
}
