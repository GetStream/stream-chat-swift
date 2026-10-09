//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    var editingScheduledMessage: ScheduledMessage?
    var editingScheduledContent: DemoScheduledMessageContent?
    var componentsBeforeScheduledEditing: Components?
    var isSubmittingScheduledMessage = false

    // Created on first use, once the channel controller is set.
    lazy var scheduledMessageListController: ScheduledMessageListController? = {
        guard AppConfig.shared.demoAppConfig.isScheduledMessagesEnabled else { return nil }
        let controller = channelController?.client.scheduledMessageListController()
        controller?.delegate = self
        return controller
    }()

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

        scheduledEditingBannerView.isHidden = true
        scheduledEditingBannerView.onDismiss = { [weak self] in
            self?.endScheduledMessageEditing()
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        attachScheduledBanners()
    }

    override func showSuggestions() {
        super.showSuggestions()

        updateScheduledMessagesBanner()
    }

    override func dismissSuggestions() {
        super.dismissSuggestions()

        updateScheduledMessagesBanner()
    }

    override func updateContent() {
        super.updateContent()

        updateScheduledMessagesBanner()
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
