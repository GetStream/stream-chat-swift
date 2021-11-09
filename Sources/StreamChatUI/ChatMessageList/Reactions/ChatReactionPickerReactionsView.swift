//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

/// The view that shows the list of reaction toggles/buttons.
open class ChatReactionPickerReactionsView: ChatMessageReactionsView {
    override public var reactionItemView: ChatMessageReactionItemView.Type {
        components.reactionPickerReactionItemView
    }
}
