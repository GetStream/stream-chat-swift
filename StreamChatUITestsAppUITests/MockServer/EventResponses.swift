//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureEventEndpoints() {
        server.register(MockEndpoint.event) { [weak self] request in
            let channelId = try XCTUnwrap(request.params[EndpointQuery.channelId])
            let json = TestData.toJson(request.body)
            let event = json[JSONKey.event] as? [String: Any]
            let eventType = event?[EventPayload.CodingKeys.eventType.rawValue] as? String
            self?.websocketEvent(
                EventType(rawValue: String(describing: eventType)),
                user: UserDetails.lukeSkywalker,
                channelId: channelId
            )
            return self?.sendEvent(eventType, channelId: channelId)
        }
        server.register(MockEndpoint.messageRead) { [weak self] request in
            let channelId = try XCTUnwrap(request.params[EndpointQuery.channelId])
            self?.websocketEvent(.messageRead, user: UserDetails.lukeSkywalker, channelId: channelId)
            return self?.sendEvent(.messageRead, channelId: channelId)
        }
    }

    private func sendEvent(_ eventType: String?, channelId: String) -> HttpResponse {
        var json = TestData.toJson(.httpChatEvent)
        var event = json[JSONKey.event] as? [String: Any]
        let user = setUpUser(source: event, details: UserDetails.lukeSkywalker)
        event?[EventPayload.CodingKeys.user.rawValue] = user
        event?[EventPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        event?[EventPayload.CodingKeys.eventType.rawValue] = eventType
        event?[EventPayload.CodingKeys.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(channelId)"
        event?[EventPayload.CodingKeys.channelId.rawValue] = channelId
        json[JSONKey.event] = event
        return .ok(.json(json))
    }
    
    private func sendEvent(_ eventType: EventType, channelId: String) -> HttpResponse {
        sendEvent(eventType.rawValue, channelId: channelId)
    }
}
