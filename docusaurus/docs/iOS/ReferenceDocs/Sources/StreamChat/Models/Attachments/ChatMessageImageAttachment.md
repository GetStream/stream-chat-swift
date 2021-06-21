---
id: chatmessageimageattachment 
title: ChatMessageImageAttachment
slug: referencedocs/sources/streamchat/models/attachments/chatmessageimageattachment
---

A type alias for attachment with `ImageAttachmentPayload` payload type.

``` swift
public typealias ChatMessageImageAttachment = _ChatMessageAttachment<ImageAttachmentPayload>
```

The `ChatMessageImageAttachment` attachment will be added to the message automatically
if the message was sent with attached `AnyAttachmentPayload` created with
local URL and `.image` attachment type.
