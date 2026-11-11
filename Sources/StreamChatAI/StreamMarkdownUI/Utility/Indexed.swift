import Foundation

@available(iOS 15.0, macOS 12.0, *)
struct Indexed<Value> {
  let index: Int
  let value: Value
}

@available(iOS 15.0, macOS 12.0, *)
extension Indexed: Equatable where Value: Equatable {}
@available(iOS 15.0, macOS 12.0, *)
extension Indexed: Hashable where Value: Hashable {}

@available(iOS 15.0, macOS 12.0, *)
extension Sequence {
  func indexed() -> [Indexed<Element>] {
    zip(0..., self).map { index, value in
      Indexed(index: index, value: value)
    }
  }
}
