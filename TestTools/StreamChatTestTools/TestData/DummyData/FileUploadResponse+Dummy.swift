//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension FileUploadResponse {
    static func dummy(
        file: String? = nil,
        thumbUrl: String? = nil
    ) -> FileUploadResponse {
        FileUploadResponse(
            file: file,
            thumbUrl: thumbUrl
        )
    }
}
