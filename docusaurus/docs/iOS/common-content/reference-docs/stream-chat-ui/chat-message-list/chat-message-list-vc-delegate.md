---
title: ChatMessageListVCDelegate
---

The object that acts as the delegate of the message list.

``` swift
public protocol ChatMessageListVCDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### chatMessageListVC(\_:​willDisplayMessageAt:​)

Tells the delegate the message list is about to draw a message for a particular row.

``` swift
func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    )
```

#### Parameters

  - vc: The message list informing the delegate of this event.
  - indexPath: An index path locating the row in the message list.

### chatMessageListVC(\_:​scrollViewDidScroll:​)

Tells the delegate when the user scrolls the content view within the receiver.

``` swift
func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    )
```

#### Parameters

  - vc: The message list informing the delegate of this event.
  - scrollView: The scroll view that belongs to the message list.

### chatMessageListVC(\_:​didTapOnAction:​for:​)

Tells the delegate when the user taps on an action for the given message.

``` swift
func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    )
```

#### Parameters

  - vc: The message list informing the delegate of this event.
  - actionItem: The action performed on the given message.
  - message: The given message.
