---
title: Custom CDN
---

By default, files are uploaded to Stream's CDN, but you can also use your own CDN. Currently, there are two options to provide your custom file uploading logic.

- Providing a `CDNClient` implementation. This is the simplest one and it is useful if you are only interested in changing the CDN URL and do not want to update the attachment payload.

- Providing an `AttachmentUploader` implementation. This one can be used for more fine-grain control, since you can change not only the URL but the attachment payload as well.

:::note
You should only pick 1 of the 2 options provided. Since using an `AttachmentUploader` will override the custom `CDNClient` implementation.
:::

## Custom `CDNClient` implementation

In case you simply want to change the URL, here is an example of a custom `CDNClient` implementation.

```swift
// Example of your Upload API
protocol UploadFileAPI {
    func uploadFile(data: Data, progress: ((Double) -> Void)?, completion: (@escaping (FileDetails) -> Void))
}
protocol FileDetails {
    var url: URL { get }
    var thumbnailURL: URL { get }
}

final class CustomCDNClient: CDNClient {
    /// Example, max 100 MB. Required by CDNClient protocol. 
    static var maxAttachmentSize: Int64 { 100 * 1024 * 1024 }

    let uploadFileApi: UploadFileAPI

    init(uploadFileApi: UploadFileAPI) {
        self.uploadFileApi = uploadFileApi
    }

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>
    ) -> Void) {
        // The local file url is present in attachment.uploadingState.
        guard let uploadingState = attachment.uploadingState,
              let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
          return completion(.failure(ClientError("Failed to upload attachment with id: \(attachment.id)")))
        }

        uploadFileApi.uploadFile(data: fileData, progress: progress) { file in
            let uploadedFile = UploadedFile(url: file.url, thumbnailURL: file.thumbnailURL)
            completion(.success(uploadedFile))
        }
    }

}
```

Then, you can set your custom implementation in the `ChatClientConfig`:
```swift
var config = ChatClientConfig(apiKeyString: apiKeyString)   
config.customCDNClient = CustomCDNClient(uploadFileApi: YourUploadFileApi())
```

:::note
In case your API does not support progress updates, you can simple ignore the argument.
:::

### Custom Firebase CDN

You can also use `FirebaseStorage` as your custom CDN. There is a Swift Package called `StreamFirebaseCDN`, built by the community to facilitate this, which can be found [here](https://github.com/pzmudzinski/StreamFirebaseCDN).

## Custom AttachmentUploader implementation

If you require changing more details of the attachment, in case your upload file API supports more features, you can provide a custom `AttachmentUploader`.

```swift
// Example of your Upload API
protocol UploadFileAPI {
    func uploadFile(data: Data, progress: ((Double) -> Void)?, completion: (@escaping (FileDetails) -> Void))
}
protocol FileDetails {
    var name: String { get set }
    var url: URL { get }
    var thumbnailURL: URL { get set }
    var codec: String { get set }
}

final class CustomUploader: AttachmentUploader {

    private let attachmentUpdater = AnyAttachmentUpdater()

    let uploadFileApi: UploadFileAPI

    init(uploadFileApi: UploadFileAPI) {
        self.uploadFileApi = uploadFileApi
    }

    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        // The local file url is present in attachment.uploadingState.
        guard let uploadingState = attachment.uploadingState,
              let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
          return completion(.failure(ClientError("Failed to upload attachment with id: \(attachment.id)")))
        }

        uploadFileApi.uploadFile(data: fileData, progress: progress) { [weak self] file in
            var uploadedAttachment = UploadedAttachment(
                attachment: attachment,
                remoteURL: file.url
            )

            // Update the image payload, in case the attachment is an image.
            self?.attachmentUpdater.update(
                &uploadedAttachment.attachment,
                forPayload: ImageAttachmentPayload.self
            ) { payload in
                payload.title = file.name
                payload.extraData = [
                    "thumbnailUrl": .string(file.thumbnailURL)
                ]
            }

            // Update the audio payload, in case the attachment is a audio.
            self?.attachmentUpdater.update(
                &uploadedAttachment.attachment,
                forPayload: AudioAttachmentPayload.self
            ) { payload in
                payload.title = file.name
                payload.extraData = [
                    "thumbnailUrl": .string(file.thumbnailURL),
                    "codec": .string(file.codec)
                ]
            }

            completion(.success(uploadedAttachment))
        }
    }
}
```

The `AnyAttachmentUpdater` is a helper component provided by Stream, to make it easier to update the underlying payload of a type-erased attachment. You should pass a reference of the attachment with `&` and say which payload to update depending on what type is the attachment.

Finally, you should set your custom implementation in the `ChatClientConfig`:
```swift
var config = ChatClientConfig(apiKeyString: apiKeyString)   
config.customAttachmentUploader = CustomUploader(uploadFileApi: YourUploadFileApi())
```