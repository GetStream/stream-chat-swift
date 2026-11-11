import Foundation

@available(iOS 15.0, macOS 12.0, *)
enum BlockNode: Hashable {
  case blockquote(children: [BlockNode])
  case bulletedList(isTight: Bool, items: [RawListItem])
  case numberedList(isTight: Bool, start: Int, items: [RawListItem])
  case taskList(isTight: Bool, items: [RawTaskListItem])
  case codeBlock(fenceInfo: String?, content: String)
  case htmlBlock(content: String)
  case paragraph(content: [InlineNode])
  case heading(level: Int, content: [InlineNode])
  case table(columnAlignments: [RawTableColumnAlignment], rows: [RawTableRow])
  case thematicBreak
}

@available(iOS 15.0, macOS 12.0, *)
extension BlockNode {
  var children: [BlockNode] {
    switch self {
    case .blockquote(let children):
      return children
    case .bulletedList(_, let items):
      return items.map(\.children).flatMap { $0 }
    case .numberedList(_, _, let items):
      return items.map(\.children).flatMap { $0 }
    case .taskList(_, let items):
      return items.map(\.children).flatMap { $0 }
    default:
      return []
    }
  }

  var isParagraph: Bool {
    guard case .paragraph = self else { return false }
    return true
  }
}

@available(iOS 15.0, macOS 12.0, *)
struct RawListItem: Hashable {
  let children: [BlockNode]
}

@available(iOS 15.0, macOS 12.0, *)
struct RawTaskListItem: Hashable {
  let isCompleted: Bool
  let children: [BlockNode]
}

@available(iOS 15.0, macOS 12.0, *)
enum RawTableColumnAlignment: Character {
  case none = "\0"
  case left = "l"
  case center = "c"
  case right = "r"
}

@available(iOS 15.0, macOS 12.0, *)
struct RawTableRow: Hashable {
  let cells: [RawTableCell]
}

@available(iOS 15.0, macOS 12.0, *)
struct RawTableCell: Hashable {
  let content: [InlineNode]
}
