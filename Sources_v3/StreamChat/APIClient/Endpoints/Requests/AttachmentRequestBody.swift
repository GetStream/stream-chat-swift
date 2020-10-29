//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the attachment data that will be sent to backend.
///
/// There are more things that can be sent in attachment request body like UI customization (`color`, `footer`) or `pretext`
/// but they are not required and can be omitted if they are not used.
/// Author fields (`author_name`, `author_link`, `author_icon`) can also be used by client side but they
/// can be overwritten by `URL` enriching on backend so it's not safe to use them.
struct AttachmentRequestBody<ExtraData: AttachmentExtraData>: Encodable {
    let type: AttachmentType
    let title: String
    let url: URL?
    let imageURL: URL?
    let file: AttachmentFile?
    let extraData: ExtraData
    
    private enum CodingKeys: String, CodingKey {
        case title
        case type
        case image
        case url
        case fallback
        case assetURL = "asset_url"
        case imageURL = "image_url"
    }
    
    /// Image upload:
    ///    {
    ///        type: 'image',
    ///        image_url: image.url,
    ///        fallback: image.file.name,
    ///    }
    ///
    /// File upload:
    ///    {
    ///         type: 'file',
    ///         asset_url: upload.url,
    ///         title: upload.file.name,
    ///         mime_type: upload.file.type,
    ///         file_size: upload.file.size,
    ///    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: (type == .image ? .fallback : .title))
        try container.encodeIfPresent(url, forKey: .assetURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try file?.encode(to: encoder)
        try extraData.encode(to: encoder)
    }
}
