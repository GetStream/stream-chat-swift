//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    func configureEventEndpoints() {
        server[MockEndpoint.event] = { request in
            self.event(request: request)
        }
        server[MockEndpoint.messageRead] = { request in
            let response = self.sendEvent(.messageRead, request: request)
            self.websocketEvent(.messageRead, user: UserDetails.lukeSkywalker)
            return response
        }
    }
    
    private func event(request: HttpRequest) -> HttpResponse {
        let json = TestData.toJson(request.body)
        let event = json[TopLevelKey.event] as! [String: Any]
        let eventType = event[EventPayload.CodingKeys.eventType.rawValue]
        return sendEvent(eventType as! String, request: request)
    }

    private func sendEvent(_ eventType: String, request: HttpRequest) -> HttpResponse {
        var json = TestData.toJson(.httpChatEvent)
        var event = json[TopLevelKey.event] as! [String: Any]
        let user = setUpUser(
            event[EventPayload.CodingKeys.user.rawValue] as! [String: Any],
            userDetails: UserDetails.lukeSkywalker
        )
        event[EventPayload.CodingKeys.user.rawValue] = user
        event[EventPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        event[EventPayload.CodingKeys.eventType.rawValue] = eventType
        json[TopLevelKey.event] = event
        return .ok(.json(json))
    }
    
    private func sendEvent(_ eventType: EventType, request: HttpRequest) -> HttpResponse {
        sendEvent(eventType.rawValue, request: request)
    }
}
