//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

import Foundation
extension AttachmentPayload {
    static func dummy<T: AttachmentExtraData>(
        type: AttachmentType = .image,
        title: String = .unique,
        url: URL? = URL(string: "https://getstream.io/some.jpg"),
        imageURL: URL? = URL(string: "https://getstream.io/some.jpg"),
        imagePreviewURL: URL? = URL(string: "https://getstream.io/some_preview.jpg"),
        file: AttachmentFile? = .init(type: .gif, size: 1024, mimeType: "image/gif"),
        extraData: T = .defaultValue
    ) -> AttachmentPayload<T> {
        .init(
            type: type,
            title: title,
            url: url,
            imageURL: imageURL,
            imagePreviewURL: imagePreviewURL,
            file: file,
            extraData: extraData
        )
    }
}
