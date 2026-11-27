//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import StreamCore
import SwiftUI
import UIKit

@available(iOS 15.0, macOS 12.0, *)
struct SelectedAttachmentThumbnail: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var image: UIImage?
    @State private var didFail = false

    @Environment(\.displayScale) private var displayScale
    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ThumbnailTile(image: image, didFail: didFail)
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    TileBadge(image: images.composerRemove, fill: Color(colors.attachmentBadgeBackground))
                        .frame(width: layout.buttonVisualHeightXs, height: layout.buttonVisualHeightXs)
                }
                .buttonStyle(.plain)
                .padding(layout.spacingXs)
            }
            .task {
                guard image == nil else { return }
                if let loaded = await loadImage() {
                    image = loaded
                    didFail = false
                } else {
                    didFail = true
                }
            }
    }
    
    private func loadImage() async -> UIImage? {
        let side = 100 * max(displayScale, 1)
        return await Task.detached(priority: .userInitiated) {
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            return Self.thumbnail(at: url, filling: side)
        }.value
    }

    // The image at `url`, decoded only as large as a square tile of `side` pixels it fills,
    // rather than at the photo's full size.
    nonisolated static func thumbnail(at url: URL, filling side: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        var maxPixelSize = side
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
           let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
           min(width, height) > 0 {
            // The tile fills its square, so the photo's shorter side is the one that covers it.
            maxPixelSize = min(side * max(width, height) / min(width, height), 4096)
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: image)
    }
}
