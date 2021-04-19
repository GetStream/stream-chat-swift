// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#subclassing-components

import StreamChat
import StreamChatUI
import UIKit

func snippets_ux_customizing_views_subclassing_components() {
    // > import UIKit
    // > import StreamChat
    // > import StreamChatUI

    struct MyExtraData: ExtraDataTypes {
        struct Message: MessageExtraData {
            static let defaultValue = Self(authorWasInGoodMood: true)

            let authorWasInGoodMood: Bool
        }
    }

    // 1. Create custom UI component subclass.
    class MyChatMessageMetadataView: _ChatMessageMetadataView<MyExtraData> {
        // 2. Declare new subview.
        let moodLabel = UILabel()

        // 3. Override `setUpLayout` and add the new subview to the hierarchy.
        override func setUpLayout() {
            // Use base implementation.
            super.setUpLayout()
            // But also extend it with the new subview.
            stack.addArrangedSubview(moodLabel)
        }

        // 4. Override `updateContent` and provide data for the new subview.
        override func updateContent() {
            // Use base implementation.
            super.updateContent()
            // But also provide data for the new subview.
            moodLabel.text = message?.authorWasInGoodMood == true ? "😃" : "😞"
        }
    }
}
