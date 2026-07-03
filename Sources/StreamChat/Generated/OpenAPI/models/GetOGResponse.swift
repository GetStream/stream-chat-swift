//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetOGResponse: Sendable, Codable, JSONEncodable {
    /// URL of detected video or audio
    let assetUrl: String?
    /// og:site_name
    let authorName: String?
    /// URL of detected image
    let imageUrl: String?
    /// extracted url from the text
    let ogScrapeUrl: String?
    /// og:description
    let text: String?
    /// URL of detected thumb image
    let thumbUrl: String?
    /// og:title
    let title: String?
    /// og:url
    let titleLink: String?

    init(assetUrl: String? = nil, authorName: String? = nil, imageUrl: String? = nil, ogScrapeUrl: String? = nil, text: String? = nil, thumbUrl: String? = nil, title: String? = nil, titleLink: String? = nil) {
        self.assetUrl = assetUrl
        self.authorName = authorName
        self.imageUrl = imageUrl
        self.ogScrapeUrl = ogScrapeUrl
        self.text = text
        self.thumbUrl = thumbUrl
        self.title = title
        self.titleLink = titleLink
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case assetUrl = "asset_url"
        case authorName = "author_name"
        case imageUrl = "image_url"
        case ogScrapeUrl = "og_scrape_url"
        case text
        case thumbUrl = "thumb_url"
        case title
        case titleLink = "title_link"
    }
}
