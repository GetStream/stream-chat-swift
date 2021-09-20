---
title: ChatMessageAudioAttachment
---

A type alias for attachment with `AudioAttachmentPayload` payload type.

``` swift
public typealias ChatMessageAudioAttachment = ChatMessageAttachment<AudioAttachmentPayload>
```

The `ChatMessageAudioAttachment` attachment will be added to the message automatically
if the message was sent with attached `AnyAttachmentPayload` created with
local URL and `.audio` attachment type.
