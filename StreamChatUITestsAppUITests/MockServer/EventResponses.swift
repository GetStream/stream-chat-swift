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
            self.sendEvent(.messageRead, request: request)
        }
    }
    
    private func event(request: HttpRequest) -> HttpResponse {
        let json = TestData.toJson(request.body)
        let eventKey = TopLevelKey.event.rawValue
        let event = json[eventKey] as! [String: Any]
        let eventType = event[EventPayload.CodingKeys.eventType.rawValue]
        return sendEvent(eventType as! String, request: request)
    }

    private func sendEvent(_ eventType: String, request: HttpRequest) -> HttpResponse {
        var json = TestData.toJson(.httpChatEvent)
        let eventKey = TopLevelKey.event.rawValue
        var event = json[eventKey] as! [String: Any]
        event[EventPayload.CodingKeys.createdAt.rawValue] = TestData.currentDate
        event[EventPayload.CodingKeys.eventType.rawValue] = eventType
        json[eventKey] = event
        return .ok(.json(json))
    }
    
    private func sendEvent(_ eventType: EventType, request: HttpRequest) -> HttpResponse {
        sendEvent(eventType.rawValue, request: request)
    }
}
