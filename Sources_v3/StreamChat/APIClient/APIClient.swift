//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    
    /// Creates a new `APIClient`.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The session configuration `APIClient` uses to create its `URLSession`.
    ///   - requestEncoder: `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    ///   - requestDecoder: `APIClient` uses this object to decode the results of network requests.
    init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder
    ) {
        encoder = requestEncoder
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
    }
    
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(endpoint: Endpoint<Response>, completion: @escaping (Result<Response, Error>) -> Void) {
        encoder.encodeRequest(for: endpoint) { [unowned self] (requestResult) in
            let urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error)
                completion(.failure(error))
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
}
