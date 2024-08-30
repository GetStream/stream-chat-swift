---
title: Attachment Downloads
---

:::note
Available from `StreamChat` version 4.63.0.
:::

## Introduction

`StreamChat` supports uploading photos, audio, voice recordings, videos, and also other types of files. Uploaded files are represented with message attachments. Starting from 4.63.0 we provide a way of downloading these attachments locally on the device. 

## Downloading Attachments

`StreamChat` has two different methods for downloading attachments locally depending on if you prefer to use completion handler based methods or the newer async-await supported [state layer](../state-layer/state-layer-overview.md).

`ChatMessageController` has a new method `downloadAttachment(_:completion:)`. The method requires to pass in an instance of  `ChatMessageAttachment` which we can retrieve from the controller managed `ChatMessage`.

Here is an example of creating an instance of `ChatMessageController` using a channel id and a message id. `ChatMessage` has convenient properties for looking up attachments with a specific attachment type. In the example below, we know that this particular message has file attachments and therefore we go ahead and download the first file attachment of the message. When the attachment download has finished, the completion is called with updated `ChatMessageAttachment` value which contains the local file URL of the download.

```swift
let message: ChatMessage = …
guard let fileAttachment = message.fileAttachments.first else { return }
let messageController = client.messageController(
    cid: cid,
    messageId: message.id
)
messageController.downloadAttachment(fileAttachment) { result in
    switch result {
    case .success(let downloadedAttachment):
        let localFileURL = downloadedAttachment.downloadingState?.localFileURL
        // …
    case .failure(let error):
        // …
    }
}
```

If your app uses state-layer and its async-await method looks like this:

```swift
let message: ChatMessage = …
let chat = client.makeChat(for: cid)
guard let fileAttachment = message.fileAttachments.first else { return }
let downloadedAttachment = try await chat.downloadAttachment(fileAttachment)
let localFileURL = downloadedAttachment.downloadingState?.localFileURL
```

When the attachment is being downloaded, its `downloadingState.state` is updated with the download progress and when the download finishes, the last state is stored which is either `downloaded` or `downloadFailed`.

Here is an example of observing the download progress of a file attachment download.

```swift
messageController.messageChangePublisher
    .compactMap(\.item.fileAttachments.first?.downloadingState?.state)
    .sink { state in
        switch state {
        case .downloaded:
            print("Downloaded")
        case .downloading(let progress):
            print("Downloading: \(progress)")
        case .downloadingFailed:
            print("Downloading failed")
        }
    }
    .store(in: &cancellables)
messageController.downloadAttachment(attachment) { result in
    // …
}
```

The same, but with async-await compatible state-layer.

```swift
let chat = client.makeChat(for: cid)
let messageState = try await chat.messageState(for: message.id)
messageState.$message
    .compactMap(\.fileAttachments.first?.downloadingState?.state)
    .sink { state in
        switch state {
        case .downloaded:
            print("Downloaded")
        case .downloading(let progress):
            print("Downloading: \(progress)")
        case .downloadingFailed:
            print("Downloading failed")
        }
    }
    .store(in: &cancellables)
try await chat.downloadAttachment(attachment)
```

:::note
Always access the local file URL using Stream's API because the absolute URL can change between app launches.
:::

### Supporting Custom Attachment Downloads

If your app is using custom attachment types then we can enable downloading the custom attachment by conforming to the `AttachmentPayloadDownloading` protocol. The protocol requires to define a file name used for storing the attachment locally and a URL of the downloadable file. Below we can see an example of a custom attachment which conforms to the `AttachmentPayloadDownloading`. 

```swift
extension AttachmentType {
    static let customLocation = Self(rawValue: "custom_location")
}

struct LocationCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct CustomLocationAttachmentPayload: AttachmentPayload {
    static var type: AttachmentType = .customLocation
    var coordinate: LocationCoordinate    
    var mapURL: URL
}

extension CustomLocationAttachmentPayload: AttachmentPayloadDownloading {
    var localStorageFileName: String {
        "\(coordinate.latitude)-\(coordinate.longitude)"
    }
    
    var remoteURL: URL {
        mapURL
    }
}

typealias ChatMessageCustomLocationAttachment = ChatMessageAttachment<CustomLocationAttachmentPayload>
```

## Deleting Local Downloads

When the local download is not needed anymore, we can delete it. `ChatMessageController` and `Chat` have a delete attachment method and if we prefer to delete all the local downloads, then we can use `CurrentChatUser` and `ConnectedUser` methods to do so.

```swift
// A delete single download
let controller = client.messageController(cid: cid, messageId: message.id)
controller.deleteLocalAttachmentDownload(for: attachment.id) { error in
    // …
}
// Delete all downloads
client.currentUserController().deleteAllLocalAttachmentDownloads { error in
    // …
}
```

```swift
// A delete single download
try await chat.deleteLocalAttachmentDownload(for: attachment.id)
// Delete all downloads
try await client.makeConnectedUser().deleteAllLocalAttachmentDownloads()
```
