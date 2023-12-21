//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat

public extension AttachmentType {
    static let location = Self(rawValue: "custom_location")
}

struct LocationCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}

public struct LocationAttachmentPayload: AttachmentPayload {
    public static var type: AttachmentType = .location

    var coordinate: LocationCoordinate
}

public typealias ChatMessageLocationAttachment = ChatMessageAttachment<LocationAttachmentPayload>
