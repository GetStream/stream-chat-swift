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

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}
