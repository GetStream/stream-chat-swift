//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for an attachment with `LiveLocationAttachmentPayload` payload type.
///
/// Live location attachments are used to represent a live location sharing in a chat message.
public typealias ChatMessageLiveLocationAttachment = ChatMessageAttachment<LiveLocationAttachmentPayload>

/// The payload for attachments with `.liveLocation` type.
public struct LiveLocationAttachmentPayload: AttachmentPayload {
    /// The type used to parse the attachment.
    public static var type: AttachmentType = .liveLocation

    /// The latitude of the location.
    public let latitude: Double
    /// The longitude of the location.
    public let longitude: Double
    /// A boolean value indicating whether the live location sharing was stopped.
    public let stoppedSharing: Bool?
    /// The extra data for the attachment payload.
    public var extraData: [String: RawJSON]?

    public init(
        latitude: Double,
        longitude: Double,
        stoppedSharing: Bool? = nil,
        extraData: [String: RawJSON]? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.stoppedSharing = stoppedSharing
        self.extraData = extraData
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case stoppedSharing = "stopped_sharing"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(stoppedSharing, forKey: .stoppedSharing)
        try extraData?.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let stoppedSharing = try container.decodeIfPresent(Bool.self, forKey: .stoppedSharing)

        self.init(
            latitude: latitude,
            longitude: longitude,
            stoppedSharing: stoppedSharing ?? false,
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
