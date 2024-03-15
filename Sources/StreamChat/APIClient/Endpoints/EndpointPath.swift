//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case connect
    case uploadAttachment(channelId: String, type: String)

    var value: String {
        switch self {
        case .connect: return "api/v2/connect"
        case let .uploadAttachment(channelId, type): return "channels/\(channelId)/\(type)"
        }
        
        #if swift(<5.5)
        // Only needed when compiling against 5.4 or lower
        enum CodingKeys: CodingKey {
            case connect, uploadAttachment
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = container.allKeys.first else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unable to decode EndpointPath"
                    )
                )
            }
            
            switch key {
            case .connect:
                self = .connect
            case .uploadAttachment:
                var nestedContainer = try container.nestedUnkeyedContainer(forKey: key)
                self = try .uploadAttachment(
                    channelId: nestedContainer.decode(String.self),
                    type: nestedContainer.decode(String.self)
                )
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .connect:
                try container.encode(true, forKey: .connect)
            case let .uploadAttachment(channelId, type):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: .uploadAttachment)
                try nestedContainer.encode(channelId)
                try nestedContainer.encode(type)
            }
        }
        #endif
    }
}
