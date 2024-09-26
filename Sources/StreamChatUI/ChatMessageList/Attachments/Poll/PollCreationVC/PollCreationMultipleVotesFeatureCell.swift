//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell to configure the multiple votes poll feature.
open class PollCreationMultipleVotesFeatureCell: _CollectionViewCell, ThemeProvider, UITextFieldDelegate {
    public struct Content {
        public var feature: MultipleVotesPollFeature
        public var maximumVotesErrorText: String?

        public init(
            feature: MultipleVotesPollFeature,
            maximumVotesErrorText: String?
        ) {
            self.feature = feature
            self.maximumVotesErrorText = maximumVotesErrorText
        }
    }
    
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The main container that holds the subviews.
    open private(set) lazy var container = VContainer(spacing: 4)

    /// A view that displays the feature name and the switch to enable/disable the feature.
    open private(set) lazy var featureSwitchView = components
        .pollCreationFeatureSwitchView.init()
        .withoutAutoresizingMaskConstraints

    /// A view to configure the maximum votes per user.
    open private(set) lazy var maximumVotesSwitchView = PollCreationMaximumVotesSwitchView()
        .withoutAutoresizingMaskConstraints

    private var currentMaximumVotesText: String = "" {
        didSet {
            validateMaximumVotesValue(currentMaximumVotesText)
            onMaximumVotesTextChanged?(currentMaximumVotesText)
        }
    }

    /// A closure that is triggered whenever the feature is enabled or disabled.
    public var onFeatureEnabledChanged: ((Bool) -> Void)?

    /// A closure that is triggered whenever the maximum votes value changes.
    public var onMaximumVotesValueChanged: ((Int?) -> Void)?

    /// A closure that is triggered whenever the maximum votes text changes.
    public var onMaximumVotesTextChanged: ((String) -> Void)?

    /// A closure that is triggered whenever the validation of the maximum votes changes.
    public var onMaximumVotesErrorTextChanged: ((String?) -> Void)?

    /// The text for the maximum votes input placeholder.
    open var maximumVotesPlaceholderText: String {
        L10n.Polls.Creation.maximumVotesPlaceholder
    }

    /// The error text for the maximum votes input.
    open var maximumVotesErrorText: String {
        L10n.Polls.Creation.maximumVotesError
    }

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true

        maximumVotesSwitchView.textFieldView.inputTextField.delegate = self

        featureSwitchView.onValueChange = { [weak self] isOn in
            self?.onFeatureEnabledChanged?(isOn)
            self?.resetMaximumVotesInput()
            self?.clearMaxVotesError()
        }

        maximumVotesSwitchView.textFieldView.onTextChanged = { [weak self] _, newValue in
            self?.currentMaximumVotesText = newValue
        }

        maximumVotesSwitchView.onValueChange = { [weak self] _ in
            self?.resetMaximumVotesInput()
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
            featureSwitchView
                .height(PollCreationVC.pollCreationInputViewHeight)
            maximumVotesSwitchView
                .height(PollCreationVC.pollCreationInputViewHeight)
        }
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

        featureSwitchView.featureNameLabel.text = content.feature.name
        featureSwitchView.switchView.isOn = content.feature.isEnabled
        maximumVotesSwitchView.isHidden = content.feature.maxVotesConfig == nil ? true : !content.feature.isEnabled
        maximumVotesSwitchView.switchView.isOn = content.feature.maxVotesConfig?.isEnabled ?? false
        maximumVotesSwitchView.textFieldView.content = .init(
            placeholder: maximumVotesPlaceholderText,
            errorText: content.maximumVotesErrorText
        )
    }

    /// Sets the maximum votes in the maximum votes switch view.
    open func setMaximumVotesText(_ text: String) {
        maximumVotesSwitchView.textFieldView.setText(text)
    }

    /// Validates the maximum votes text and shows an error if it is not valid.
    open func validateMaximumVotesValue(_ newValue: String) {
        let errorText = maximumVotesErrorText

        if newValue.isEmpty && maximumVotesSwitchView.switchView.isOn {
            showMaxVotesError(message: errorText)
            return
        }

        if newValue.isEmpty {
            clearMaxVotesError()
            maximumVotesSwitchView.switchView.setOn(false, animated: true)
            return
        }

        maximumVotesSwitchView.switchView.setOn(true, animated: true)

        guard let value = Int(newValue), value >= 1 && value <= 10 else {
            showMaxVotesError(message: errorText)
            return
        }

        clearMaxVotesError()
        onMaximumVotesValueChanged?(value)
    }

    /// Shows an error in the maximum votes switch view.
    open func showMaxVotesError(message: String) {
        maximumVotesSwitchView.textFieldView.content?.errorText = message
        onMaximumVotesErrorTextChanged?(message)
    }

    /// Clears the error of the maximum votes switch view.
    open func clearMaxVotesError() {
        maximumVotesSwitchView.textFieldView.content?.errorText = nil
        onMaximumVotesErrorTextChanged?(nil)
    }

    open func resetMaximumVotesInput() {
        maximumVotesSwitchView.textFieldView.inputTextField.text = nil
        currentMaximumVotesText = ""
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

open class PollCreationMaximumVotesSwitchView: _View, ThemeProvider {
    /// A text field that supports showing validator errors.
    open private(set) lazy var textFieldView = components
        .pollCreationTextFieldView.init()
        .withoutAutoresizingMaskConstraints

    /// A view to switch on or off. Used to enable or disable poll features.
    open private(set) lazy var switchView = UISwitch()
        .withoutAutoresizingMaskConstraints

    /// A closure that is triggered whenever the switch value changes.
    public var onValueChange: ((Bool) -> Void)?

    override open func setUp() {
        super.setUp()

        textFieldView.inputTextField.keyboardType = .numberPad
        switchView.addTarget(self, action: #selector(switchChangedValue(sender:)), for: .valueChanged)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(spacing: 4, alignment: .center) {
            textFieldView
            switchView
        }
        .embed(in: self)
    }

    @objc open func switchChangedValue(sender: Any?) {
        onValueChange?(switchView.isOn)
    }
}
