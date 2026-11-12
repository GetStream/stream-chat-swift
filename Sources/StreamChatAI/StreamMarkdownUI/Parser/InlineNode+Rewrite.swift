import Foundation

@available(iOS 15.0, macOS 12.0, *)
extension Sequence where Element == InlineNode {
  func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [InlineNode] {
    try self.flatMap { try $0.rewrite(r) }
  }
}

@available(iOS 15.0, macOS 12.0, *)
extension InlineNode {
  func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [InlineNode] {
    var inline = self
    inline.children = try self.children.rewrite(r)
    return try r(inline)
  }
}
