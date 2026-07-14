//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import SwiftUI
import UIKit

/// A small `ObservableObject` that loads an image through the Stream media loader
/// and publishes it for SwiftUI.
@MainActor
final class FetchImage: ObservableObject {
    @Published private(set) var image: UIImage?
    private var requestID = UUID()

    func load(_ url: URL) {
        image = nil
        let requestID = UUID()
        self.requestID = requestID
        Components.default.mediaLoader.loadImage(url: url, options: ImageLoadOptions()) { [weak self] result in
            guard self?.requestID == requestID else { return }
            if case let .success(loaded) = result {
                self?.image = loaded.image
            }
        }
    }

    var view: SwiftUI.Image? {
        image.map(Image.init(uiImage:))
    }
}
