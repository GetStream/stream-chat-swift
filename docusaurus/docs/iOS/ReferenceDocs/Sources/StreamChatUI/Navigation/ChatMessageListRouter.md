---
id: chatmessagelistrouter 
title: ChatMessageListRouter
slug: /ReferenceDocs/Sources/StreamChatUI/Navigation/chatmessagelistrouter
---

A `NavigationRouter` subclass used for navigating from message-list-based view controllers.

``` swift
open class _ChatMessageListRouter<ExtraData: ExtraDataTypes>:
    // We use UIViewController here because the router is used for both
    // the channel and thread message lists.
    NavigationRouter<UIViewController>,
    UIViewControllerTransitioningDelegate,
    ComponentsProvider
```

## Inheritance

`// We use UIViewController here because the router is used for both // the channel and thread message lists. NavigationRouter<UIViewController>`, [`ComponentsProvider`](../Utils/ComponentsProvider), `UIViewControllerTransitioningDelegate`

## Properties

### `messagePopUpTransitionController`

The transition controller used to animate `ChatMessagePopupVC` transition.

``` swift
open private(set) lazy var messagePopUpTransitionController 
```

### `impactFeedbackGenerator`

Feedback generator used when presenting actions controller on selected message

``` swift
open var impactFeedbackGenerator 
```

### `zoomTransitionController`

The transition controller used to animate photo gallery transition.

``` swift
open private(set) lazy var zoomTransitionController 
```

## Methods

### `showMessageActionsPopUp(messageContentView:messageActionsController:messageReactionsController:)`

Shows the detail pop-up for the selected message. By default called when the message is long-pressed.

``` swift
open func showMessageActionsPopUp(
        messageContentView: _ChatMessageContentView<ExtraData>,
        messageActionsController: _ChatMessageActionsVC<ExtraData>,
        messageReactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) 
```

#### Parameters

  - messageContentView: The source content view of the selected message. It's used to get the information about the source frame for the zoom-like transition.
  - messageActionsController: The `ChatMessageActionsVC` object which will presented as a part of the pop up.
  - messageReactionsController: The `ChatMessageReactionsVC` object which will presented as a part of the pop up.

### `showLinkPreview(link:)`

Handles opening of a link URL.

``` swift
open func showLinkPreview(link: URL) 
```

#### Parameters

  - url: The URL of the link to preview.

### `showFilePreview(fileURL:)`

Shows a View Controller that show the detail of a file attachment.

``` swift
open func showFilePreview(fileURL: URL?) 
```

#### Parameters

  - fileURL: The URL of the file to preview.

### `showThread(messageId:cid:client:)`

Shows the detail View Controller of a message thread.

``` swift
open func showThread(
        messageId: MessageId,
        cid: ChannelId,
        client: _ChatClient<ExtraData>
    ) 
```

#### Parameters

  - messageId: The id if the parent message of the thread.
  - cid: The `cid` of the channel the message belongs to.
  - client: The current `ChatClient` instance.

### `showImageGallery(message:initialAttachment:previews:)`

Shows the image gallery VC for the selected photo attachment.

``` swift
open func showImageGallery(
        message: _ChatMessage<ExtraData>,
        initialAttachment: ChatMessageImageAttachment,
        previews: [ImagePreviewable]
    ) 
```

#### Parameters

  - message: The id of the message the attachment belongs to.
  - initialAttachment: The attachment to present.
  - previews: All previewable attachments of the message. This is used for swiping right-left when a single message has multiple previewable attachments.

### `animationController(forPresented:presenting:source:)`

``` swift
open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? 
```

### `animationController(forDismissed:)`

``` swift
open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? 
```

### `interactionControllerForDismissal(using:)`

``` swift
open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? 
```
