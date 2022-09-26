//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public let eventKey = EventPayload.CodingKeys.self

public extension StreamMockServer {
    
    func configureEventEndpoints() {
        server.register(MockEndpoint.event) { [weak self] request in
            let channelId = try XCTUnwrap(request.params[EndpointQuery.channelId])
            let json = TestData.toJson(request.body)
            let event = json[JSONKey.event] as? [String: Any]
            let eventType = event?[eventKey.eventType.rawValue] as? String
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
        event?[eventKey.user.rawValue] = user
        event?[eventKey.createdAt.rawValue] = TestData.currentDate
        event?[eventKey.eventType.rawValue] = eventType
        event?[eventKey.cid.rawValue] = "\(ChannelType.messaging.rawValue):\(channelId)"
        event?[eventKey.channelId.rawValue] = channelId
        json[JSONKey.event] = event
        return .ok(.json(json))
    }
    
    private func sendEvent(_ eventType: EventType, channelId: String) -> HttpResponse {
        sendEvent(eventType.rawValue, channelId: channelId)
    }
}
