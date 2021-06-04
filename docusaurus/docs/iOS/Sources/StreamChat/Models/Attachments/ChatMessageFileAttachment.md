
A type alias for attachment with `FileAttachmentPayload` payload type.

``` swift
public typealias ChatMessageFileAttachment = _ChatMessageAttachment<FileAttachmentPayload>
```

The `ChatMessageFileAttachment` attachment will be added to the message automatically
if the message was sent with attached `AnyAttachmentPayload` created with
local URL and `.file` attachment type.
