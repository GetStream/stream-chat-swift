//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class TestBuilder {
    let encoder = RequestEncoder_Spy(
        baseURL: .unique(),
        apiKey: .init(.unique)
    )
    let decoder = RequestDecoder_Spy()
    var sessionConfiguration = URLSessionConfiguration.ephemeral
    let uniqueHeaderValue = String.unique

    func make() -> StreamCDNClient {
        sessionConfiguration.httpAdditionalHeaders?["unique_value"] = uniqueHeaderValue
        RequestRecorderURLProtocol_Mock.startTestSession(with: &sessionConfiguration)
        URLProtocol_Mock.startTestSession(with: &sessionConfiguration)

        return StreamCDNClient(
            encoder: encoder,
            decoder: decoder,
            sessionConfiguration: sessionConfiguration
        )
    }
}
