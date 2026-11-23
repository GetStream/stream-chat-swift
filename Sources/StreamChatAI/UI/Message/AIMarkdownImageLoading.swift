//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Which images in the agent's Markdown replies load.
///
/// A model writes the replies, so an image can point at any address, and loading it sends a
/// request there. So no image loads by default. Each one shows as a link to its address instead,
/// which opens only when tapped.
///
/// ```swift
/// AIConversationView(conversation: conversation)
///     .aiMarkdownImageLoading(.hosts(["images.example.com"]))
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct AIMarkdownImageLoading: Sendable {
    let shouldLoad: @Sendable (URL) -> Bool

    /// No image loads: each shows as a link to its address. The default.
    public static let never = AIMarkdownImageLoading { _ in false }

    /// Loads the images served over HTTPS by these hosts, such as `images.example.com`. Images
    /// from other hosts show as links.
    public static func hosts(_ hosts: Set<String>) -> Self {
        let hosts = Set(hosts.map { $0.lowercased() })
        return AIMarkdownImageLoading { url in
            url.host.map { hosts.contains($0.lowercased()) } ?? false
        }
    }

    /// Loads the images served over HTTPS whose address `shouldLoad` accepts. Other images show
    /// as links.
    public static func custom(_ shouldLoad: @escaping @Sendable (URL) -> Bool) -> Self {
        AIMarkdownImageLoading(shouldLoad: shouldLoad)
    }

    func loads(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host != nil && shouldLoad(url)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension View {
    /// Sets which images load in the agent's Markdown replies shown in this view.
    public func aiMarkdownImageLoading(_ loading: AIMarkdownImageLoading) -> some View {
        environment(\.aiMarkdownImageLoading, loading)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
    var aiMarkdownImageLoading: AIMarkdownImageLoading {
        get { self[AIMarkdownImageLoadingKey.self] }
        set { self[AIMarkdownImageLoadingKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct AIMarkdownImageLoadingKey: EnvironmentKey {
    static let defaultValue = AIMarkdownImageLoading.never
}

@available(iOS 15.0, macOS 12.0, *)
extension MarkdownContent {
    // The content with each image that `loading` doesn't load replaced by a link to its address,
    // so that nothing in a reply is fetched before the person taps it.
    func loadingImages(_ loading: AIMarkdownImageLoading) -> MarkdownContent {
        MarkdownContent(blocks: blocks.rewrite { (inline: InlineNode) -> [InlineNode] in
            inline.loadingImages(loading)
        })
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension InlineNode {
    func loadingImages(_ loading: AIMarkdownImageLoading) -> [InlineNode] {
        switch self {
        case let .image(source, children):
            let url = URL(string: source)
            if let url, loading.loads(url) {
                return [self]
            }
            let description = children.collect { inline -> [String] in
                switch inline {
                case let .text(text), let .code(text):
                    return [text]
                default:
                    return []
                }
            }.joined()
            let label = L10n.StreamingMessage.imageLink(description.isEmpty ? url?.host ?? source : description)
            guard let scheme = url?.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
                return [.text(label)]
            }
            return [.link(destination: source, children: [.text(label)])]
        case let .link(destination, children):
            // A link can't hold another, such as an image in it that became one.
            return [.link(destination: destination, children: children.flatMap(\.unlinked))]
        default:
            return [self]
        }
    }

    var unlinked: [InlineNode] {
        if case let .link(_, children) = self {
            return children
        }
        return [self]
    }
}
