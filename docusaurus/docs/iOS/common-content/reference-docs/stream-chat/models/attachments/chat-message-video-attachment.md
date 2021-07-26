---
title: ChatMessageVideoAttachment
---

A type alias for attachment with `VideoAttachmentPayload` payload type.

``` swift
public typealias ChatMessageVideoAttachment = _ChatMessageAttachment<VideoAttachmentPayload>
```

The `ChatMessageVideoAttachment` attachment will be added to the message automatically
if the message was sent with attached `AnyAttachmentPayload` created with
local URL and `.video` attachment type.
