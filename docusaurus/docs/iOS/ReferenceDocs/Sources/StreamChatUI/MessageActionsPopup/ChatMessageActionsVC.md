---
id: chatmessageactionsvc 
title: ChatMessageActionsVC
--- 

View controller to show message actions.

``` swift
open class _ChatMessageActionsVC<ExtraData: ExtraDataTypes>: _ViewController, ThemeProvider 
```

## Inheritance

[`_ViewController`](../CommonViews/_ViewController), [`ThemeProvider`](../Utils/ThemeProvider)

## Properties

### `delegate`

`_ChatMessageActionsVC.Delegate` instance.

``` swift
public var delegate: Delegate?
```

### `messageController`

`_ChatMessageController` instance used to obtain the message data.

``` swift
public var messageController: _ChatMessageController<ExtraData>!
```

### `channelConfig`

`ChannelConfig` that contains the feature flags of the channel.

``` swift
public var channelConfig: ChannelConfig!
```

### `message`

Message that should be shown in this view controller.

``` swift
open var message: _ChatMessage<ExtraData>? 
```

### `alertsRouter`

The `AlertsRouter` instance responsible for presenting alerts.

``` swift
open lazy var alertsRouter 
```

### `messageActionsContainerStackView`

`ContainerView` for showing message's actions.

``` swift
open private(set) lazy var messageActionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `actionButtonClass`

Class used for buttons in `messageActionsContainerView`.

``` swift
open var actionButtonClass: ChatMessageActionControl.Type 
```

### `messageActions`

Array of `ChatMessageActionItem`s - override this to setup your own custom actions

``` swift
open var messageActions: [ChatMessageActionItem] 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `editActionItem()`

Returns `ChatMessageActionItem` for edit action

``` swift
open func editActionItem() -> ChatMessageActionItem 
```

### `deleteActionItem()`

Returns `ChatMessageActionItem` for delete action

``` swift
open func deleteActionItem() -> ChatMessageActionItem 
```

### `resendActionItem()`

Returns `ChatMessageActionItem` for resend action.

``` swift
open func resendActionItem() -> ChatMessageActionItem 
```

### `muteActionItem()`

Returns `ChatMessageActionItem` for mute action.

``` swift
open func muteActionItem() -> ChatMessageActionItem 
```

### `unmuteActionItem()`

Returns `ChatMessageActionItem` for unmute action.

``` swift
open func unmuteActionItem() -> ChatMessageActionItem 
```

### `inlineReplyActionItem()`

Returns `ChatMessageActionItem` for inline reply action.

``` swift
open func inlineReplyActionItem() -> ChatMessageActionItem 
```

### `threadReplyActionItem()`

Returns `ChatMessageActionItem` for thread reply action.

``` swift
open func threadReplyActionItem() -> ChatMessageActionItem 
```

### `copyActionItem()`

Returns `ChatMessageActionItem` for copy action.

``` swift
open func copyActionItem() -> ChatMessageActionItem 
```

### `handleAction(_:)`

Triggered for actions which should be handled by `delegate` and not in this view controller.

``` swift
open func handleAction(_ actionItem: ChatMessageActionItem) 
```
