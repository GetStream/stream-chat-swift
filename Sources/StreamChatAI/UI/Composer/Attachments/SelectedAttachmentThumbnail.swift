//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

@available(iOS 16, *)
struct SelectedAttachmentThumbnail: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var image: UIImage?
    @State private var didFail = false

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    
    var body: some View {
        ThumbnailTile(image: image, didFail: didFail)
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    TileBadge(image: images.composerRemove, fill: Color(colors.attachmentBadgeBackground))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .padding(6)
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
        await Task.detached(priority: .userInitiated) {
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }.value
    }
}
