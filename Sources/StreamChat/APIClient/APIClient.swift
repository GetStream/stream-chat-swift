//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object allowing making request to Stream Chat servers.
class APIClient {
    /// The URL session used for all requests.
    var session: URLSession
    
    /// `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    let encoder: RequestEncoder
    
    /// `APIClient` uses this object to decode the results of network requests.
    let decoder: RequestDecoder
    
    let cdnClient: CDNClient
    
    /// Creates a new `APIClient`.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The session configuration `APIClient` uses to create its `URLSession`.
    ///   - requestEncoder: `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    ///   - requestDecoder: `APIClient` uses this object to decode the results of network requests.
    init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        CDNClient: CDNClient
    ) {
        encoder = requestEncoder
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
        cdnClient = CDNClient
    }
    
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(endpoint: Endpoint<Response>, completion: @escaping (Result<Response, Error>) -> Void) {
        encoder.encodeRequest(for: endpoint) { [weak self] (requestResult) in
            let urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error)
                completion(.failure(error))
                return
            }
            
            log.debug(
                "Making URL request: \(endpoint.method.rawValue.uppercased()) \(endpoint.path)\n"
                    + "Body:\n\(urlRequest.httpBody?.debugPrettyPrintedJSON ?? "<Empty>")\n"
                    + "Query items:\n\(urlRequest.queryItems.prettyPrinted)"
            )

            guard let self = self else {
                log.warning("Callback called while self is nil")
                return
            }
            
            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let decodedResponse: Response = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
    
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        cdnClient.uploadAttachment(
            attachment,
            progress: progress,
            completion: completion
        )
    }
}

extension URLRequest {
    var queryItems: [URLQueryItem] {
        if let url = url,
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            return queryItems
        }
        return []
    }
}

extension Array where Element == URLQueryItem {
    var prettyPrinted: String {
        var message = ""
        
        forEach { item in
            if let value = item.value,
               value.hasPrefix("{"),
               let data = value.data(using: .utf8) {
                message += "- \(item.name)=\(data.debugPrettyPrintedJSON)\n"
            } else if item.name != "api_key" && item.name != "user_id" && item.name != "client_id" {
                message += "- \(item.description)\n"
            }
        }
        
        if message.isEmpty {
            message = "<Empty>"
        }
        
        return message
    }
}
