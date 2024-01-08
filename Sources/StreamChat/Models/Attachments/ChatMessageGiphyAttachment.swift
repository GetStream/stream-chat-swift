//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    public var title: String?
    /// A link to gif file.
    public var previewURL: URL
    /// Actions when gif is not sent yet. (e.g. `Shuffle`)
    public var actions: [AttachmentAction]
    /// The extra data for the attachment payload.
    public var extraData: [String: RawJSON]?

    /// - Parameters:
    ///   - title: The title of the giphy.
    ///   - previewURL: The preview url of the giphy.
    ///   - actions: The actions when gif is not sent yet. (e.g. `Shuffle`)
    ///   - extraData: The extra data for the attachment payload.
    public init(
        title: String?,
        previewURL: URL,
        actions: [AttachmentAction] = [],
        extraData: [String: RawJSON]? = nil
    ) {
        self.title = title
        self.previewURL = previewURL
        self.actions = actions
        self.extraData = extraData
    }
}

extension GiphyAttachmentPayload: Hashable {}

enum GiphyAttachmentSpecificCodingKeys: String, CodingKey {
    case actions
}

// MARK: - Encodable

extension GiphyAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(previewURL, forKey: .thumbURL)

        // Encode giphy attachment specific keys
        var giphyAttachmentContainer = encoder.container(keyedBy: GiphyAttachmentSpecificCodingKeys.self)
        try giphyAttachmentContainer.encode(actions, forKey: .actions)

        try extraData?.encode(to: encoder)
    }
}

// MARK: - Decodable

extension GiphyAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        // Used for decoding giphy attachment specific keys
        let giphyAttachmentContainer = try decoder.container(keyedBy: GiphyAttachmentSpecificCodingKeys.self)
        let actions = try giphyAttachmentContainer.decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? []

        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            previewURL: try container.decode(URL.self, forKey: .thumbURL),
            actions: actions,
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
