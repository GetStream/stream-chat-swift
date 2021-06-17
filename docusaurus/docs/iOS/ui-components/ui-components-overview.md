---
title: UI Components Overview
---

## ChatChannelListVC

Component responsible for displaying channels and direct messages.

<img src={require("../assets/uisdk-overview-channelist.png").default} width="40%" />

### Types

- [CellActionView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/CellActionView):
View which wraps inside `SwipeActionButton` for leading layout
- [ChatChannelListCollectionViewCell](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListCollectionViewCell):
A `UICollectionViewCell` subclass that shows channel information.
- [ChatChannelListCollectionViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListCollectionViewDelegate)
- [ChatChannelListItemView.SwiftUIWrapper](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListItemViewSwiftUIWrapper):
SwiftUI wrapper of `ChatChannelListItemView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `Components`.
- [ChatChannelListItemView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListItemView):
An `UIView` subclass that shows summary and preview information about a given channel.
- [ChatChannelListVC](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListVC):
A `UIViewController` subclass  that shows list of channels.
- [ChatChannelReadStatusCheckmarkView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelReadStatusCheckmarkView):
A view that shows a read/unread status of the last message in channel.
- [ChatChannelUnreadCountView.SwiftUIWrapper](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelUnreadCountViewSwiftUIWrapper):
SwiftUI wrapper of `ChatChannelUnreadCountView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `Components`.
- [ChatChannelUnreadCountView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelUnreadCountView):
A view that shows a number of unread messages in channel.
- [SwipeableView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/SwipeableView):
A view with swipe functionality that is used as action buttons view for channel list item view.
- [ChatChannelReadStatusCheckmarkView.Status](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelReadStatusCheckmarkViewStatus):
An underlying type for status in the view.
Right now corresponding functionality in LLC is missing and it will likely be replaced with the type from LLC.
-[ChatChannelListItemView.Content](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListItemViewContent):
The content of this view.

### Protocols

- [ChatChannelListItemViewSwiftUIView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListItemViewSwiftUIView)
- [ChatChannelUnreadCountViewSwiftUIView](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelUnreadCountViewSwiftUIView)
- [SwipeableViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/SwipeableViewDelegate): Delegate responsible for easily assigning swipe action buttons to collectionView cells.

## ChatMessageList

Component responsible for displaying conversations, messages with reactions and composer to input text.

<img src={require("../assets/uisdk-overview-messagelist.png").default} width="40%" />

### Types

- [AttachmentViewInjector](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ImagePreviewable):
An object used for injecting attachment views into `ChatMessageContentView`. The injector is also
responsible for updating the content of the injected views.
- [ChatMessageFileAttachmentListView.ItemView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageFileAttachmentListView.ItemView)
- [ChatMessageAttachmentPreviewVC](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageAttachmentPreviewVC)
- [ChatMessageFileAttachmentListView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageFileAttachmentListView):
View which holds one or more file attachment views in a message or composer attachment view
- [ChatMessageGiphyView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageGiphyView)
- [ChatMessageGiphyView.GiphyBadge](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageGiphyView.GiphyBadge)
- [ChatMessageImageGallery.ImagePreview](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageImageGallery.ImagePreview)
- [ChatMessageImageGallery.UploadingOverlay](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageImageGallery.UploadingOverlay)
- [ChatMessageImageGallery](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageImageGallery ):
Gallery view that displays images.
- [ChatMessageInteractiveAttachmentView.ActionButton](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageInteractiveAttachmentView.ActionButton)
- [ChatMessageInteractiveAttachmentView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageInteractiveAttachmentView)
- [ChatMessageLinkPreviewView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageLinkPreviewView)
- [FilesAttachmentViewInjector](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/FilesAttachmentViewInjector)
- [GalleryAttachmentViewInjector](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/GalleryAttachmentViewInjector)
- [GiphyAttachmentViewInjector](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/GiphyAttachmentViewInjector)
- [LinkAttachmentViewInjector](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/LinkAttachmentViewInjector):
View injector for showing link attachments.
- [ChatMessageBubbleView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageBubbleView):
A view that displays a bubble around a message.
- [ChatMessageCollectionViewCell](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageCollectionViewCell):
The cell that displays the message content of a dynamic type and layout.
Once the cell is set up it is expected to be dequeued for messages with
the same content and layout the cell has already been configured with.
- [ChatMessageContentView.SwiftUIWrapper](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageContentView.SwiftUIWrapper):
SwiftUI wrapper of `ChatMessageContentView`.
Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `Components`.
- [ChatMessageContentView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageContentView):
A view that displays the message content.
- [ChatMessageErrorIndicator](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageErrorIndicator):
A view that displays an error indicator inside the message content view.
- [ChatMessageLayoutOptionsResolver](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageLayoutOptionsResolver):
Resolves layout options for the message at given `indexPath`.
- [ChatReactionsBubbleView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatReactionsBubbleView)
- [ChatThreadArrowView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatThreadArrowView)
- [ChatMessageListCollectionView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListCollectionView):
The collection view that provides convenient API for dequeuing `ChatMessageCollectionViewCell` instances
with the provided content view type and layout options.
- [ChatMessageListCollectionViewLayout](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListCollectionViewLayout):
Custom Table View like layout that position item at index path 0-0 on bottom of the list.
- [ChatMessageListKeyboardObserver](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListKeyboardObserver)
- [ChatMessageListScrollOverlayView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListScrollOverlayView):
View that is displayed as top overlay when message list is scrolling
- [ChatMessageListVC](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListVC):
Controller that shows list of messages and composer together in the selected channel.
- [ChatThreadVC](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatThreadVC):
Controller responsible for displaying message thread.
- [ChatMessageDefaultReactionsBubbleView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageDefaultReactionsBubbleView)
- [ChatMessageReactionsBubbleView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsBubbleView)
- [ChatMessageReactionsVC](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsVC)
- [ChatMessageReactionsView.ItemView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsView.ItemView)
- [ChatMessageReactionsView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsView)
- [ScrollToLatestMessageButton](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ScrollToLatestMessageButton):
A Button that is used to indicate unread messages in the Message list.
- [TitleContainerView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/TitleContainerView):
A view that is used as a wrapper for status data in navigationItem's titleView.
- [TypingAnimationView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/TypingAnimationView):
A `UIView` subclass with 3 dots which can be animated with fading out effect.
- [TypingIndicatorView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/TypingIndicatorView):
An `UIView` subclass indicating that user or multiple users are currently typing.
- [ChatThreadArrowView.Direction](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatThreadArrowView.Direction)
- [ChatMessageReactionsBubbleStyle](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsBubbleStyle)
- [ChatMessageInteractiveAttachmentView.ActionButton.Content](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ChatMessageInteractiveAttachmentView.ActionButton.Content)
- [ChatMessageBubbleView.Content](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageBubbleView.Content):
A type describing the content of this view.
- [ChatMessageLayoutOptions](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageLayoutOptions):
Describes the layout of base message content view.
- [ChatMessageListCollectionViewLayout.LayoutItem](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListCollectionViewLayout.LayoutItem)
- [ChatMessageReactionAppearance](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionAppearance):
The default `ReactionAppearanceType` implementation without any additional data
which can be used to provide custom icons for message reaction.
- [ChatMessageReactionData](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionData)
- [ChatMessageReactionsBubbleView.Content](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsBubbleView.Content)
- [ChatMessageReactionsView.ItemView.Content](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsView.ItemView.Content)
- [ChatMessageReactionsView.Content](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionsView.Content)

### Protocols

- [ImagePreviewable](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/ImagePreviewable):
Properties necessary for image to be previewed.
- [FileActionContentViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/FileActionContentViewDelegate):
The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
- [GalleryContentViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/GalleryContentViewDelegate):
The delegate used `GalleryAttachmentViewInjector` to communicate user interactions.
- [GiphyActionContentViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/GiphyActionContentViewDelegate):
The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
- [LinkPreviewViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/LinkPreviewViewDelegate):
The delegate used in `LinkAttachmentViewInjector` to communicate user interactions.
- [ChatMessageContentViewSwiftUIView](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageContentViewSwiftUIView)
- [ChatMessageContentViewDelegate](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageContentViewDelegate):
A protocol for message content delegate responsible for action handling.
- [ChatMessageListCollectionViewDataSource](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessageListCollectionViewDataSource):
Protocol that adds delegate methods specific for `ChatMessageListCollectionView`
- [ChatMessageReactionAppearanceType](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Reactions/ChatMessageReactionAppearanceType):
The type describing message reaction appearance.


## Composer

Component responsible for sending messages, running commands and adding attachments to the prepared message.

<img src={require("../assets/uisdk-overview-composer.png").default} width="40%" />

### Types

- [ComposerVC](../ReferenceDocs/Sources/StreamChatUI/Composer/ComposerVC):
A view controller that manages the composer view.
- [ComposerView](../ReferenceDocs/Sources/StreamChatUI/Composer/ComposerView):
 The composer view that layouts all the components to create a new message.
- [ComposerState](../ReferenceDocs/Sources/StreamChatUI/Composer/ComposerState):
The possible composer states. An Enum is not used so it does not cause
future breaking changes and is possible to extend with new cases.
- [ComposerVC.Content](../ReferenceDocs/Sources/StreamChatUI/Composer/ComposerVC.Content):
The content of the composer.

### Protocols

- [ComposerVCDelegate](../ReferenceDocs/Sources/StreamChatUI/ComposerVCDelegate):
The delegate of the ComposerVC that notifies composer events.


## Navigation

Object responsible for navigation through the Chat. 

### Types

- [NavigationRouter](../ReferenceDocs/Sources/StreamChatUI/Navigation/NavigationRouter):
A root class for all routes in the SDK.
- [ChatChannelListRouter](../ReferenceDocs/Sources/StreamChatUI/Navigation/ChatChannelListRouter):
A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
- [AlertsRouter](../ReferenceDocs/Sources/StreamChatUI/Navigation/AlertsRouter):
A `NavigationRouter` instance responsible for presenting alerts.
- [ChatMessageListRouter](../ReferenceDocs/Sources/StreamChatUI/Navigation/ChatMessageListRouter):
A `NavigationRouter` subclass used for navigating from message-list-based view controllers.

## MessageActionsPopup

Component responsible for showing actions while tap and holding message. You can for example modify transition and actions for the message.

<img src={require("../assets/uisdk-overview-messageactionspopup.png").default} width="40%" />

### Types

- [ChatMessageActionControl](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessageActionControl):
Button for action displayed in `ChatMessageActionsView`.
- [ChatMessageActionsVC](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessageActionsVC):
View controller to show message actions.
- [ChatMessagePopupVC](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessagePopupVC):
`ChatMessagePopupVC` is shown when user long-presses a message.
By default, it has a blurred background, reactions, and actions which are shown for a given message
and with which user can interact.
- [MessageActionsTransitionController](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/MessageActionsTransitionController):
Transitions controller for `ChatMessagePopupVC`.
- [InlineReplyActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/InlineReplyActionItem):
Instance of `ChatMessageActionItem` for inline reply.
- [ThreadReplyActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ThreadReplyActionItem):
Instance of `ChatMessageActionItem` for thread reply.
- [EditActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/EditActionItem):
Instance of `ChatMessageActionItem` for edit message action.
- [CopyActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/CopyActionItem):
Instance of `ChatMessageActionItem` for copy message action.
- [UnblockUserActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/UnblockUserActionItem):
Instance of `ChatMessageActionItem` for unblocking user.
- [BlockUserActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/BlockUserActionItem):
Instance of `ChatMessageActionItem` for blocking user.
- [MuteUserActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/MuteUserActionItem):
Instance of `ChatMessageActionItem` for muting user.
- [UnmuteUserActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/UnmuteUserActionItem):
Instance of `ChatMessageActionItem` for unmuting user.
- [DeleteActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/DeleteActionItem):
Instance of `ChatMessageActionItem` for deleting message action.
- [ResendActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ResendActionItem):
Instance of `ChatMessageActionItem` for resending message action.
- [ChatMessageActionsVC.Delegate](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessageActionsVC.Delegate):
Delegate instance for `ChatMessageActionsVC`.

### Protocols

- [ChatMessageActionItem](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessageActionItem):
Protocol for action item.
Action items are then showed in `ChatMessageActionsView`.
Setup individual item by creating new instance that conforms to this protocol.
- [ChatMessageActionsVCDelegate](../ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/ChatMessageActionsVCDelegate)
