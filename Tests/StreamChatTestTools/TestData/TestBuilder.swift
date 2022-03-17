//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class TestBuilder {
    let encoder = TestRequestEncoder(
        baseURL: .unique(),
        apiKey: .init(.unique)
    )
    let decoder = TestRequestDecoder()
    var sessionConfiguration = URLSessionConfiguration.ephemeral
    let uniqueHeaderValue = String.unique

    func make() -> StreamCDNClient {
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqueHeaderValue
        RequestRecorderURLProtocol.startTestSession(with: &sessionConfiguration)
        MockNetworkURLProtocol.startTestSession(with: &sessionConfiguration)

        return StreamCDNClient(
            encoder: encoder,
            decoder: decoder,
            sessionConfiguration: sessionConfiguration
        )
    }
}
