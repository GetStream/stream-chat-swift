//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell to configure the multiple votes poll feature.
open class PollCreationMultipleVotesFeatureCell: _CollectionViewCell, ThemeProvider {
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

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true

        featureSwitchView.onValueChange = { [weak self] isOn in
            self?.onFeatureEnabledChanged?(isOn)
        }

        maximumVotesSwitchView.textFieldView.onTextChanged = { [weak self] _, newValue in
            self?.currentMaximumVotesText = newValue
        }

        maximumVotesSwitchView.onValueChange = { [weak self] _ in
            self?.maximumVotesSwitchView.textFieldView.inputTextField.text = nil
            self?.currentMaximumVotesText = ""
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
                .height(56)
            maximumVotesSwitchView
                .height(56)
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
        maximumVotesSwitchView.isHidden = !content.feature.isEnabled
        maximumVotesSwitchView.textFieldView.content = .init(
            placeholder: "Maximum votes per person",
            errorText: content.maximumVotesErrorText
        )
    }

    open func setMaximumVotesText(_ text: String) {
        maximumVotesSwitchView.textFieldView.setText(text)
    }

    open func validateMaximumVotesValue(_ newValue: String) {
        let errorText = "Type a number from 1 and 10"
        
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

    open func showMaxVotesError(message: String) {
        maximumVotesSwitchView.textFieldView.content?.errorText = message
        onMaximumVotesErrorTextChanged?(message)
    }

    open func clearMaxVotesError() {
        maximumVotesSwitchView.textFieldView.content?.errorText = nil
        onMaximumVotesErrorTextChanged?(nil)
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
