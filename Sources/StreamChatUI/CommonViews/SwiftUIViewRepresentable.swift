//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Protocol with necessary properties to make `SwiftUIRepresentable` instance
public protocol SwiftUIRepresentable: AnyObject {
    /// Type used for `content` property
    associatedtype Content
    /// Content of a given view
    var content: Content { get set }
}

@available(iOS 13.0, *)
public extension SwiftUIRepresentable where Self: UIView {
    /// Creates `SwiftUIViewRepresentable` instance wrapping the current type that can be used in your SwiftUI view
    /// - Parameters:
    ///     - content: Content of the view. Its value is automatically updated when it's changed
    static func asView(_ content: Content) -> SwiftUIViewRepresentable<Self> {
        SwiftUIViewRepresentable(
            view: self,
            content: content
        )
    }
}

@available(iOS 13.0, *)
/// A concrete type that wraps a view conforming to `SwiftUIRepresentable` and enables using it in SwiftUI via `UIViewRepresentable`
public struct SwiftUIViewRepresentable<View: UIView & SwiftUIRepresentable>: UIViewRepresentable {
    private let view: View.Type
    private let content: View.Content
    
    init(
        view: View.Type,
        content: View.Content
    ) {
        self.view = view
        self.content = content
    }
    
    public func makeUIView(context: Context) -> View {
        view.init()
    }
    
    public func updateUIView(_ uiView: View, context: Context) {
        uiView.content = content
    }
}
