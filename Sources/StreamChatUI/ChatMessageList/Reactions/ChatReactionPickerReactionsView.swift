//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

/// The view that shows the list of reaction toggles/buttons.
/// // TODO: Depcreated
open class ChatReactionPickerReactionsView: ChatMessageReactionsView {
    override public var reactionItemView: ChatMessageReactionItemView.Type {
        components.reactionPickerReactionItemView
    }
}
