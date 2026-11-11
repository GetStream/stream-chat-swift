//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct MessagePhotosView: View {
    let photos: [ChatMessageImageAttachment]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(photos.prefix(4)) { photo in
                ResizedImage(
                    url: photo.payload.imageURL,
                    // Clip fits the photo inside the box, so a box twice the tile still fills the tile for photos up to 2:1.
                    resize: CDNImageResize(width: 640, height: 640, resizeMode: "clip"),
                    contentMode: .fill
                )
                .frame(width: 320, height: 320)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .overlay(alignment: .trailing) {
            if photos.count > 4 {
                Text("+\(photos.count - 4)")
                    .font(.title2)
                    .frame(width: 320, height: 320)
                    .background(.black.opacity(0.5), in: .rect(cornerRadius: 12))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("^[\(photos.count) photo](inflect: true)"))
    }
}

struct PhotoViewer: View {
    let photos: [ChatMessageImageAttachment]
    @State private var index = 0

    var body: some View {
        ResizedImage(
            url: photos[index].payload.imageURL,
            resize: CDNImageResize(width: 1920, height: 1080, resizeMode: "clip"),
            contentMode: .fit
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .overlay(alignment: .bottom) {
            if photos.count > 1 {
                Text("\(index + 1) of \(photos.count)")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: .capsule)
            }
        }
        // Focus lets the remote's left and right presses page through the photos.
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left: index = max(index - 1, 0)
            case .right: index = min(index + 1, photos.count - 1)
            default: break
            }
        }
    }
}

private struct ResizedImage: View {
    let url: URL
    let resize: CDNImageResize
    let contentMode: ContentMode
    @State private var resolvedURL: URL?

    var body: some View {
        AsyncImage(url: resolvedURL) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .task(id: url) {
            let request = try? await Self.cdnRequester.imageRequest(for: url, options: ImageRequestOptions(resize: resize))
            resolvedURL = request?.url ?? url
        }
    }

    private static let cdnRequester = StreamCDNRequester()
}
