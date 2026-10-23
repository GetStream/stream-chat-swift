
import SwiftUI

/// The default inline image provider, which loads images from the network.
struct DefaultInlineImageProvider: InlineImageProvider {
  func image(with url: URL, label: String) async throws -> Image {
    try await Image(
      DefaultNetworkImageLoader.shared.image(from: url),
      scale: 1,
      label: Text(label)
    )
  }
}

extension InlineImageProvider where Self == DefaultInlineImageProvider {
  /// The default inline image provider, which loads images from the network.
  ///
  /// Use the `markdownInlineImageProvider(_:)` modifier to configure
  /// this image provider for a view hierarchy.
  static var `default`: Self {
    .init()
  }
}
