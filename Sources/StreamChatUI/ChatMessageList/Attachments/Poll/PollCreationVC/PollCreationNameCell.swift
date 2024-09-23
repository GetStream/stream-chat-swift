//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for editing the poll's name.
open class PollCreationNameCell: _CollectionViewCell, ThemeProvider {
    public struct Content {
        /// The placeholder of the text field.
        public var placeholder: String
        /// The error text in case there are validator errors.
        public var errorText: String?

        public init(placeholder: String, errorText: String?) {
            self.placeholder = placeholder
            self.errorText = errorText
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The main container that holds the subviews.
    open private(set) lazy var container = HContainer()

    /// A text field that supports showing validation errors.
    open private(set) lazy var textFieldView = components
        .pollCreationTextFieldView.init()
        .withoutAutoresizingMaskConstraints

    /// A closure to notify that the input text changed.
    public var onTextChanged: ((_ oldValue: String, _ newValue: String) -> Void)?

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
        textFieldView.onTextChanged = { [weak self] oldValue, newValue in
            self?.onTextChanged?(oldValue, newValue)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        container.backgroundColor = appearance.colorPalette.background1
        container.layer.cornerRadius = 16
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.views {
            textFieldView
        }
        .height(56)
        .layout {
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        }
        .embed(in: self, insets: .init(top: 6, leading: 12, bottom: 6, trailing: 12))
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        textFieldView.content = .init(
            placeholder: content.placeholder,
            errorText: content.errorText
        )
    }

    open func setText(_ text: String) {
        textFieldView.inputTextField.text = text
    }
}
