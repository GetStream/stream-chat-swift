//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// The image attachment preview information.
public struct ImageAttachmentPreview: AttachmentPreview {
    /// The image preview.
    public let image: UIImage
    /// The name of the image attachment.
    public let name: String?
    /// The size of the attachment.
    public let size: Int64
    /// The local url of the image attachment.
    public let localURL: URL

    public init(image: UIImage, localURL: URL, name: String? = nil) {
        self.image = image
        self.name = name
        self.localURL = localURL
        if let imageData = image.imageData, !imageData.isEmpty {
            size = Int64(imageData.count) / 1000
        } else {
            size = 0
        }
    }
}
