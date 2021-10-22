# Attachments v4.x migration

## Send attachments

In both `v4.x` and `v3.2` the sequence of steps is the same:
- **[1]** create a controller for the channel the message should be sent to
- **[2]** create attachments that should be added to the message
- **[3]** send the message with attachments using the controller

```swift {7-9}
// [1] Create a controller
let channelController = ChatChannelController(
    for: ChannelId(type: .messaging, id: "general")
)

// [2] Create attachments (🚨 has changed in `v4.x`)
let attachments = [
  ...
]

// [3] Send the message
channelController.createNewMessage(
    text: "Hey, have a look at this one",
    attachments: attachments,
    completion: { result in
      // handle the result
      print(result)
    }
)
```

Let's see how to create **file/image** and **custom** attachments in `v4.x` and make the compiler happy.

### File/image attachments

`Version 3.x`
```swift
// Create an array of `AttachmentEnvelope` objects
let attachments: [AttachmentEnvelope] = [
  // Add file attachment by creating `ChatMessageAttachmentSeed`
  ChatMessageAttachmentSeed(localURL: fileURL, type: .file),
  // Add image attachment by creating `ChatMessageAttachmentSeed`
  ChatMessageAttachmentSeed(localURL: imageURL, type: .image)
]
```

`Version 4.x`
```swift
// Create an array of `AnyAttachmentPayload` objects
let attachments: [AnyAttachmentPayload] = [
  // Add file attachment by creating `AnyAttachmentPayload`
  try AnyAttachmentPayload(localFileURL: fileURL, attachmentType: .file),
  // Add image attachment by creating `AnyAttachmentPayload`
  try AnyAttachmentPayload(localFileURL: imageURL, attachmentType: .image)
]
```

The `.file` and `.image` attachments are the only built-in attachment types that can be added to the message manually.

### Custom attachments

To add a custom attachments to the message the custom type has to be created first.
This is true for both `v3.2` and `v4.x` however there're some differences so let's see what they are:

`Version 3.x`
```swift
// Declare a custom type conforming to `AttachmentEnvelope`
struct Product: AttachmentEnvelope {
    let type: AttachmentType = .custom("product")

    let name: String
    let price: Int
}

// Create a custom attachment
let iPhone = Product(name: "iPhone 12 Pro", price: 999)

// Create an array of `AttachmentEnvelope` objects
let attachments: [AttachmentEnvelope] = [
  // Add custom attachment instance directly
  iPhone
]
```

`Version 4.x`
```swift
// Declare a custom type conforming to `AttachmentPayload`
struct Product: AttachmentPayload {
    static let type: AttachmentType = "product"

    let name: String
    let price: Int
}

// Create an attachment payload
let iPhone = Product(name: "iPhone 12 Pro", price: 999)

// Create an array of `AnyAttachmentPayload` objects
let attachments: [AnyAttachmentPayload] = [
  // Create `AnyAttachmentPayload` that wraps custom attachment payload
  AnyAttachmentPayload(payload: iPhone)
]
```

### Summary

| `v3.2` | `v4.x` |
| ----------- | ----------- |
| An array of `AttachmentEnvelope` objects is passed when creating a message | An array of `AnyAttachmentPayload` is passed when creating a message |
| Attachments of `.file/.image` type are added via `ChatMessageAttachmentSeed` | Attachments of `.file/.image` type are added via `AnyAttachmentPayload` |
| Custom attachment must conform to `AttachmentEnvelope` protocol and can be directly passed to `createMessage` | Custom attachment must conform to `AttachmentPayload` protocol and wrapped by `AnyAttachmentPayload` before passing to `createMessage` |

## Get attachments

In both `v4.x` and `v3.2` the sequence of steps is the same:
- **[1]** get a `ChatMessage` model ([Working with messages](./working-with-messages.md))
- **[2]** get all attachments of the required type
- **[3]** access attachment fields

Let's see how at steps **[2]** and **[3]** look in `v4.x` for different kind of attachments.

### File attachments

File attachment requires prior uploading before the message is sent. The local state is exposed for `.file` attachments to track how the uploading goes.

`Version 3.x`
```swift
// Get `.file` attachments
let fileAttachments = message.attachments
  .compactMap { $0 as? ChatMessageDefaultAttachment }
  .filter { $0.type == .file }

// Get the first attachment
if let file = fileAttachments.first {
  if let localState = file.localState, let localURL = file.localURL {
    // Attachment is being uploaded, use local URL to show a preview
    print(localState, localURL)
  } else if let fileURL = file.url {
    // Attachment is uploaded, use remote url
    print(fileURL)
  }
}
```

`Version 4.x`
```swift
// Get the first `.file` attachment
if let file = message.fileAttachments.first {
  // Show file preview url. If attachment is being uploaded this will be the local URL.
  print(file.assetURL)

  if let uploadingState = file.uploadingState {
    // Attachment is being uploaded, handle uploading progress
    print(uploadingState)
  }
}
```

### Image attachments

Image attachment requires prior uploading before the message is sent. The local state is exposed for `.image` attachments to track how the uploading goes.

`Version 3.x`

Image attachments are exposed as `ChatMessageDefaultAttachment`. Mandatory fields are **optional** because of `ChatMessageDefaultAttachment` being used for all built-in attachment types.

```swift
// Get `.image` attachments
let imageAttachments = message.attachments
  .compactMap { $0 as? ChatMessageDefaultAttachment }
  .filter { $0.type == .image }

// Get the first attachment
if let image = imageAttachments.first {
  if let localState = image.localState, let localURL = image.localURL {
    // Attachment is being uploaded, use local URL to show a preview
    print(localState, localURL)
  } else if let imageURL = image.imageURL {
    // Attachment is uploaded, use remote url
    print(imageURL)
  }
}
```

`Version 4.x`

Image attachments are exposed as `ChatMessageImageAttachment`. Mandatory fields are **non-optional** and can be accessed directly on attachment.

```swift
// Get the first `.image` attachment
if let image = message.imageAttachments.first {
  // Show a preview
  print(image.previewURL)

  if let uploadingState = image.uploadingState {
    // Attachment is being uploaded, handle uploading progress
    print(uploadingState)
  }
}
```

### Giphy attachments

The ephemeral message containing giphy attachment will be created when `/giphy` command is used.

`Version 3.x`

Giphy attachments are exposed as `ChatMessageDefaultAttachment`. Mandatory fields are **optional** because of `ChatMessageDefaultAttachment` being used for all built-in attachment types.

```swift
// Get `.giphy` attachments
let giphyAttachments = message.attachments
  .compactMap { $0 as? ChatMessageDefaultAttachment }
  .filter { $0.type == .giphy }

// Get the first attachments
if let giphy = giphyAttachments.first {
  // Unwrap gif URL
  if let gifURL = giphy.imageURL {
    // Load and show gif
    print(gifURL)
  }
}
```

`Version 4.x`

Giphy attachments are exposed as `ChatMessageGiphyAttachment`. Mandatory fields are **non-optional** and can be accessed directly on attachment.

```swift
// Get the first `.giphy` attachment
if let giphy = message.giphyAttachments.first {
  // Load and show gif right away
  print(giphy.previewURL)
}
```

### Link preview attachments

The link attachment will be added to the message automatically if the message is sent with the text containing the URL.

`Version 3.x`

Giphy attachments are exposed as `ChatMessageDefaultAttachment`. Mandatory fields are **optional** because of `ChatMessageDefaultAttachment` being used for all built-in attachment types.

```swift
// Get `.link(...)` attachments
let linkAttachments = message.attachments
  .compactMap { $0 as? ChatMessageDefaultAttachment }
  .filter { $0.type.isLink }

// Get the first attachment
if let link = linkAttachments.first {
  // Unwrap the URL
  if let url = link.url {
    // Show preview for url
    print(url)
  }
}
```

`Version 4.x`

Link preview attachments are exposed as `ChatMessageLinkAttachment`. Mandatory fields are **non-optional** and can be accessed directly on attachment.

```swift
// Get the first `.linkPreview` attachment
if let linkPreview = message.linkAttachments.first {
  // Handle the link
  print(linkPreview.originalURL)
}
```

### Custom attachments

`Version 3.x`

- all built-in attachments exposed as `ChatMessageRawAttachment`
- custom payload is stored in `data: Data?` fields
- custom data should be decoded manually `data`
- attachment `id` is optional

```swift
// Custom attachment type has to be `Decodable`
extension Product: Decodable { /* ... */ }

// Get attachments of custom type
let productAttachments = message.attachments
  .compactMap { $0 as? ChatMessageRawAttachment }
  .filter { $0.type == .custom("product") }

// Get first custom attachment
if let productAttachment = productAttachments.first {
  // Unwrap attachment data
  if let productData = productAttachment.data {
    // Try to decode the custom type from data
    let product = try JSONDecoder().decode(Product.self, from: productData)
    // Handle custom attachment payload
    print(product)
  }
}
```

`Version 4.x`

- custom attachments are directly accessible on `ChatMessage`
- custom payload fields are are directly on attachment thanks to `dynamicMemberLookup`
- attachment `id` is not-optional 🎉

```swift

// It's recommended but not required to create a typealias for custom attachment type to avoid generic stuff
typealias ProductAttachment = _ChatMessageAttachment<Product>

// Get attachments of custom type
let productAttachments = message.attachments(payloadType: Product.self)

// Get first custom attachment
if let product = productAttachments.first {
  // Access the payload fields right away
  print(product.name)
}
```

### Changes summary

| `v3.2` | `v4.x` |
| ----------- | ----------- |
| `ChatMessage` has a single `attachments` field | `ChatMessage` has multiple fields one for each attachment type (`imageAttachments/giphyAttachments/etc.`) |
| Built-in attachments are exposed as `ChatMessageDefaultAttachment` with mandatory fields being **optional** | Built-in attachments are exposed as arrays `_ChatMessageAttachment<Payload>` with concrete payload type with mandatory fields being **non-optional** |
| To be exposed on the message custom attachment must conform to `ChatMessageAttachment` protocol | In order attachment can be exposed on the message it's payload must conform to `AttachmentPayload` protocol |
| Custom attachments are exposed as `ChatMessageRawAttachment` | Custom attachments are exposed the same way built-in attachments are |
