//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

extension UIImageView {
    /// Load image from URL
    /// - Parameters:
    ///   - url: URL of the image.
    ///   - placeholder: Placeholder to show while the image is loading or in case the loading fails.
    ///   - resize: Request thumbnail if supported and resize loaded image to match the size of the image view.
    ///   - preferredSize: Specify the thumbnail and resized image size.
    ///   - components: dependency injection for components.
    ///   - completion: Image request completion block.
    /// - Returns: Active image download task.
    @discardableResult
    func loadImage<ExtraData: ExtraDataTypes>(
        from url: URL?,
        placeholder: UIImage? = nil,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        components: _Components<ExtraData>,
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
            var url = url
        else {
            image = placeholder
            return nil
        }

        let size = preferredSize ?? bounds.size
        let preprocessors: [ImageProcessing] = resize && size != .zero
            ? [ImageProcessors.Resize(size: size, contentMode: .aspectFill, crop: true)]
            : []
        
        if resize && size != .zero {
            url = components.imageCDN.thumbnailURL(originalURL: url, preferredSize: size)
        }
        
        let imageKey = components.imageCDN.cachingKey(forImage: url)
        let request = ImageRequest(url: url, processors: preprocessors, options: ImageRequestOptions(filteredURL: imageKey))
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
