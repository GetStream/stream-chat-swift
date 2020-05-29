//
// APIClient.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

class APIClient {
  let session: URLSession
  let baseURL: URL
  let apiKey: String

  // Must be weak??
  weak var connectionIdProvider: ConnectionIdProvider?

  init(apiKey: String, baseURL: URL, sessionConfiguration: URLSessionConfiguration) {
    self.apiKey = apiKey
    self.baseURL = baseURL
    self.session = URLSession(configuration: sessionConfiguration)
  }
}

protocol ConnectionIdProvider: AnyObject {
  func requestConnectionId(completion: @escaping (_ connectionId: String?) -> Void)
}

extension APIClient {
  // MARK: - Request

  /// Send a request.
  ///
  /// - Parameters:
  ///   - endpoint: an endpoint (see `Endpoint`).
  ///   - completion: a completion block.
  /// - Returns: an URLSessionTask that can be canncelled.
  func request<T: Decodable>(endpoint: Endpoint, _ completion: @escaping (Result<T, Error>) -> Void) {
    queryItems(for: endpoint) { queryItemsResult in
      guard case .success(let queryItems) = queryItemsResult else { fatalError() }
      do {
        let url = try self.requestURL(for: endpoint, queryItems: queryItems).get()
        let urlRequest = try self.encodeRequest(for: endpoint, url: url).get()

        let task = self.session.dataTask(with: urlRequest) { data, _, error in
          if let error = error {
            completion(.failure(error))
            return
          }

          do {
            let decoded = try JSONDecoder.default.decode(T.self, from: data!)
            completion(.success(decoded))
          } catch {
            completion(.failure(error))
          }
        }

        task.resume()

      } catch {
        fatalError()
      }
    }
  }

  private func requestURL(for endpoint: Endpoint, queryItems: [URLQueryItem]) -> Result<URL, Error> {
    var urlComponents = URLComponents()
    urlComponents.scheme = baseURL.scheme
    urlComponents.host = baseURL.host
    urlComponents.path = baseURL.path
    urlComponents.queryItems = queryItems

    guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
      fatalError()
//           return .failure(.invalidURL("For \(urlComponents) with appending path \(endpoint.path)"))
    }

    return .success(url)
  }

  private func queryItems(for endpoint: Endpoint, completion: @escaping (Result<[URLQueryItem], Error>) -> Void) {
    if apiKey.isEmpty {
      fatalError()
//           return .failure(.emptyAPIKey)
    }

    var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]

    queryItems.append(contentsOf: endpoint.queryItems)

    if let endpointQueryItems = endpoint.jsonQueryItems {
      endpointQueryItems.forEach { (key: String, value: Encodable) in
        do {
          let data = try JSONEncoder.default.encode(AnyEncodable(value))

          if let json = String(data: data, encoding: .utf8) {
            queryItems.append(URLQueryItem(name: key, value: json))
          }
        } catch {
          fatalError()
//                   logger?.log(error, message: "Encode jsonQueryItems")
        }
      }
    }

//       if let endpointQueryItem = endpoint.queryItem {
//           if let data = try? JSONEncoder.default.encode(AnyEncodable(endpointQueryItem)),
//               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//               json.forEach { key, value in
//                   if let stringValue = value as? String {
//                       queryItems.append(URLQueryItem(name: key, value: stringValue))
//                   } else if let intValue = value as? Int {
//                       queryItems.append(URLQueryItem(name: key, value: String(intValue)))
//                   } else if let floatValue = value as? Float {
//                       queryItems.append(URLQueryItem(name: key, value: String(floatValue)))
//                   } else if let doubleValue = value as? Double {
//                       queryItems.append(URLQueryItem(name: key, value: String(doubleValue)))
//                   } else if let value = value as? CustomStringConvertible {
//                       queryItems.append(URLQueryItem(name: key, value: value.description))
//                   }
//               }
//           }
//       }

    //       if let connectionId = webSocket.connectionId {
    //           queryItems.append(URLQueryItem(name: "connection_id", value: connectionId))
    //       } else if endpoint.requiresConnectionId {
    //           return .failure(.emptyConnectionId)
    //       }

    connectionIdProvider?.requestConnectionId(completion: { connectionId in
      if let connectionId = connectionId {
        queryItems.append(URLQueryItem(name: "connection_id", value: connectionId))
        completion(.success(queryItems))
      } else {
        fatalError()
      }
    })
  }

  private func encodeRequest(for endpoint: Endpoint, url: URL) -> Result<URLRequest, Error> {
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = endpoint.method.rawValue
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

    if let body = endpoint.body {
      let encodable = AnyEncodable(body)

      do {
        if let httpBody = try? JSONEncoder.defaultGzip.encode(encodable) {
          urlRequest.httpBody = httpBody
          urlRequest.addValue("gzip", forHTTPHeaderField: "Content-Encoding")
        } else {
          urlRequest.httpBody = try JSONEncoder.default.encode(encodable)
        }
      } catch {
        fatalError()
//               return .failure(.encodingFailure(error, object: body))
      }
    }

    return .success(urlRequest)
  }
}
