//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for an attachment with `StaticLocationAttachmentPayload` payload type.
///
/// Static location attachments represent a location that doesn't change.
public typealias ChatMessageStaticLocationAttachment = ChatMessageAttachment<StaticLocationAttachmentPayload>

/// The payload for attachments with `.staticLocation` type.
public struct StaticLocationAttachmentPayload: AttachmentPayload {
    /// The type used to parse the attachment.
    public static var type: AttachmentType = .staticLocation

    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
    /// The extra data for the attachment payload.
    public var extraData: [String: RawJSON]?

    public init(
        latitude: Double,
        longitude: Double,
        extraData: [String: RawJSON]? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.extraData = extraData
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try extraData?.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)

        self.init(
            latitude: latitude,
            longitude: longitude,
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
