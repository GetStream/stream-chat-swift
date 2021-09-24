---
title: ChatMessageContentViewDelegate
---

A protocol for message content delegate responsible for action handling.

``` swift
public protocol ChatMessageContentViewDelegate: AnyObject 
```

When custom message content view is created, the protocol that inherits from this one
should be created if an action can be taken on the new content view.

## Inheritance

`AnyObject`

## Requirements

### messageContentViewDidTapOnErrorIndicator(\_:​)

Gets called when error indicator is tapped.

``` swift
func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?)
```

#### Parameters

  - indexPath: The index path of the cell displaying the content view. Equals to `nil` when the content view is displayed outside the collection/table view.

### messageContentViewDidTapOnThread(\_:​)

Gets called when thread reply button is tapped.

``` swift
func messageContentViewDidTapOnThread(_ indexPath: IndexPath?)
```

#### Parameters

  - indexPath: The index path of the cell displaying the content view. Equals to `nil` when the content view is displayed outside the collection/table view.

### messageContentViewDidTapOnQuotedMessage(\_:​)

Gets called when quoted message view is tapped.

``` swift
func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?)
```

#### Parameters

  - indexPath: The index path of the cell displaying the content view. Equals to `nil` when the content view is displayed outside the collection/table view.

### messageContentViewDidTapOnAvatarView(\_:​)

Gets called when avatar view is tapped.

``` swift
func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?)
```

#### Parameters

  - indexPath: The index path of the cell displaying the content view. Equals to `nil` when the content view is displayed outside the collection/table view.
