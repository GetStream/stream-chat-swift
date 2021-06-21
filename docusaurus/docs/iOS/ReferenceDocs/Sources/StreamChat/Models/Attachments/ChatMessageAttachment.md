---
id: chatmessageattachment 
title: ChatMessageAttachment
slug: referencedocs/sources/streamchat/models/attachments/chatmessageattachment
---

A type representing a chat message attachment.
`_ChatMessageAttachment<Payload>` is an immutable snapshot of message attachment at the given time.

``` swift
@dynamicMemberLookup
public struct _ChatMessageAttachment<Payload> 
```

> 

## Properties

### `id`

The attachment identifier.

``` swift
public let id: AttachmentId
```

### `type`

The attachment type.

``` swift
public let type: AttachmentType
```

### `payload`

The attachment payload.

``` swift
public let payload: Payload
```

### `uploadingState`

The uploading state of the attachment.

``` swift
public let uploadingState: AttachmentUploadingState?
```

Reflects uploading progress for local attachments that require file uploading.
Is `nil` for local attachments that don't need to be uploaded.

Becomes `nil` when the message with the current attachment is sent.
