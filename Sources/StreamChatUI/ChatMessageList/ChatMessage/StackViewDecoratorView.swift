//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

/// The decorator view that is used to stack multiple decorators.
class StackViewDecoratorView: ChatMessageDecorationView {
    /// The container for the stacked views.
    private(set) lazy var container = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "stackViewDecoratorContainer")

    var content: [ChatMessageDecorationView] = []

    override open func setUpLayout() {
        super.setUpLayout()
        embed(container, insets: .init(top: 0, leading: 0, bottom: 0, trailing: 0))
        container.axis = .vertical
        container.spacing = 8
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = nil
    }

    override open func updateContent() {
        super.updateContent()

        guard content != container.arrangedSubviews else { return }

        container.removeAllArrangedSubviews()
        content.forEach(container.addArrangedSubview)
    }
}
