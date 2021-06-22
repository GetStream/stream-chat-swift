---
id: chatmessageactionsvcdelegate 
title: ChatMessageActionsVCDelegate
slug: /ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/chatmessageactionsvcdelegate
---

``` swift
public protocol _ChatMessageActionsVCDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### chatMessageActionsVC(\_:​message:​didTapOnActionItem:​)

``` swift
func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
```

### chatMessageActionsVCDidFinish(\_:​)

``` swift
func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>)
```
