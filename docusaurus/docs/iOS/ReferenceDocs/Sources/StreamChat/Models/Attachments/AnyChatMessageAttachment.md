---
id: anychatmessageattachment 
title: AnyChatMessageAttachment
slug: /ReferenceDocs/Sources/StreamChat/Models/Attachments/anychatmessageattachment
---

## Methods

### `attachment(payloadType:)`

Converts type-erased attachment to the attachment with the concrete payload.

``` swift
func attachment<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> _ChatMessageAttachment<Payload>? 
```

Attachment with the requested payload type will be returned if the type-erased payload
has a `Payload` instance under the hood OR if it’s a `Data` that can be decoded as a `Payload`.

#### Parameters

  - payloadType: The payload type the current type-erased attachment payload should be treated as.

#### Returns

The attachment with the requested payload type or `nil`.
