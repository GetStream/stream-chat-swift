//
//  UploadedAttachment.swift
//  StreamChat
//
//  Created by Nuno Vieira on 09/11/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UploadedAttachment {
    static func dummy(
        attachment: AnyChatMessageAttachment = .dummy(),
        remoteURL: URL = .unique()
    ) -> UploadedAttachment {
        UploadedAttachment(
            attachment: attachment,
            remoteURL: remoteURL
        )
    }
}
