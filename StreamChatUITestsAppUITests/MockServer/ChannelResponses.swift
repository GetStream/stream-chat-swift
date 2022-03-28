//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    // TODO: CIS-1686
    func configureChannelEndpoints() {
        server[MockEndpoint.query] = { _ in
            self.mockChannel(mockFile: .httpChannels)
        }
        server[MockEndpoint.channels] = { _ in
            self.mockChannel(mockFile: .httpChannelQuery)
        }
    }
    
    private func mockChannel(mockFile: MockFile) -> HttpResponse {
        var json = TestData.toJson(mockFile)
        var channels = json[TopLevelKey.channels] as! [[String: Any]]
        let first = 0
        channels[first][ChannelQuery.CodingKeys.messages.rawValue] = messageList
        json[TopLevelKey.channels] = channels
        return .ok(.json(json))
    }
}
