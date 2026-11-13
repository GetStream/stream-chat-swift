import Foundation

@available(iOS 15.0, macOS 12.0, *)
extension Sequence where Element == InlineNode {
  func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.flatMap { try $0.collect(c) }
  }
}

@available(iOS 15.0, macOS 12.0, *)
extension InlineNode {
  func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.children.collect(c) + c(self)
  }
}
