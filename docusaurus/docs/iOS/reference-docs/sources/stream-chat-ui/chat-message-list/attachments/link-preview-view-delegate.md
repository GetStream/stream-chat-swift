---
title: LinkPreviewViewDelegate
---

The delegate used in `LinkAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol LinkPreviewViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../chat-message/chat-message-content-view-delegate.md)

## Requirements

### didTapOnLinkAttachment(\_:​at:​)

Called when the user taps the link preview.

``` swift
func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    )
```
