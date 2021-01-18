//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct HTTPHeader {
    let key: Key
    let value: String
}

extension HTTPHeader {
    enum Key: String {
        case authorization = "Authorization"
        case streamAuthType = "Stream-Auth-Type"
        case contentType = "Content-Type"
    }
}

extension HTTPHeader {
    static var anonymousStreamAuth: Self {
        .init(key: .streamAuthType, value: "anonymous")
    }

    static var jwtStreamAuth: Self {
        .init(key: .streamAuthType, value: "jwt")
    }

    static func authorization(_ token: String) -> Self {
        .init(key: .authorization, value: token)
    }
}

extension URLRequest {
    mutating func setHTTPHeaders(_ headers: HTTPHeader...) {
        headers.forEach {
            setValue($0.value, forHTTPHeaderField: $0.key.rawValue)
        }
    }

    mutating func addHTTPHeaders(_ headers: HTTPHeader...) {
        headers.forEach {
            addValue($0.value, forHTTPHeaderField: $0.key.rawValue)
        }
    }
}
