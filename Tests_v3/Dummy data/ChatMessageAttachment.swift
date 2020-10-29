//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension _ChatMessageAttachment {
    static func dummy<T: ExtraDataTypes>(
        title: String = .unique,
        author: String? = .unique,
        text: String? = .unique,
        type: AttachmentType = .image,
        url: URL? = URL(string: "https://getstream.io/some.jpg"),
        imageURL: URL? = URL(string: "https://getstream.io/some.jpg"),
        file: AttachmentFile? = .init(type: .gif, size: 1024, mimeType: "image/gif"),
        extraData: T.Attachment = .defaultValue
    ) -> _ChatMessageAttachment<T> {
        .init(
            title: .unique,
            author: .unique,
            text: .unique,
            type: .image,
            actions: [],
            url: URL(string: "https://getstream.io/some.jpg"),
            imageURL: URL(string: "https://getstream.io/some.jpg"),
            file: nil,
            extraData: .defaultValue
        )
    }
}

extension DefaultExtraData {
    static var dummyAttachment: _ChatMessageAttachment<DefaultExtraData> { .dummy() }
}
