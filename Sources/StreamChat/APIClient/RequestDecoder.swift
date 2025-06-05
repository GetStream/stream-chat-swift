//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object responsible for handling incoming URL request response and decoding it.
protocol RequestDecoder {
    /// Decodes an incoming URL request response.
    ///
    /// - Parameters:
    ///   - request: The URL request that was sent.
    ///   - data: The incoming data.
    ///   - response: The response object from the network.
    ///   - error: An error object returned by the data task.
    ///
    /// - Throws: An error if the decoding fails.
    func decodeRequestResponse<ResponseType: Decodable>(
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType
}

/// The default implementation of `RequestDecoder`.
struct DefaultRequestDecoder: RequestDecoder {
    func decodeRequestResponse<ResponseType: Decodable>(
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType {
        // Handle the error case
        guard error == nil else {
            let error = error!
            switch (error as NSError).code {
            case NSURLErrorCancelled:
                log.info("The request was cancelled.", subsystems: .httpRequests)
            case NSURLErrorNetworkConnectionLost:
                log.info("The network connection was lost.", subsystems: .httpRequests)
            default:
                log.error(error, subsystems: .httpRequests)
            }

            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.Unexpected("Expecting `HTTPURLResponse` but received: \(response?.description ?? "nil").")
        }

        guard let data = data, !data.isEmpty else {
            throw ClientError.ResponseBodyEmpty()
        }

        log.debug(
            """
            \(httpResponse.statusCode) \(request.url?.pathComponentsString ?? "unknown path")
            \(data.debugPrettyPrintedJSON))

            \(request.toCurlString())
            """,
            subsystems: .httpRequests
        )

        guard httpResponse.statusCode < 300 else {
            let serverError: ErrorPayload
            do {
                serverError = try JSONDecoder.default.decode(ErrorPayload.self, from: data)
            } catch {
                log
                    .error(
                        "Failed to decode API request error with status code: \(httpResponse.statusCode), \nerror:\n\(error) \nresponse:\n\(data.debugPrettyPrintedJSON))",
                        subsystems: .httpRequests
                    )
                throw ClientError.Unknown("Unknown error. Server response: \(httpResponse).")
            }

            if serverError.isExpiredTokenError {
                log.info("Request failed because of an expired token.", subsystems: .httpRequests)
                throw ClientError.ExpiredToken()
            }

            log
                .error(
                    "API request failed with status code: \(httpResponse.statusCode), code: \(serverError.code) response:\n\(data.debugPrettyPrintedJSON))",
                    subsystems: .httpRequests
                )
            throw ClientError(with: serverError)
        }

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

extension ClientError {
    final class ExpiredToken: ClientError {}
    final class RefreshingToken: ClientError {}
    final class TokenRefreshed: ClientError {}
    final class ConnectionError: ClientError {}
    final class ResponseBodyEmpty: ClientError {
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

extension URLRequest {
    /// Converts the URLRequest to a cURL command string
    /// - Returns: A cURL command string representation of the request
    func toCurlString() -> String {
        guard let url = self.url else {
            return "curl # Invalid URL"
        }

        var components = ["curl"]

        // Add URL (with proper escaping)
        let escapedUrl = "'\(url.absoluteString)'"
        components.append(escapedUrl)

        // Add HTTP method if not GET
        if let httpMethod = self.httpMethod, httpMethod != "GET" {
            components.append("-X \(httpMethod)")
        }

        // Add headers
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                let escapedHeader = "'\(key): \(value)'"
                components.append("-H \(escapedHeader)")
            }
            components.append("-H 'Content-Type: application/json'")
        }

        // Add body data
        if let httpBody = self.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\"'\"'")
            components.append("--data-raw '\(escapedBody)'")
        }

        return components.joined(separator: " \\\n  ")
    }
}

extension URL {
    /// Returns the path components joined with "/"
    /// - Returns: Path string without leading slash (e.g., "api/v1/users/123")
    var pathComponentsString: String {
        pathComponents.dropFirst().joined(separator: "/")
    }
}
