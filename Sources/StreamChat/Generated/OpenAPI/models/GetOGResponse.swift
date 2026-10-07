//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetOGResponse: Sendable, Decodable {
    /// URL of detected video or audio
    let assetUrl: String?
    /// og:site_name
    let authorName: String?
    let custom: [String: RawJSON]
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

    init(
        assetUrl: String? = nil,
        authorName: String? = nil,
        custom: [String: RawJSON],
        imageUrl: String? = nil,
        ogScrapeUrl: String? = nil,
        text: String? = nil,
        thumbUrl: String? = nil,
        title: String? = nil,
        titleLink: String? = nil
    ) {
        self.assetUrl = assetUrl
        self.authorName = authorName
        self.custom = custom
        self.imageUrl = imageUrl
        self.ogScrapeUrl = ogScrapeUrl
        self.text = text
        self.thumbUrl = thumbUrl
        self.title = title
        self.titleLink = titleLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.assetUrl = try container.decodeIfPresent(String.self, forKey: .assetUrl)
        self.authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.ogScrapeUrl = try container.decodeIfPresent(String.self, forKey: .ogScrapeUrl)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.thumbUrl = try container.decodeIfPresent(String.self, forKey: .thumbUrl)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.titleLink = try container.decodeIfPresent(String.self, forKey: .titleLink)
    }
}
