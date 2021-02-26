//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type that describes attachment JSON payload.
struct AttachmentPayload: Decodable {
    /// An attachment type.
    let type: AttachmentType
    /// A raw attachment payload data.
    /// It's possible to have attachments of custom type with unknown structure
    /// so we need to keep in raw data form so it will be possible to decode later.
    let payload: RawJSON
    
    private enum CodingKeys: String, CodingKey {
        case type
        case ogURL = "og_scrape_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // `.link` attachments doesn't have type explicitly specified.
        let type: AttachmentType
        let itWasLinkOriginally = container.contains(.ogURL)
        if itWasLinkOriginally {
            type = .link(try? container.decode(String.self, forKey: .type))
        } else {
            type = AttachmentType(rawValue: try container.decode(String.self, forKey: .type))
        }
        self.type = type
        
        let singleValueContainer = try decoder.singleValueContainer()
        
        payload = try singleValueContainer.decode(RawJSON.self)
    }
}
