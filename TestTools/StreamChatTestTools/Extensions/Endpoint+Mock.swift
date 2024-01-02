//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Endpoint {
    static func mock(path: EndpointPath = .guest) -> Endpoint<ResponseType> {
        .init(path: path, method: .post, queryItems: nil, requiresConnectionId: false, body: nil)
    }
}
