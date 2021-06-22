---
id: attachmentviewcatalog 
title: AttachmentViewCatalog
slug: /ReferenceDocs/Sources/StreamChatUI/ChatMessageList/Attachments/attachmentviewcatalog
---

A class that is used to determine the AttachmentViewInjector to use for rendering one message's attachments.
If your application uses custom attachment types, you will need to create a subclass and override the attachmentViewInjectorClassFor
method so that the correct AttachmentViewInjector is used.

``` swift
open class _AttachmentViewCatalog<ExtraData: ExtraDataTypes> 
```

## Methods

### `attachmentViewInjectorClassFor(message:components:)`

``` swift
open class func attachmentViewInjectorClassFor(
        message: _ChatMessage<ExtraData>,
        components: _Components<ExtraData>
    ) -> _AttachmentViewInjector<ExtraData>.Type? 
```
