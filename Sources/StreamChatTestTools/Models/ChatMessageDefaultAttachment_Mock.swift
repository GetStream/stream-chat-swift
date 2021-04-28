//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChatMessageDefaultAttachment {
    public static func mock(
        imageUrl: URL?,
        title: String
    ) -> Self {
        var attachment = Self(id: .unique, type: .image, localURL: nil, localState: nil, title: title)
        attachment.imageURL = imageUrl
        return attachment
    }
}
