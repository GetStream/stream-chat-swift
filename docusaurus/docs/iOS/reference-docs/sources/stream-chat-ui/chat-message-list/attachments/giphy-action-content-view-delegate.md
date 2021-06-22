---
title: GiphyActionContentViewDelegate
---

The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol GiphyActionContentViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate)

## Requirements

### didTapOnAttachmentAction(\_:​at:​)

Called when the user taps on attachment action

``` swift
func didTapOnAttachmentAction(_ action: AttachmentAction, at indexPath: IndexPath)
```
