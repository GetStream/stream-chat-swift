//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

public struct DocumentAttachmentPreview: AttachmentPreview {
    public let image: UIImage
    public let name: String?
    public let size: Int64
    public let localURL: URL

    public init(image: UIImage, localURL: URL, name: String, size: Int64) {
        self.image = image
        self.name = name
        self.size = size
        self.localURL = localURL
    }
}
