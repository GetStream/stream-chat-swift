---
title: FileActionContentViewDelegate
---

The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol FileActionContentViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate.md)

## Requirements

### didTapOnAttachment(\_:​at:​)

Called when the user taps on attachment action

``` swift
func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
```
