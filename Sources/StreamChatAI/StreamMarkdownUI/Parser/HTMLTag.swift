import Foundation

@available(iOS 15.0, macOS 12.0, *)
struct HTMLTag {
  let name: String
}

@available(iOS 15.0, macOS 12.0, *)
extension HTMLTag {
  private enum Constants {
    static let tagExpression = try! NSRegularExpression(pattern: "<\\/?([a-zA-Z0-9]+)[^>]*>")
  }

  init?(_ description: String) {
    guard
      let match = Constants.tagExpression.firstMatch(
        in: description,
        range: NSRange(description.startIndex..., in: description)
      ),
      let nameRange = Range(match.range(at: 1), in: description)
    else {
      return nil
    }

    self.name = String(description[nameRange])
  }
}
