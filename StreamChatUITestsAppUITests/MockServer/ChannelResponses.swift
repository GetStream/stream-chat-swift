//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    // TODO: CIS-1686
    func configureChannelEndpoints() {
        server[MockEndpoint.query] = { _ in
            .ok(.text(TestData.getMockResponse(fromFile: .httpChannel)))
        }
        server[MockEndpoint.channels] = { _ in
            .ok(.text(TestData.getMockResponse(fromFile: .httpChannelsQuery)))
        }
    }
}
