//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import SwiftUI

/// The media components of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum MediaComponents {
    /// All media components, in catalog order.
    static var all: [ComponentDefinition] {
        [image, video, audioPlayer]
    }

    /// Displays a remote or bundled image.
    static let image = ComponentDefinition(
        name: "Image",
        description: "Displays an image from a URL.",
        properties: [
            "url": JsonSchema.dynamicString(description: "The URL of the image to display."),
            "description": JsonSchema.dynamicString(description: "Accessibility text for the image."),
            "fit": JsonSchema.string(
                description: "Specifies how the image should be resized to fit its container.",
                enumValues: ["contain", "cover", "fill", "none", "scaleDown"],
                defaultValue: "fill"
            ),
            "variant": JsonSchema.string(
                description: "A hint for the image size and style.",
                enumValues: ["icon", "avatar", "smallFeature", "mediumFeature", "largeFeature", "header"],
                defaultValue: "mediumFeature"
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["url"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "Image",
                "url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300",
                "variant": "mediumFeature",
                "fit": "cover"
            }
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIImageView(
                source: context.string("url", default: ""),
                accessibilityText: context.string("description"),
                isDecorative: A2UIImageView.isDecorative(
                    description: context.string("description"),
                    label: context.component.accessibility?.label ?? .missing
                ),
                fit: context.option("fit", default: "fill"),
                variant: context.option("variant", default: "mediumFeature"),
                mediaURL: context.services.mediaURL
            )
        )
    }

    /// Plays a remote video.
    static let video = ComponentDefinition(
        name: "Video",
        description: "Displays a video from a URL.",
        properties: [
            "url": JsonSchema.dynamicString(description: "The URL of the video to display."),
            "posterUrl": JsonSchema.dynamicString(
                description: "The URL of the poster image to display before the video plays."
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["url"],
        examples: [
            """
            [
              {"id": "root", "component": "Video", "url": "https://example.com/clip.mp4"}
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIMediaPlayerView(
                url: URL(string: context.string("url", default: "")).flatMap(context.services.mediaURL),
                posterUrl: context.string("posterUrl").flatMap { URL(string: $0) }.flatMap(context.services.mediaURL),
                title: nil,
                isAudioOnly: false
            )
        )
    }

    /// Plays a remote audio file.
    static let audioPlayer = ComponentDefinition(
        name: "AudioPlayer",
        description: "A player for audio content from a URL.",
        properties: [
            "url": JsonSchema.dynamicString(description: "The URL of the audio to be played."),
            "description": JsonSchema.dynamicString(
                description: "A description of the audio, such as a title or summary."
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["url"],
        examples: [
            """
            [
              {"id": "root", "component": "AudioPlayer", "url": "https://example.com/track.mp3", "description": "Sample track"}
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIMediaPlayerView(
                url: URL(string: context.string("url", default: "")).flatMap(context.services.mediaURL),
                posterUrl: nil,
                title: context.string("description"),
                isAudioOnly: true
            )
        )
    }
}

/// Renders an A2UI `Image`, honouring its size and fit hints.
///
/// The image is drawn as an overlay of a sized box rather than sized directly.
/// A resizable image with `aspectRatio(.fill)` reports an intrinsic width
/// derived from its height, which would make a header image wider than its
/// container and stretch the whole surface; an overlay cannot affect the
/// layout of the box it fills.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIImageView: View {
    let source: String
    let accessibilityText: String?
    let isDecorative: Bool
    let fit: String
    let variant: String
    var mediaURL: @Sendable (URL) -> URL? = RendererServices.default.mediaURL

    @Environment(\.a2uiTheme) private var theme

    // An image without a description is decorative, unless the agent labels it explicitly.
    static func isDecorative(description: String?, label: DynamicValue) -> Bool {
        description == nil && label.isMissing
    }

    var body: some View {
        box
            .overlay(content)
            .clipped()
            .clipShape(shape)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityText ?? ""))
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(isDecorative)
    }

    /// The layout footprint of the image, which never depends on the image itself.
    private var box: some View {
        theme.subtleSurface
            .frame(width: layout.width, height: layout.height)
            .frame(maxWidth: layout.expandsHorizontally ? .infinity : nil)
    }

    private var layout: A2UIImageLayout {
        A2UIImageLayout(variant: variant)
    }

    @ViewBuilder
    private var content: some View {
        if source.isEmpty {
            EmptyView()
        } else if let url = URL(string: source), url.scheme != nil {
            if let allowed = mediaURL(url) {
                A2UIRemoteImage(url: allowed) { image in
                    scaled(image)
                } placeholder: { failed in
                    if !failed {
                        ProgressView()
                    }
                }
            }
        } else {
            // Names without a scheme are resolved from the app's asset catalog.
            scaled(Image(source))
        }
    }

    @ViewBuilder
    private func scaled(_ image: Image) -> some View {
        // `fit` follows CSS object-fit, where `fill` stretches the image.
        switch fit {
        case "none":
            image
        case "contain", "scaleDown":
            image.resizable().aspectRatio(contentMode: .fit)
        case "cover":
            image.resizable().aspectRatio(contentMode: .fill)
        default:
            image.resizable()
        }
    }

    private var shape: AnyShape2 {
        variant == "avatar" ? AnyShape2(Circle()) : AnyShape2(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
    }
}

/// The layout footprint the renderer gives an `Image` for a size variant.
///
/// The footprint deliberately never depends on the loaded image: a resizable
/// image with `aspectRatio(.fill)` derives its intrinsic width from its height,
/// which would let a header image push its surface wider than the screen.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIImageLayout: Equatable {
    /// The fixed width, or `nil` when the image spans its container.
    let width: CGFloat?

    /// The fixed height of the image box.
    let height: CGFloat?

    /// Whether the box grows to fill the available width.
    let expandsHorizontally: Bool

    /// The height of a full-width header band.
    static let headerHeight: CGFloat = 200

    /// Resolves the footprint of an image variant.
    /// Unknown variants fall back to the catalog default, `mediumFeature`.
    init(variant: String) {
        switch variant {
        case "header":
            width = nil
            height = Self.headerHeight
            expandsHorizontally = true
        case "icon":
            width = 24
            height = 24
            expandsHorizontally = false
        case "avatar":
            width = 48
            height = 48
            expandsHorizontally = false
        case "smallFeature":
            width = 72
            height = 72
            expandsHorizontally = false
        case "largeFeature":
            width = 240
            height = 240
            expandsHorizontally = false
        default:
            width = 160
            height = 160
            expandsHorizontally = false
        }
    }
}

/// A type-erased shape, so image clipping can vary by variant on iOS 15.
@available(iOS 15.0, macOS 12.0, *)
private struct AnyShape2: Shape {
    private let pathBuilder: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// Nothing loads until the person plays it: the poster, or a placeholder, covers the player
// until then, the way HTML's `poster` does, so a list of clips doesn't open a connection each.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIMediaPlayerView: View {
    let url: URL?
    let posterUrl: URL?
    let title: String?
    let isAudioOnly: Bool

    @StateObject private var model = A2UIMediaPlayerModel()
    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        Group {
            if let player = model.player {
                #if os(iOS) || os(tvOS) || os(macOS)
                VideoPlayer(player: player)
                    .frame(height: height)
                #else
                cover
                #endif
            } else {
                cover
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let title, isAudioOnly {
                Text(title)
                    .font(theme.caption)
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.controlCornerRadius, style: .continuous))
        .onAppear { model.load(url) }
        .onChange(of: url) { model.load($0) }
        .onDisappear { model.release() }
    }

    private var height: CGFloat {
        isAudioOnly ? 80 : 200
    }

    private var cover: some View {
        ZStack {
            if let posterUrl, !isAudioOnly {
                Color.black
                A2UIRemoteImage(url: posterUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { _ in
                    Color.clear
                }
            } else {
                Rectangle().fill(theme.subtleSurface)
            }
            if url != nil {
                Button {
                    model.play()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: isAudioOnly ? 32 : 44))
                        .foregroundColor(posterUrl == nil || isAudioOnly ? theme.accent : .white)
                        .shadow(radius: posterUrl == nil || isAudioOnly ? 0 : 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Play"))
            } else {
                Image(systemName: isAudioOnly ? "speaker.wave.2" : "play.rectangle")
                    .foregroundColor(theme.secondaryText)
            }
        }
        .frame(height: height)
    }
}

// Keeps the URL of a clip and makes its player only when the person plays it. A bound URL that
// changes lets go of the player, and so does the view leaving the screen.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UIMediaPlayerModel: ObservableObject {
    @Published private(set) var player: AVPlayer?
    private(set) var url: URL?

    func load(_ newUrl: URL?) {
        guard newUrl != url else { return }
        release()
        url = newUrl
    }

    func play() {
        guard let url else { return }
        if player == nil {
            player = AVPlayer(url: url)
        }
        player?.play()
    }

    func release() {
        player?.pause()
        player = nil
    }
}
