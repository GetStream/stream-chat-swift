---
id: chatmessageinteractiveattachmentview.actionbutton 
title: ChatMessageInteractiveAttachmentView.ActionButton
slug: /ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/chatmessageinteractiveattachmentview.actionbutton
---

``` swift
open class ActionButton: _Button, AppearanceProvider 
```

## Inheritance

[`_Button`](../../CommonViews/_Button), [`AppearanceProvider`](../../Utils/AppearanceProvider)

## Properties

### `content`

``` swift
public var content: AttachmentAction? 
```

### `didTap`

``` swift
public var didTap: (() -> Void)?
```

### `defaultIntrinsicContentSize`

``` swift
public var defaultIntrinsicContentSize 
```

### `intrinsicContentSize`

``` swift
override open var intrinsicContentSize: CGSize 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```

### `handleTouchUpInside()`

``` swift
@objc open func handleTouchUpInside() 
```
