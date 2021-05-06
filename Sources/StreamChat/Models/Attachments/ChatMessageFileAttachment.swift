//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatMessageFileAttachment = _ChatMessageAttachment<AttachmentFilePayload>

public struct AttachmentFilePayload: AttachmentPayload {
    public static let type: AttachmentType = .file

    /// A title, usually the name of the image.
    public let title: String?
    /// A link to the image.
    public internal(set) var assetURL: URL
    /// A link to the image preview.
    public let file: AttachmentFile
}

extension AttachmentFilePayload: Equatable {}

// MARK: - Encodable

extension AttachmentFilePayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(assetURL, forKey: .assetURL)
        try file.encode(to: encoder)
    }
}

// MARK: - Decodable

extension AttachmentFilePayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        guard
            let assetURL = try container
            .decodeIfPresent(String.self, forKey: .assetURL)?
            .attachmentFixedURL
        else {
            throw ClientError.AttachmentDecoding("File attachment must contain `assetURL`")
        }

        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            assetURL: assetURL,
            file: try AttachmentFile(from: decoder)
        )
    }
}
