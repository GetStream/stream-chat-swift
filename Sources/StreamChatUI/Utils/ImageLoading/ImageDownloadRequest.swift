//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The url and options information of an image download request.
public struct ImageDownloadRequest {
    public let url: URL
    public let options: ImageDownloadOptions

    public init(url: URL, options: ImageDownloadOptions) {
        self.url = url
        self.options = options
    }
}
