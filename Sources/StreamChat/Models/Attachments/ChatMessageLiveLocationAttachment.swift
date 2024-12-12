//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    public init(latitude: Double, longitude: Double, stoppedSharing: Bool) {
        self.latitude = latitude
        self.longitude = longitude
        self.stoppedSharing = stoppedSharing
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case stoppedSharing = "stopped_sharing"
    }
}
