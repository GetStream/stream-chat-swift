import Foundation

@available(iOS 15.0, macOS 12.0, *)
struct ImageSource: Hashable, Sendable {
  let url: URL
  let scale: CGFloat
}
