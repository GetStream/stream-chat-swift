//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An event type SDK fallbacks to if incoming event was failed to be
/// decoded as a system event.
public struct UnknownUserEvent: Event, Hashable {
    /// An event type.
    public let type: EventType
    
    /// A user the event is triggered for.
    public let userId: UserId
    
    /// An event creation date.
    public let createdAt: Date
    
    /// A dictionary containing the entire event JSON.
    public let payload: [String: RawJSON]
}

extension UnknownUserEvent: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: EventPayload.CodingKeys.self)
        
        self.init(
            type: try container.decode(EventType.self, forKey: .eventType),
            userId: try container.decode(UserPayload.self, forKey: .user).id,
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            payload: try decoder
                .singleValueContainer()
                .decode([String: RawJSON].self)
        )
    }
}

// MARK: - Payload

public extension UnknownUserEvent {
    /// Decodes a payload of the given type from the event.
    ///
    /// - Parameter ofType: The type of payload the custom fields should be treated as.
    /// - Returns: A payload of the given type if decoding succeeds and if event type matches the one declared in custom payload type. Otherwise `nil` is returned.
    func payload<T: CustomEventPayload>(ofType: T.Type) -> T? {
        guard
            T.eventType == type,
            let payloadData = try? JSONEncoder.default.encode(payload),
            let payload = try? JSONDecoder.default.decode(T.self, from: payloadData)
        else { return nil }
        
        return payload
    }
}
