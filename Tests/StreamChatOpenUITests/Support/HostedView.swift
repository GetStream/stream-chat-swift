//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

// Shows a view in a window, so its onAppear, onChange and task modifiers run.
@MainActor
final class HostedView<Content: View> {
    let window: UIWindow
    let controller: UIHostingController<Content>

    init(_ content: Content, size: CGSize = CGSize(width: 390, height: 844)) {
        window = UIWindow(frame: CGRect(origin: .zero, size: size))
        controller = UIHostingController(rootView: content)
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }

    func settle() async {
        for _ in 0..<5 {
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }
}
#endif
