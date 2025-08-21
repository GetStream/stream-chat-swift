//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if !os(macOS)
import UIKit.UIColor
import UIKit.UIImage
#else
import AppKit.NSImage
#endif

/// A set of options that control how the image is loaded and displayed.
struct ImageLoadingOptions {
    /// Shared options.
    @MainActor static var shared = ImageLoadingOptions()

    /// Placeholder to be displayed when the image is loading. `nil` by default.
    var placeholder: PlatformImage?

    /// Image to be displayed when the request fails. `nil` by default.
    var failureImage: PlatformImage?

    #if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)

    /// The image transition animation performed when displaying a loaded image.
    /// Only runs when the image was not found in memory cache. `nil` by default.
    var transition: Transition?

    /// The image transition animation performed when displaying a failure image.
    /// `nil` by default.
    var failureImageTransition: Transition?

    /// If true, the requested image will always appear with transition, even
    /// when loaded from cache.
    var alwaysTransition = false

    func transition(for response: ResponseType) -> Transition? {
        switch response {
        case .success: return transition
        case .failure: return failureImageTransition
        case .placeholder: return nil
        }
    }

    #endif

    /// If true, every time you request a new image for a view, the view will be
    /// automatically prepared for reuse: image will be set to `nil`, and animations
    /// will be removed. `true` by default.
    var isPrepareForReuseEnabled = true

    /// If `true`, every progressively generated preview produced by the pipeline
    /// is going to be displayed. `true` by default.
    ///
    /// - note: To enable progressive decoding, see `ImagePipeline.Configuration`,
    /// `isProgressiveDecodingEnabled` option.
    var isProgressiveRenderingEnabled = true

    /// Custom pipeline to be used. `nil` by default.
    var pipeline: ImagePipeline?

    /// Image processors to be applied unless the processors are provided in the
    /// request. `[]` by default.
    var processors: [any ImageProcessing] = []

    #if os(iOS) || os(tvOS) || os(visionOS)

    /// Content modes to be used for each image type (placeholder, success,
    /// failure). `nil`  by default (don't change content mode).
    var contentModes: ContentModes?

    /// Custom content modes to be used for each image type (placeholder, success,
    /// failure).
    struct ContentModes {
        /// Content mode to be used for the loaded image.
        var success: UIView.ContentMode
        /// Content mode to be used when displaying a `failureImage`.
        var failure: UIView.ContentMode
        /// Content mode to be used when displaying a `placeholder`.
        var placeholder: UIView.ContentMode

        /// - parameters:
        ///   - success: A content mode to be used with a loaded image.
        ///   - failure: A content mode to be used with a `failureImage`.
        ///   - placeholder: A content mode to be used with a `placeholder`.
        init(success: UIView.ContentMode, failure: UIView.ContentMode, placeholder: UIView.ContentMode) {
            self.success = success; self.failure = failure; self.placeholder = placeholder
        }
    }

    func contentMode(for response: ResponseType) -> UIView.ContentMode? {
        switch response {
        case .success: return contentModes?.success
        case .placeholder: return contentModes?.placeholder
        case .failure: return contentModes?.failure
        }
    }

    /// Tint colors to be used for each image type (placeholder, success,
    /// failure). `nil`  by default (don't change tint color or rendering mode).
    var tintColors: TintColors?

    /// Custom tint color to be used for each image type (placeholder, success,
    /// failure).
    struct TintColors {
        /// Tint color to be used for the loaded image.
        var success: UIColor?
        /// Tint color to be used when displaying a `failureImage`.
        var failure: UIColor?
        /// Tint color to be used when displaying a `placeholder`.
        var placeholder: UIColor?

        /// - parameters:
        ///   - success: A tint color to be used with a loaded image.
        ///   - failure: A tint color to be used with a `failureImage`.
        ///   - placeholder: A tint color to be used with a `placeholder`.
        init(success: UIColor?, failure: UIColor?, placeholder: UIColor?) {
            self.success = success; self.failure = failure; self.placeholder = placeholder
        }
    }

    func tintColor(for response: ResponseType) -> UIColor? {
        switch response {
        case .success: return tintColors?.success
        case .placeholder: return tintColors?.placeholder
        case .failure: return tintColors?.failure
        }
    }

    #endif

    #if os(iOS) || os(tvOS) || os(visionOS)

    /// - parameters:
    ///   - placeholder: Placeholder to be displayed when the image is loading.
    ///   - transition: The image transition animation performed when
    ///   displaying a loaded image. Only runs when the image was not found in
    ///   memory cache.
    ///   - failureImage: Image to be displayed when request fails.
    ///   - failureImageTransition: The image transition animation
    ///   performed when displaying a failure image.
    ///  - contentModes: Content modes to be used for each image type
    ///  (placeholder, success, failure).
    init(placeholder: UIImage? = nil, transition: Transition? = nil, failureImage: UIImage? = nil, failureImageTransition: Transition? = nil, contentModes: ContentModes? = nil, tintColors: TintColors? = nil) {
        self.placeholder = placeholder
        self.transition = transition
        self.failureImage = failureImage
        self.failureImageTransition = failureImageTransition
        self.contentModes = contentModes
        self.tintColors = tintColors
    }

    #elseif os(macOS)

    init(placeholder: NSImage? = nil, transition: Transition? = nil, failureImage: NSImage? = nil, failureImageTransition: Transition? = nil) {
        self.placeholder = placeholder
        self.transition = transition
        self.failureImage = failureImage
        self.failureImageTransition = failureImageTransition
    }

    #elseif os(watchOS)

    init(placeholder: UIImage? = nil, failureImage: UIImage? = nil) {
        self.placeholder = placeholder
        self.failureImage = failureImage
    }

    #endif

    /// An animated image transition.
    struct Transition {
        var style: Style

        #if os(iOS) || os(tvOS) || os(visionOS)
        enum Style { // internal representation
            case fadeIn(parameters: Parameters)
            case custom((ImageDisplayingView, UIImage) -> Void)
        }

        struct Parameters { // internal representation
            let duration: TimeInterval
            let options: UIView.AnimationOptions
        }

        /// Fade-in transition (cross-fade in case the image view is already
        /// displaying an image).
        static func fadeIn(duration: TimeInterval, options: UIView.AnimationOptions = .allowUserInteraction) -> Transition {
            Transition(style: .fadeIn(parameters: Parameters(duration: duration, options: options)))
        }

        /// Custom transition. Only runs when the image was not found in memory cache.
        static func custom(_ closure: @escaping (ImageDisplayingView, UIImage) -> Void) -> Transition {
            Transition(style: .custom(closure))
        }

        #elseif os(macOS)
        enum Style { // internal representation
            case fadeIn(parameters: Parameters)
            case custom((ImageDisplayingView, NSImage) -> Void)
        }

        struct Parameters { // internal representation
            let duration: TimeInterval
        }

        /// Fade-in transition.
        static func fadeIn(duration: TimeInterval) -> Transition {
            Transition(style: .fadeIn(parameters: Parameters(duration: duration)))
        }

        /// Custom transition. Only runs when the image was not found in memory cache.
        static func custom(_ closure: @escaping (ImageDisplayingView, NSImage) -> Void) -> Transition {
            Transition(style: .custom(closure))
        }
        #else
        enum Style {}
        #endif
    }

    init() {}

    enum ResponseType {
        case success, failure, placeholder
    }
}
