---
id: anyattachmentpayload 
title: AnyAttachmentPayload
slug: /ReferenceDocs/Sources/StreamChat/Models/Attachments/anyattachmentpayload
---

A type-erased type that wraps either a local file URL that has to be uploaded
and attached to the message OR a custom payload which the message attachment
should contain.

``` swift
public struct AnyAttachmentPayload 
```

## Initializers

### `init(payload:)`

Creates an instance of `AnyAttachmentPayload` with the given payload.

``` swift
init<Payload: AttachmentPayload>(payload: Payload) 
```

If attached to the new message the attachment with the given payload will be immediately
available on `ChatMessage` with the `uploadingState == nil` since it doesn't require prior
uploading.

#### Parameters

  - payload: The payload to have the message attachment with.

### `init(localFileURL:attachmentType:)`

Creates an instance of `AnyAttachmentPayload` with the URL referencing to a local file.

``` swift
init(localFileURL: URL, attachmentType: AttachmentType) throws 
```

The resulting attachment will have `ImageAttachmentPayload` if `attachmentType == .image`.
If the type is different from `.image` the attachment will have payload of `FileAttachmentPayload`
type.

If attached to the new message the attachment with the given payload will be immediately
available on `ChatMessage` with the `uploadingState` reflecting the file uploading progress.

> 

#### Parameters

  - localFileURL: The local URL referencing to the file.
  - attachmentType: The type of resulting attachment exposed on the message.

#### Throws

The error if `localFileURL` is not the file URL.

## Properties

### `type`

A type of attachment that will be created when the message is sent.

``` swift
public let type: AttachmentType
```

### `payload`

A payload that will exposed on attachment when the message is sent.

``` swift
public let payload: Encodable?
```

### `localFileURL`

A URL referencing to the local file that should be uploaded.

``` swift
public let localFileURL: URL?
```
