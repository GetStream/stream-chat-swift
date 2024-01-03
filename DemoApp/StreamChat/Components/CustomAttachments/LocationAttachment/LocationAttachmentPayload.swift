//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

public extension AttachmentType {
    static let location = Self(rawValue: "custom_location")
}

struct LocationCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

public struct LocationAttachmentPayload: AttachmentPayload {
    public static var type: AttachmentType = .location

    var coordinate: LocationCoordinate
}

public typealias ChatMessageLocationAttachment = ChatMessageAttachment<LocationAttachmentPayload>
