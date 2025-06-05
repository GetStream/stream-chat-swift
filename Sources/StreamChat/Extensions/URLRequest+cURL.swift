//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension URLRequest {
    /// Gives cURL representation of the request for an easy API request reproducibility in Terminal.
    /// - Parameter urlSession: The URLSession handling the request.
    /// - Returns: cURL representation of the URLRequest.
    func cURLRepresentation(for urlSession: URLSession?) -> String {
        guard let url, let httpMethod else { return "$ curl failed to create" }
        var cURL = [String]()
        cURL.append("curl -v")
        cURL.append("-X \(httpMethod)")
        
        var allHeaders = [String: String]()
        if let additionalHeaders = urlSession?.configuration.httpAdditionalHeaders as? [String: String] {
            allHeaders.merge(additionalHeaders, uniquingKeysWith: { _, new in new })
        }
        if let allHTTPHeaderFields {
            allHeaders.merge(allHTTPHeaderFields, uniquingKeysWith: { _, new in new })
        }
        cURL.append(contentsOf: allHeaders
            .mapValues { $0.replacingOccurrences(of: "\"", with: "\\\"") }
            .map { "-H \"\($0.key): \($0.value)\"" }
        )
        if let httpBody {
            let httpBodyString = String(decoding: httpBody, as: UTF8.self)
            let escapedBody = httpBodyString
                .replacingOccurrences(of: "\\\"", with: "\\\\\"")
                .replacingOccurrences(of: "\"", with: "\\\"")
            cURL.append("-d \"\(escapedBody)\"")
        }
        let urlString = url.absoluteString
            .replacingOccurrences(of: "$", with: "%24") // encoded JSON payload
        cURL.append("\"\(urlString)\"")
        return cURL.joined(separator: " \\\n\t")
    }
}
