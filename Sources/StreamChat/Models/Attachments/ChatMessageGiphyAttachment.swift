//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatMessageGiphyAttachment = _ChatMessageAttachment<AttachmentGiphyPayload>

public struct AttachmentGiphyPayload: AttachmentPayload {
    public static let type: AttachmentType = .giphy
    
    /// A  title, usually the search request used to find the gif.
    public let title: String
    /// A link to gif file.
    public let previewURL: URL
    /// Actions when gif is not sent yet. (e.g. `Shuffle`)
    public let actions: [AttachmentAction]
}

extension AttachmentGiphyPayload: Equatable {}

// MARK: - Encodable

extension AttachmentGiphyPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(previewURL, forKey: .thumbURL)
        try container.encode(actions, forKey: .actions)
    }
}

// MARK: - Decodable

extension AttachmentGiphyPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        guard
            let previewURL = try container
            .decodeIfPresent(String.self, forKey: .thumbURL)?
            .attachmentFixedURL
        else { throw ClientError.AttachmentDecoding() }

        self.init(
            title: try container.decode(String.self, forKey: .title),
            previewURL: previewURL,
            actions: try container.decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? []
        )
    }
}
