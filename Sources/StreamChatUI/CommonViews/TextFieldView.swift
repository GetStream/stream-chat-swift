//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A custom text field that allows to easily observe the current value.
public class TextFieldView: UITextField {
    private var previousValue: String = ""

    /// A closure to notify that the input text changed.
    public var onTextChanged: ((_ oldValue: String, _ newValue: String) -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    override public func deleteBackward() {
        if text?.isEmpty == true && previousValue.isEmpty {
            onTextChanged?("", "")
        }
        
        super.deleteBackward()
    }

    @objc func textDidChange() {
        let newValue = text ?? ""
        onTextChanged?(previousValue, newValue)
        previousValue = newValue
    }
}
