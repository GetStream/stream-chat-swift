---
title: AttachmentViewCatalog
---

A class that is used to determine the AttachmentViewInjector to use for rendering one message's attachments.
If your application uses custom attachment types, you will need to create a subclass and override the attachmentViewInjectorClassFor
method so that the correct AttachmentViewInjector is used.

``` swift
@available(iOSApplicationExtension, unavailable)
open class AttachmentViewCatalog 
```

## Methods

### `attachmentViewInjectorClassFor(message:components:)`

``` swift
open class func attachmentViewInjectorClassFor(
        message: ChatMessage,
        components: Components
    ) -> AttachmentViewInjector.Type? 
```
