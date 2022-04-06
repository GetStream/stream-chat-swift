//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    // TODO: CIS-1686
    func configureChannelEndpoints() {
        server[MockEndpoint.query] = { [weak self] _ in
            self?.mockChannel(mockFile: .httpChannels) ?? .badRequest(nil)
        }
        server[MockEndpoint.channels] = { [weak self] _ in
            self?.mockChannel(mockFile: .httpChannelQuery) ?? .badRequest(nil)
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
