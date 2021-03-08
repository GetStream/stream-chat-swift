//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object responsible for handling incoming URL request response and decoding it.
protocol RequestDecoder {
    /// Decodes an incoming URL request response.
    ///
    /// - Parameters:
    ///   - data: The incoming data.
    ///   - response: The response object from the network.
    ///   - error: An error object returned by the data task.
    ///
    /// - Throws: An error if the decoding fails.
    func decodeRequestResponse<ResponseType: Decodable>(data: Data?, response: URLResponse?, error: Error?) throws -> ResponseType
}

/// The default implementation of `RequestDecoder`.
struct DefaultRequestDecoder: RequestDecoder {
    func decodeRequestResponse<ResponseType: Decodable>(data: Data?, response: URLResponse?, error: Error?) throws -> ResponseType {
        // Handle the error case
        guard error == nil else {
            let error = error!
            switch (error as NSError).code {
            case NSURLErrorCancelled:
                log.info("The request was cancelled.")
            case NSURLErrorNetworkConnectionLost:
                log.info("The network connection was lost.")
            default:
                log.error(error)
            }
            
            throw error
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.Unexpected("Expecting `HTTPURLResponse` but received: \(response?.description ?? "nil").")
        }
        
        guard let data = data, data.isEmpty == false else {
            throw ClientError.ResponseBodyEmpty()
        }
        
        log.debug("URL request response: \(httpResponse), data:\n\(data.debugPrettyPrintedJSON))")
        
        guard httpResponse.statusCode < 400 else {
            guard let serverError = try? JSONDecoder.default.decode(ErrorPayload.self, from: data) else {
                throw ClientError.Unknown("Unknown error. Server response: \(httpResponse).")
            }
            
            // TODO: 👇
//                if errorResponse.message.contains("was deactivated") {
//                    webSocket.disconnect(reason: "JSON response error: the client was deactivated")
//                }
            
            if ErrorPayload.tokenInvadlidErrorCodes ~= serverError.code {
                log.info("Request failed because of an experied token.")
                throw ClientError.ExpiredToken()
            }
            
            throw ClientError(with: serverError)
        }
        
        do {
            let decodedPayload = try JSONDecoder.default.decode(ResponseType.self, from: data)
            return decodedPayload
            
        } catch {
            log.error(error)
            throw error
        }
    }
}

extension ClientError {
    class ExpiredToken: ClientError {}
    class ResponseBodyEmpty: ClientError {
        override var localizedDescription: String { "Response body is empty." }
    }
}
