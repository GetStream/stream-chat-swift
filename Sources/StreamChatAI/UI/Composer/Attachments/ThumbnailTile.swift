//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// A photo's tile: the photo once it has loaded, a warning if it couldn't, and a spinner until then.
@available(iOS 16, *)
struct ThumbnailTile: View {
    let image: UIImage?
    let didFail: Bool

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    
    var body: some View {
        AttachmentTile {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .allowsHitTesting(false)
                    .clipped()
            } else if didFail {
                images.attachmentFailed
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(colors.attachmentPickerTileFailureIcon))
            } else {
                ProgressView()
            }
        }
    }
}
