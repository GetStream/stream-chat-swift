//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension AttachmentUploadingState {
    /// Creates a new `AttachmentUploadingState` object from the provided data.
    static func mock(
        localFileURL: URL = .localYodaQuote,
        state: LocalAttachmentState = .uploaded
    ) throws -> Self {
        .init(
            localFileURL: localFileURL,
            state: state,
            file: try AttachmentFile(url: localFileURL)
        )
    }
}
