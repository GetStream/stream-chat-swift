import SwiftUI

/// The state of a network image loading operation.
@available(iOS 15.0, macOS 12.0, *)
enum NetworkImageState: Equatable {
  /// No image is loaded.
  case empty

  /// An image successfully loaded.
  case success(image: Image, idealSize: CGSize)

  /// An image failed to load.
  case failure

  /// The loaded image, if any.
  var image: Image? {
    guard case .success(let image, _) = self else {
      return nil
    }
    return image
  }
}
