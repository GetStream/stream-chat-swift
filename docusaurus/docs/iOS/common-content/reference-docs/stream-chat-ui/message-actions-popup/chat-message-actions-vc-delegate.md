---
title: ChatMessageActionsVCDelegate
---

``` swift
public protocol ChatMessageActionsVCDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### chatMessageActionsVC(\_:​message:​didTapOnActionItem:​)

``` swift
func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
```

### chatMessageActionsVCDidFinish(\_:​)

``` swift
func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC)
```
