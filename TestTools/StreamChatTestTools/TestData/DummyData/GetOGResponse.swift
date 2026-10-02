//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension GetOGResponse {
    static func dummy(
        assetUrl: String? = nil,
        authorName: String? = nil,
        imageUrl: String? = nil,
        ogScrapeUrl: String? = "https://getstream.io",
        text: String? = nil,
        thumbUrl: String? = nil,
        title: String? = nil,
        titleLink: String? = nil
    ) -> GetOGResponse {
        GetOGResponse(
            assetUrl: assetUrl,
            authorName: authorName,
            imageUrl: imageUrl,
            ogScrapeUrl: ogScrapeUrl,
            text: text,
            thumbUrl: thumbUrl,
            title: title,
            titleLink: titleLink
        )
    }
}
