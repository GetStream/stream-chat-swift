//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserAuth: @unchecked Sendable, DefaultAPIClientMiddleware {
    var tokenProvider: () -> String
    var connectionId: () async throws -> String

    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        let connectionId = try await connectionId()
        if !connectionId.isEmpty {
            modifiedRequest.queryParams.append(
                .init(name: "connection_id", value: connectionId)
            )
        }
        modifiedRequest.headers["Authorization"] = tokenProvider()
        modifiedRequest.headers["stream-auth-type"] = "jwt"
        return try await next(modifiedRequest)
    }
}

struct AnonymousAuth: DefaultAPIClientMiddleware {
    var token: String
    
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        if !token.isEmpty {
            modifiedRequest.headers["Authorization"] = token
        }
        modifiedRequest.headers["stream-auth-type"] = "anonymous"
        return try await next(modifiedRequest)
    }
}

struct DefaultParams: DefaultAPIClientMiddleware {
    let apiKey: String
    
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        modifiedRequest.queryParams.append(.init(name: "api_key", value: apiKey))
        modifiedRequest.headers["X-Stream-Client"] = SystemEnvironment.xStreamClientHeader
        modifiedRequest.headers["x-client-request-id"] = UUID().uuidString
        return try await next(modifiedRequest)
    }
}
