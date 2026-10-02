//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object responsible for handling incoming URL request response and decoding it.
protocol RequestDecoder: Sendable {
    /// Decodes an incoming URL request response.
    ///
    /// - Parameters:
    ///   - request: The request that produced the response.
    ///   - session: The session that performed the request.
    ///   - data: The incoming data.
    ///   - response: The response object from the network.
    ///   - error: An error object returned by the data task.
    ///
    /// - Throws: An error if the decoding fails.
    func decodeRequestResponse<ResponseType: Decodable>(
        request: URLRequest,
        session: URLSession,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType
}

/// The default implementation of `RequestDecoder`.
struct DefaultRequestDecoder: RequestDecoder {
    func decodeRequestResponse<ResponseType: Decodable>(
        request: URLRequest,
        session: URLSession,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType {
        // Handle the error case
        guard error == nil else {
            let error = error!
            let message = request.logMessage(status: "FAILED")
            let metadata = { [LogMetadataKey: String].http(request: request, error: error, session: session) }
            switch (error as NSError).code {
            case NSURLErrorCancelled, NSURLErrorNetworkConnectionLost:
                log.info(message, subsystems: .httpRequests, metadata: metadata())
            default:
                log.error(message, subsystems: .httpRequests, metadata: metadata())
            }

            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.Unexpected("Expecting `HTTPURLResponse` but received: \(response?.description ?? "nil").")
        }

        let statusCode = httpResponse.statusCode
        let message = request.logMessage(status: "\(statusCode)")
        guard let data = data, !data.isEmpty else {
            let metadata = { [LogMetadataKey: String].http(request: request, response: httpResponse, session: session) }
            if statusCode < 300 {
                log.debug(message, subsystems: .httpRequests, metadata: metadata())
            } else {
                log.error(message, subsystems: .httpRequests, metadata: metadata())
            }
            throw ClientError.ResponseBodyEmpty()
        }

        let metadata = {
            [LogMetadataKey: String].http(request: request, response: httpResponse, responseBody: data, session: session)
        }
        guard statusCode < 300 else {
            let serverError: APIError
            do {
                serverError = try JSONDecoder.default.decode(APIError.self, from: data)
            } catch {
                log.error(
                    message,
                    subsystems: .httpRequests,
                    metadata: .http(request: request, response: httpResponse, responseBody: data, error: error, session: session)
                )
                throw ClientError.Unknown("Unknown error. Server response: \(httpResponse).")
            }

            if serverError.isTokenExpiredError {
                log.info(message, subsystems: .httpRequests, metadata: metadata())
                throw ClientError.ExpiredToken()
            }

            log.error(message, subsystems: .httpRequests, metadata: metadata())
            throw ClientError(with: serverError)
        }

        log.debug(message, subsystems: .httpRequests, metadata: metadata())

        if let responseAsData = data as? ResponseType {
            return responseAsData
        }

        do {
            let decodedPayload = try JSONDecoder.default.decode(ResponseType.self, from: data)
            return decodedPayload
        } catch {
            log.error(error, subsystems: .httpRequests)
            throw error
        }
    }
}

extension URLRequest {
    func logMessage(status: String) -> String {
        "\(status) \(httpMethod ?? "GET") \(url?.path ?? "")"
    }
}

extension ClientError {
    final class ExpiredToken: ClientError, @unchecked Sendable {}
    final class RefreshingToken: ClientError, @unchecked Sendable {}
    final class TokenRefreshed: ClientError, @unchecked Sendable {}
    final class ConnectionError: ClientError, @unchecked Sendable {}
    final class ResponseBodyEmpty: ClientError, @unchecked Sendable {
        override var localizedDescription: String { "Response body is empty." }
    }

    static let temporaryErrors: Set<Int> = [
        NSURLErrorCancelled,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorBadServerResponse,
        NSURLErrorUserCancelledAuthentication,
        NSURLErrorCannotLoadFromNetwork,
        NSURLErrorDataNotAllowed
    ]

    // returns true if the error is related to a temporary condition
    // you can use this to check if it makes sense to retry an API call
    static func isEphemeral(error: Error) -> Bool {
        if temporaryErrors.contains((error as NSError).code) {
            return true
        }

        return false
    }
}
