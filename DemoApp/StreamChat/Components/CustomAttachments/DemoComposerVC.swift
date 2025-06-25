//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions

        let isDemoAppLocationsEnabled = AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled
        let isLocationEnabled = channelController?.channel?.config.sharedLocationsEnabled == true
        if isLocationEnabled && isDemoAppLocationsEnabled && content.isInsideThread == false {
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
}

class DemoInputTextView: InputTextView {
    override func setUpAppearance() {
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 8
        font = appearance.fonts.body
        textColor = appearance.colorPalette.text
        textAlignment = .natural
        adjustsFontForContentSizeCategory = true

        // Calling the layoutManager in debug builds loads a dynamic lib
        // Which causes a big performance penalty. So in our Demo App
        // we avoid the performance penalty, unless it is using the our internal scheme.
        if StreamRuntimeCheck.isStreamInternalConfiguration {
            layoutManager.allowsNonContiguousLayout = false
        }

        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
        placeholderLabel.adjustsFontSizeToFitWidth = true
    }
}
