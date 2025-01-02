//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

/// A text field used by the poll creation form to input text and show validation errors.
open class PollCreationTextFieldView: _View, ThemeProvider {
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

    /// A label that displays validation errors.
    open private(set) lazy var errorLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    /// A view that displays an editable text.
    open private(set) lazy var inputTextField = TextFieldView()
        .withoutAutoresizingMaskConstraints

    /// A closure to notify that the input text changed.
    public var onTextChanged: ((_ oldValue: String, _ newValue: String) -> Void)?

    override open func setUp() {
        super.setUp()

        inputTextField.onTextChanged = { [weak self] oldValue, newValue in
            self?.onTextChanged?(oldValue, newValue)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        inputTextField.font = appearance.fonts.body
        inputTextField.textColor = appearance.colorPalette.text
        errorLabel.font = appearance.fonts.caption1
        errorLabel.textColor = appearance.colorPalette.validationError
    }

    override open func setUpLayout() {
        super.setUpLayout()

        VContainer(spacing: 2) {
            errorLabel
            inputTextField
        }.embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        inputTextField.placeholder = content?.placeholder
        errorLabel.text = content?.errorText

        if errorLabel.isHidden && content?.errorText != nil {
            showError()
        } else if !errorLabel.isHidden && content?.errorText == nil {
            hideError()
        }
    }

    open func setText(_ text: String) {
        inputTextField.text = text
    }

    open func showError() {
        errorLabel.isHidden = false
        errorLabel.alpha = 0
        errorLabel.frame.origin.y = 8
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.errorLabel.alpha = 1
            self?.errorLabel.frame.origin.y = 0
        }
    }

    open func hideError() {
        errorLabel.alpha = 1
        errorLabel.frame.origin.y = 0
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.errorLabel.isHidden = true
                self?.errorLabel.alpha = 0
                self?.errorLabel.frame.origin.y = -8
                self?.layoutIfNeeded()
            }
        )
    }
}
