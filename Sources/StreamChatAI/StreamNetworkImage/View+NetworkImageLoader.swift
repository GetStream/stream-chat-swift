import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension View {
  /// Sets the image loader for network images within this view.
  func networkImageLoader<T: NetworkImageLoader>(_ networkImageLoader: T) -> some View {
    environment(\.networkImageLoader, networkImageLoader)
  }
}

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
  var networkImageLoader: NetworkImageLoader {
    get { self[NetworkImageLoaderKey.self] }
    set { self[NetworkImageLoaderKey.self] = newValue }
  }
}

@available(iOS 15.0, macOS 12.0, *)
private struct NetworkImageLoaderKey: EnvironmentKey {
  static let defaultValue: NetworkImageLoader = .default
}
