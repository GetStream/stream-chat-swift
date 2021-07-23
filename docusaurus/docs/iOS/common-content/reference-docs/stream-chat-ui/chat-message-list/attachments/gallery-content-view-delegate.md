---
title: GalleryContentViewDelegate
---

The delegate used `GalleryAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol GalleryContentViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../../chat-message/chat-message-content-view-delegate)

## Requirements

### galleryMessageContentView(at:​didTapAttachmentPreview:​previews:​)

Called when the user taps on one of the attachment previews.

``` swift
func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    )
```

### galleryMessageContentView(at:​didTakeActionOnUploadingAttachment:​)

Called when action button is clicked for uploading attachment.

``` swift
func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    )
```
