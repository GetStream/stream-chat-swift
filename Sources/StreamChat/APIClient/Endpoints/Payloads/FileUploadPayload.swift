//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A file upload response.
struct FileUploadPayload: Decodable {
    let fileURL: URL

    enum CodingKeys: String, CodingKey {
        case fileURL = "file"
    }
}
