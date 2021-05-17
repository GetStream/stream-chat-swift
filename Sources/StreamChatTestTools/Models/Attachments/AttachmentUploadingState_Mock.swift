//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

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
