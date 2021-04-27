// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#injecting-custom-subclass

import StreamChatUI
import UIKit

private class InteractiveAttachmentView: ChatMessageInteractiveAttachmentView {}

func snippets_ux_customizing_views_injecting_custom_subclass() {
    // > import UIKit
    // > import StreamChatUI

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.

        Components.default
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .interactiveAttachmentView = InteractiveAttachmentView.self

        return true
    }
}
