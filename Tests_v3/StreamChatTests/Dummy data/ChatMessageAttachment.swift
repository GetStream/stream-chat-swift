//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension _ChatMessageAttachment {
    static func dummy<T: ExtraDataTypes>(
        id: AttachmentId = .unique,
        localURL: URL? = .unique(),
        localState: LocalAttachmentState? = nil,
        title: String = .unique,
        author: String? = .unique,
        text: String? = .unique,
        type: AttachmentType = .image,
        url: URL? = URL(string: "https://getstream.io/some.jpg"),
        imageURL: URL? = URL(string: "https://getstream.io/some.jpg"),
        imagePreviewURL: URL? = URL(string: "https://getstream.io/some_preview.jpg"),
        file: AttachmentFile? = .init(type: .gif, size: 1024, mimeType: "image/gif"),
        extraData: T.Attachment = .defaultValue
    ) -> _ChatMessageAttachment<T> {
        .init(
            id: id,
            localURL: localURL,
            localState: localState,
            title: .unique,
            author: .unique,
            text: .unique,
            type: .image,
            actions: [],
            url: url,
            imageURL: imageURL,
            imagePreviewURL: imagePreviewURL,
            file: nil,
            extraData: .defaultValue
        )
    }

    init(
        cid: ChannelId,
        messageId: MessageId,
        index: Int,
        seed: Seed,
        localState: LocalAttachmentState? = .pendingUpload
    ) {
        self.init(
            id: .init(cid: cid, messageId: messageId, index: index),
            localURL: seed.localURL,
            localState: localState,
            title: seed.fileName,
            author: nil,
            text: nil,
            type: .image,
            actions: [],
            url: nil,
            imageURL: nil,
            imagePreviewURL: nil,
            file: seed.file,
            extraData: .defaultValue
        )
    }
}

extension _ChatMessageAttachment.Seed {
    static func dummy(
        localURL: URL = .unique(),
        fileName: String = .unique,
        type: AttachmentType = .image,
        extraData: ExtraData.Attachment = .defaultValue
    ) -> Self {
        .init(
            localURL: localURL,
            fileName: fileName,
            type: type,
            extraData: extraData
        )
    }
}

extension NoExtraData {
    static var dummyAttachment: _ChatMessageAttachment<NoExtraData> { .dummy() }
}
