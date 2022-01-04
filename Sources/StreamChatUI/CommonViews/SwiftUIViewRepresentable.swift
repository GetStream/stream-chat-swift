//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI

/// Protocol with necessary properties to make `SwiftUIRepresentable` instance
public protocol SwiftUIRepresentable: AnyObject {
    /// Type used for `content` property
    associatedtype ViewContent
    /// Content of a given view
    var content: ViewContent { get set }
}

@available(iOS 13.0, *)
public extension SwiftUIRepresentable where Self: UIView {
    /// Creates `SwiftUIViewRepresentable` instance wrapping the current type that can be used in your SwiftUI view
    /// - Parameters:
    ///     - content: Content of the view. Its value is automatically updated when it's changed
    static func asView(_ content: ViewContent) -> SwiftUIViewRepresentable<Self> {
        SwiftUIViewRepresentable(
            view: self,
            content: content
        )
    }
}

@available(iOS 13.0, *)
public extension SwiftUIRepresentable where Self: UIViewController {
    /// Creates `SwiftUIViewControllerRepresentable` instance wrapping the current type that can be used in your SwiftUI view
    /// - Parameters:
    ///     - content: Content of the view controller. Its value is automatically updated when it's changed
    static func asView(_ content: ViewContent) -> SwiftUIViewControllerRepresentable<Self> {
        SwiftUIViewControllerRepresentable(
            viewController: self,
            content: content
        )
    }
}

@available(iOS 13.0, *)
/// A concrete type that wraps a view conforming to `SwiftUIRepresentable` and enables using it in SwiftUI via `UIViewRepresentable`
public struct SwiftUIViewRepresentable<View: UIView & SwiftUIRepresentable>: UIViewRepresentable {
    private let view: View.Type
    private let content: View.ViewContent
    
    init(
        view: View.Type,
        content: View.ViewContent
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

@available(iOS 13.0, *)
/// A concrete type that wraps a view conforming to `SwiftUIRepresentable` and enables using it in SwiftUI via `UIViewControllerRepresentable`
public struct SwiftUIViewControllerRepresentable<
    ViewController: UIViewController &
        SwiftUIRepresentable
>: UIViewControllerRepresentable {
    private let viewController: ViewController.Type
    private let content: ViewController.ViewContent
    
    init(
        viewController: ViewController.Type,
        content: ViewController.ViewContent
    ) {
        self.viewController = viewController
        self.content = content
    }
    
    public func makeUIViewController(context: Context) -> ViewController {
        let controller = ViewController()
        controller.content = content
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
