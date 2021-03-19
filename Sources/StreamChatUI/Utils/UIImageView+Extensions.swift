//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension UIImageView {
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            image = url.flatMap { UIImage(data: try! Data(contentsOf: $0)) }
            return
        }

        // Cancel any previous loading task
        currentImageLoadingTask?.cancel()

        guard let url = url else { image = nil; return }
        let options = ImageLoadingOptions(placeholder: placeholder)

        currentImageLoadingTask = Nuke.loadImage(with: request, options: options, into: self)
    }
}

private extension UIImageView {
    static var nukeLoadingTaskKey: UInt8 = 0

    var currentImageLoadingTask: ImageTask? {
        get { objc_getAssociatedObject(self, &Self.nukeLoadingTaskKey) as? ImageTask }
        set { objc_setAssociatedObject(self, &Self.nukeLoadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
