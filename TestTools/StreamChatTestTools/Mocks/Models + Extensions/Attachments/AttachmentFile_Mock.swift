//
//  AttachmentFile_Mock.swift
//  StreamChatTestTools
//
//  Created by Ilias Pavlidakis on 15/3/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension AttachmentFile {

    /// Creates a new `AttachmentFile` object from the provided data.
    static func mock(
        type: AttachmentFileType,
        size: Int64 = 120,
        mimeType: String? = nil
    ) -> AttachmentFile {
        .init(
            type: type,
            size: size,
            mimeType: mimeType
        )
    }
}

