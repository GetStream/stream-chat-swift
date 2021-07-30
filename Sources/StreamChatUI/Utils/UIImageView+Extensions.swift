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
    ///   - preferredSize: Specify the thumbnail size.
    ///   - components: dependency injection for components.
    ///   - completion: Image request completion block.
    /// - Returns: Active image download task.
    @discardableResult
    func loadImage(
        from url: URL?,
        placeholder: UIImage? = nil,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        components: Components,
        completion: ((_ result: Result<ImageResponse, ImagePipeline.Error>) -> Void)? = nil
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

        let preprocessors: [ImageProcessing] = resize
            ? [ImageProcessors.LateResize(sizeProvider: { [weak self] in self?.bounds.size ?? .zero })]
            : []
  
        let size = preferredSize ?? bounds.size
        if resize && size != .zero {
            url = components.imageCDN.thumbnailURL(originalURL: url, preferredSize: size)
        }
        
        let imageKey = components.imageCDN.cachingKey(forImage: url)
        let urlRequest = components.imageCDN.urlRequest(forImage: url)
        let request = ImageRequest(
            urlRequest: urlRequest,
            processors: preprocessors,
            options: ImageRequestOptions(filteredURL: imageKey)
        )
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

extension ImageProcessors {
    /// Scales an image to a specified size.
    /// The getting of the size is offloaded via closure after the image is loaded.
    /// The View has time to layout and provide non-zero size.
    public struct LateResize: ImageProcessing {
        private var size: CGSize {
            var size: CGSize = .zero
            DispatchQueue.main.sync { size = sizeProvider() }
            return size
        }

        private let sizeProvider: () -> CGSize
        
        /// Initializes the processor with size providing closure.
        /// - Parameter sizeProvider: Closure to obtain size after the image is loaded.
        public init(sizeProvider: @escaping () -> CGSize) {
            self.sizeProvider = sizeProvider
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            let size = self.size
            guard size != .zero else { return image }
            
            return ImageProcessors.Resize(
                size: size,
                unit: .points,
                contentMode: .aspectFill,
                upscale: false
            ).process(image)
        }

        public var identifier: String {
            "com.github.kean/nuke/lateResize"
        }
    }
}
