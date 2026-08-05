//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// A SwiftUI view rendering animated GIF data.
///
/// Updates with unchanged data do not restart or re-decode the animation.
public struct StreamAnimatedImage: UIViewRepresentable {
    private let data: Data?
    private let contentMode: UIView.ContentMode

    /// Creates a view for the given animated image data.
    ///
    /// - Parameters:
    ///   - data: The encoded animation bytes. When `nil`, the view renders nothing.
    ///   - contentMode: How the frames are fitted into the available space.
    public init(data: Data?, contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.data = data
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> StreamAnimatedImageView {
        makeView()
    }

    public func updateUIView(_ uiView: StreamAnimatedImageView, context: Context) {
        apply(to: uiView)
    }

    func makeView() -> StreamAnimatedImageView {
        let view = StreamAnimatedImageView()
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        apply(to: view)
        return view
    }

    func apply(to view: StreamAnimatedImageView) {
        view.contentMode = contentMode
        guard let data else {
            view.clearAnimatedImage()
            view.image = nil
            return
        }
        view.setAnimatedImage(data: data)
    }
}
