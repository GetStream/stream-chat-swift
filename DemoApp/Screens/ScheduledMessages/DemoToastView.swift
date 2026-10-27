//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import SwiftUI
import UIKit

/// A short confirmation or error shown at the top of a screen, which fades out by itself.
enum DemoToastView {
    @MainActor static func show(_ text: String, isError: Bool = false, in container: UIView) {
        let host = UIHostingController(rootView: DemoToast(text: text, isError: isError))
        let toast: UIView = host.view
        toast.backgroundColor = .clear
        toast.isUserInteractionEnabled = false
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        container.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 8),
            toast.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16)
        ])
        // An error is longer to read.
        let duration: TimeInterval = isError ? 4 : 2.5
        UIAccessibility.post(notification: .announcement, argument: text)

        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: duration) {
                toast.alpha = 0
            } completion: { _ in
                // The hosting controller is kept until the toast is removed.
                withExtendedLifetime(host) { toast.removeFromSuperview() }
            }
        }
    }
}

private struct DemoToast: View {
    let text: String
    let isError: Bool

    var body: some View {
        let colors = Appearance.default.colorPalette
        Text(text)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(isError ? .white : colors.backgroundCoreApp))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(isError ? colors.accentError : colors.textPrimary), in: RoundedRectangle(cornerRadius: 18))
    }
}
