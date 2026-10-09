//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    var editingScheduledMessage: DemoScheduledMessage?
    var componentsBeforeScheduledEditing: Components?
    var editingScheduledMessageObservation: AnyCancellable?
    var isSubmittingScheduledMessage = false
    var scheduledMessagesObservation: AnyCancellable?

    lazy var scheduledMessagesBannerView = DemoComposerBannerView()
    lazy var scheduledEditingBannerView = DemoComposerBannerView()

    override func setUp() {
        super.setUp()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(sendButtonLongPressed(_:)))
        composerView.sendButton.addGestureRecognizer(longPress)

        scheduledMessagesBannerView.isHidden = true
        scheduledMessagesBannerView.onTap = { [weak self] in
            (self?.tabBarController as? DemoAppTabBarController)?.showScheduledMessages()
        }
        scheduledMessagesObservation = DemoScheduledMessagesService.shared.$scheduledMessages
            .sink { [weak self] messages in
                self?.updateScheduledMessagesBanner(with: messages)
            }

        scheduledEditingBannerView.isHidden = true
        scheduledEditingBannerView.onDismiss = { [weak self] in
            self?.endScheduledMessageEditing()
        }
    }

    override func setUpLayout() {
        super.setUpLayout()

        composerView.container.insertArrangedSubview(scheduledEditingBannerView, at: 0)
        composerView.container.insertArrangedSubview(scheduledMessagesBannerView, at: 0)
    }

    override func updateContent() {
        super.updateContent()

        updateScheduledMessagesBanner(with: DemoScheduledMessagesService.shared.scheduledMessages)
    }

    override func viewWillDisappear(_ animated: Bool) {
        saveEditedScheduledMessageIfNeeded()

        super.viewWillDisappear(animated)
    }

    override func publishMessage(sender: UIButton) {
        if editingScheduledMessage != nil {
            confirmSendingEditedScheduledMessage()
        } else {
            super.publishMessage(sender: sender)
        }
    }

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions

        let isLocationEnabled = channelController?.channel?.config.sharedLocationsEnabled == true
        if isLocationEnabled && content.isInsideThread == false {
            let locationAction = UIAlertAction(
                title: "Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.presentLocationSelection()
                }
            )
            actions.append(locationAction)
        }

        return actions
    }

    func presentLocationSelection() {
        guard let channelController = channelController else { return }
        
        let locationSelectionVC = LocationSelectionViewController(channelController: channelController)
        let navigationController = UINavigationController(rootViewController: locationSelectionVC)
        
        present(navigationController, animated: true)
    }

    @objc private func sendButtonLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }

        if editingScheduledMessage != nil {
            presentRescheduleSheet()
        } else {
            presentScheduleSheet()
        }
    }
}

class DemoInputTextView: InputTextView {
    override func setUpAppearance() {
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 8
        font = appearance.fonts.body
        textColor = appearance.colorPalette.textPrimary
        textAlignment = .natural
        adjustsFontForContentSizeCategory = true

        // Calling the layoutManager in debug builds loads a dynamic lib
        // Which causes a big performance penalty. So in our Demo App
        // we avoid the performance penalty, unless it is using the our internal scheme.
        if StreamRuntimeCheck.isStreamInternalConfiguration {
            layoutManager.allowsNonContiguousLayout = false
        }

        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.textSecondary
        placeholderLabel.adjustsFontSizeToFitWidth = true
    }
}
