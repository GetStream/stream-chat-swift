import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
  var listLevel: Int {
    get { self[ListLevelKey.self] }
    set { self[ListLevelKey.self] = newValue }
  }

  var tightSpacingEnabled: Bool {
    get { self[TightSpacingEnabledKey.self] }
    set { self[TightSpacingEnabledKey.self] = newValue }
  }
}

@available(iOS 15.0, macOS 12.0, *)
private struct ListLevelKey: EnvironmentKey {
  static let defaultValue = 0
}

@available(iOS 15.0, macOS 12.0, *)
private struct TightSpacingEnabledKey: EnvironmentKey {
  static let defaultValue = false
}
