import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct ThematicBreakView: View {
  @Environment(\.theme.thematicBreak) private var thematicBreak

  var body: some View {
    self.thematicBreak.makeBody(configuration: ())
  }
}
