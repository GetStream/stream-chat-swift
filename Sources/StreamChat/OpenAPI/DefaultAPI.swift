//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"

    init(stringValue: String) {
        guard let method = HTTPMethod(rawValue: stringValue.uppercased()) else {
            self = .get
            return
        }
        self = method
    }
}

internal struct Request {
    var url: URL
    var method: HTTPMethod
    var body: Data?
    var queryParams: [URLQueryItem] = []
    var headers: [String: String] = [:]

    func urlRequest() throws -> URLRequest {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var existingQueryItems = urlComponents.queryItems ?? []
        existingQueryItems.append(contentsOf: queryParams)
        urlComponents.queryItems = existingQueryItems
        var urlRequest = URLRequest(url: urlComponents.url!)
        headers.forEach { (k, v) in
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        return urlRequest
    }
}
