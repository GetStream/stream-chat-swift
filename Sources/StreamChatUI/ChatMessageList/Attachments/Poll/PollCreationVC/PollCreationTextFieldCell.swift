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

    /// A boolean value indicating if the cell can be re-ordered.
    ///
    /// This is used to control whether an additional spacing should be added
    /// to accommodate the native reorder control of the table view.
    public var isReorderingSupported = true

    /// The main container that holds the subviews.
    open private(set) lazy var container = HContainer()

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
            if isReorderingSupported {
                Spacer().width(28)
            }
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
            initialText: content.initialText,
            placeholder: content.placeholder,
            errorText: content.errorText
        )
    }
}
