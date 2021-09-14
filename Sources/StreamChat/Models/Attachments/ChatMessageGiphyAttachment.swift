//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `GiphyAttachmentPayload` payload type.
///
/// The ephemeral message containing `ChatMessageGiphyAttachment` attachment will be created
/// when `/giphy` command is used.
public typealias ChatMessageGiphyAttachment = ChatMessageAttachment<GiphyAttachmentPayload>

/// Represents a payload for attachments with `.giphy` type.
public struct GiphyAttachmentPayload: AttachmentPayload {
    /// An attachment type all `GiphyAttachmentPayload` instances conform to. Is set to `.giphy`.
    public static let type: AttachmentType = .giphy
    
    /// A  title, usually the search request used to find the gif.
    public var title: String
    /// A link to gif file.
    public var previewURL: URL
    /// Actions when gif is not sent yet. (e.g. `Shuffle`)
    public var actions: [AttachmentAction]
}

extension GiphyAttachmentPayload: Equatable {}

// MARK: - Encodable

extension GiphyAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(previewURL, forKey: .thumbURL)
        try container.encode(actions, forKey: .actions)
    }
}

// MARK: - Decodable

extension GiphyAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        self.init(
            title: try container.decode(String.self, forKey: .title),
            previewURL: try container.decode(URL.self, forKey: .thumbURL),
            actions: try container.decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? []
        )
    }
}
