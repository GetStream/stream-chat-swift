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
            let message = request.logMessage(for: session, status: "FAILED", error: error)
            switch (error as NSError).code {
            case NSURLErrorCancelled, NSURLErrorNetworkConnectionLost:
                log.info(message, subsystems: .httpRequests)
            default:
                log.error(message, subsystems: .httpRequests)
            }

            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.Unexpected("Expecting `HTTPURLResponse` but received: \(response?.description ?? "nil").")
        }

        let status = "\(httpResponse.statusCode)"
        guard let data = data, !data.isEmpty else {
            let message = request.logMessage(for: session, status: status)
            if httpResponse.statusCode < 300 {
                log.debug(message, subsystems: .httpRequests)
            } else {
                log.error(message, subsystems: .httpRequests)
            }
            throw ClientError.ResponseBodyEmpty()
        }

        guard httpResponse.statusCode < 300 else {
            let serverError: APIError
            do {
                serverError = try JSONDecoder.default.decode(APIError.self, from: data)
            } catch {
                log.error(request.logMessage(for: session, status: status, responseData: data, error: error), subsystems: .httpRequests)
                throw ClientError.Unknown("Unknown error. Server response: \(httpResponse).")
            }

            let message = request.logMessage(for: session, status: status, responseData: data)
            if serverError.isTokenExpiredError {
                log.info(message, subsystems: .httpRequests)
                throw ClientError.ExpiredToken()
            }

            log.error(message, subsystems: .httpRequests)
            throw ClientError(with: serverError)
        }

        log.debug(request.logMessage(for: session, status: status, responseData: data), subsystems: .httpRequests)

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
    // The `Response:` and `Request:` sections let log viewers extract the response body and the cURL command.
    func logMessage(for session: URLSession, status: String, responseData: Data? = nil, error: Error? = nil) -> String {
        var sections = ["\(status) \(httpMethod ?? "") \(url?.path ?? "")"]
        if let error {
            sections.append("Error:\n\(error)")
        }
        if let responseData, !responseData.isEmpty {
            sections.append("Response:\n\(responseData.debugPrettyPrintedJSON)")
        }
        sections.append("Request:\n\(cURLRepresentation(for: session))")
        return sections.joined(separator: "\n\n")
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
