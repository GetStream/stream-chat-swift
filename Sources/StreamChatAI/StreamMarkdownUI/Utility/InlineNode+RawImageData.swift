import Foundation

@available(iOS 15.0, macOS 12.0, *)
struct RawImageData: Hashable {
  var source: String
  var alt: String
  var destination: String?
}

@available(iOS 15.0, macOS 12.0, *)
extension InlineNode {
  var imageData: RawImageData? {
    switch self {
    case .image(let source, let children):
      return .init(source: source, alt: children.renderPlainText())
    case .link(let destination, let children) where children.count == 1:
      guard var imageData = children.first?.imageData else { return nil }
      imageData.destination = destination
      return imageData
    default:
      return nil
    }
  }
}
