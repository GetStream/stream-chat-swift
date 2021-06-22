---
id: gallerycontentviewdelegate 
title: GalleryContentViewDelegate
slug: /ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/gallerycontentviewdelegate
---

The delegate used `GalleryAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol GalleryContentViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../ChatMessage/ChatMessageContentViewDelegate)

## Requirements

### didTapOnImageAttachment(\_:​previews:​at:​)

Called when the user taps on one of the image attachments.

``` swift
func didTapOnImageAttachment(
        _ attachment: ChatMessageImageAttachment,
        previews: [ImagePreviewable],
        at indexPath: IndexPath
    )
```
