//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension UIImageView {
    @discardableResult
    func loadImage(
        from url: URL?,
        placeholder: UIImage? = nil,
        resizeAutomatically: Bool = true,
        completion: ImageTask.Completion? = nil
    ) -> ImageTask? {
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            if let url = url {
                image = UIImage(data: try! Data(contentsOf: url))
                completion?(
                    .success(
                        ImageResponse(
                            container: ImageContainer(image: image!)
                        )
                    )
                )
                return nil
            }

            image = placeholder
            return nil
        }

        // Cancel any previous loading task
        currentImageLoadingTask?.cancel()

        guard
            let url = url
        else {
            image = nil
            return nil
        }

        let preprocessors: [ImageProcessing] = resizeAutomatically && bounds.size != .zero
            ? [ImageProcessors.Resize(size: bounds.size, contentMode: .aspectFill, crop: true)]
            : []
 
        let request = ImageRequest(url: url, processors: preprocessors)
        let options = ImageLoadingOptions(placeholder: placeholder)

        currentImageLoadingTask = Nuke.loadImage(with: request, options: options, into: self, completion: completion)
        return currentImageLoadingTask
    }
}

private extension UIImageView {
    static var nukeLoadingTaskKey: UInt8 = 0

    var currentImageLoadingTask: ImageTask? {
        get { objc_getAssociatedObject(self, &Self.nukeLoadingTaskKey) as? ImageTask }
        set { objc_setAssociatedObject(self, &Self.nukeLoadingTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
