---
title: ChatMessageLinkAttachment
---

A type alias for attachment with `LinkAttachmentPayload` payload type.

``` swift
public typealias ChatMessageLinkAttachment = ChatMessageAttachment<LinkAttachmentPayload>
```

The `ChatMessageLinkAttachment` attachment will be added to the message automatically
if the message is sent with the text containing the URL.
