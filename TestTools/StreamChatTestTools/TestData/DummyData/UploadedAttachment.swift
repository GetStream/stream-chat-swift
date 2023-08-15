//
//  UploadedAttachment.swift
//  StreamChat
//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UploadedAttachment {
    static func dummy(
        attachment: AnyChatMessageAttachment = .dummy(),
        remoteURL: URL = .unique(),
        thumbnailURL: URL = .unique()
    ) -> UploadedAttachment {
        UploadedAttachment(
            attachment: attachment,
            remoteURL: remoteURL,
            thumbnailURL: thumbnailURL
        )
    }
}
