//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for adding an option to the poll.
open class PollCreationOptionCell: _CollectionViewCell, ThemeProvider, UITextFieldDelegate {
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
    open private(set) lazy var container = HContainer(alignment: .center)

    /// A text field that supports showing validation errors.
    open private(set) lazy var textFieldView = components
        .pollCreationTextFieldView.init()
        .withoutAutoresizingMaskConstraints

    /// The image view that shows the reorder icon.
    open private(set) lazy var reorderImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A closure to notify that the input text changed.
    public var onTextChanged: ((_ oldValue: String, _ newValue: String) -> Void)?

    /// A closure to notify that the return key was pressed.
    public var onReturnKeyPressed: (() -> Bool)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        textFieldView.hideError()
    }

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
        textFieldView.inputTextField.delegate = self
        textFieldView.inputTextField.returnKeyType = .next
        textFieldView.inputTextField.enablesReturnKeyAutomatically = true
        textFieldView.onTextChanged = { [weak self] oldValue, newValue in
            self?.onTextChanged?(oldValue, newValue)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        container.backgroundColor = appearance.colorPalette.background1
        container.layer.cornerRadius = 16
        reorderImageView.image = appearance.images.pollReorderIcon
        reorderImageView.tintColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.views {
            textFieldView
            reorderImageView
                .width(28)
                .height(22)
        }
        .height(PollCreationVC.pollCreationInputViewHeight)
        .padding(leading: 12, trailing: 12)
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

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturnKeyPressed?() ?? false
    }
}
