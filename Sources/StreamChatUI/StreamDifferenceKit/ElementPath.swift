/// Represents the path to a specific element in a tree of nested collections.
///
/// - Note: `Foundation.IndexPath` is disadvantageous in performance.
struct ElementPath: Hashable {
    /// The element index (or offset) of this path.
    var element: Int
    /// The section index (or offset) of this path.
    var section: Int

    /// Creates a new `ElementPath`.
    ///
    /// - Parameters:
    ///   - element: The element index (or offset).
    ///   - section: The section index (or offset).
    init(element: Int, section: Int) {
        self.element = element
        self.section = section
    }
}

extension ElementPath: CustomDebugStringConvertible {
    var debugDescription: String {
        "[element: \(element), section: \(section)]"
    }
}
