//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for the poll creation form that displays a text field and supports showing validator errors.
open class PollCreationTextFieldCell: _TableViewCell, ThemeProvider {
    public struct Content {
        /// The initial value of the text field.
        public var initialText: String?
        /// The placeholder of the text field.
        public var placeholder: String
        /// The error text in case there are validator errors.
        public var errorText: String?

        public init(initialText: String?, placeholder: String, errorText: String?) {
            self.initialText = initialText
            self.placeholder = placeholder
            self.errorText = errorText
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A text field that supports showing validator errors.
    open private(set) lazy var textFieldView = PollCreationTextFieldView()
        .withoutAutoresizingMaskConstraints

    override open func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        shouldIndentWhileEditing = false
    }

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer {
            textFieldView
        }.embedToMargins(in: contentView)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }
        
        textFieldView.content = .init(
            initialText: content.initialText,
            placeholder: content.placeholder,
            errorText: content.errorText
        )
    }
}
