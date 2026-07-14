//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension FileUploadResponse {
    static func dummy(
        duration: String = "",
        file: String? = nil,
        thumbUrl: String? = nil
    ) -> FileUploadResponse {
        FileUploadResponse(
            duration: duration,
            file: file,
            thumbUrl: thumbUrl
        )
    }
}
