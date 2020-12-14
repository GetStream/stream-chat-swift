//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A file upload response.
struct FileUploadPayload: Decodable {
    /// An uploaded file URL.
    let file: URL
}
