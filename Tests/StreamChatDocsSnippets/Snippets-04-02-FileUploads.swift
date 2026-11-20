//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/file-uploads/

import Foundation
import StreamChat

struct Snippets_04_02_FileUploads {
    var channelController: ChatChannelController!
    var chatClient: ChatClient!
    var config: ChatClientConfig!
    var imageLocalFileUrl: URL!
    var localFileUrl: URL!
    var localImageUrl: URL!

    func uploadingFilesToAChannel() throws {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = chatClient.channelController(for: channelId)

        // Option 1: Send message with local attachment (SDK handles upload)
        let imageAttachment = try AnyAttachmentPayload(
          localFileURL: localImageUrl,
          attachmentType: .image
        )
        channelController.createNewMessage(
          text: "Hello",
          attachments: [imageAttachment]
        )

        // Option 2: Upload first, then attach to message
        // File size and type information for the attachment payload
        let file = try AttachmentFile(url: localFileUrl)
        channelController.uploadAttachment(
          localFileURL: localFileUrl,
          type: .image,
          progress: { value in
            // Track upload progress (0.0 to 1.0)
          },
          completion: { result in
            switch result {
            case .success(let uploadedFile):
              let payload = ImageAttachmentPayload(
                title: nil,
                imageRemoteURL: uploadedFile.remoteURL,
                file: file
              )
              let attachment = AnyAttachmentPayload(payload: payload)
              channelController.createNewMessage(
                text: "Hello",
                attachments: [attachment]
              )
            case .failure(let error):
              // Handle upload error
              print(error)
            }
          }
        )
    }

    func uploadingStandaloneFiles() {
        chatClient.uploadAttachment(
          localUrl: imageLocalFileUrl,
          progress: { progressValue in
            // Track upload progress (0.0 to 1.0)
          },
          completion: { result in
            switch result {
            case .success(let uploadedFile):
              // Use the URL (e.g., update user avatar)
              chatClient.currentUserController().updateUserData(
                imageURL: uploadedFile.fileURL
              )
            case .failure(let error):
              // Handle upload error
              print(error)
            }
          }
        )
    }

    func deletingFiles() {
        // Delete from channel
        channelController.deleteFile(url: "remote-url")
        channelController.deleteImage(url: "remote-url")

        // Delete standalone file
        let remoteURL = URL(string: "https://example.com/remote-url")!
        chatClient.deleteAttachment(remoteUrl: remoteURL) { error in
          // Handle deletion error
        }
    }

    final class CustomCDN: CDNStorage {
      // Message attachments: the local file is at attachment.uploadingState?.localFileURL
      func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
      ) {
        // Upload to your CDN
        // Call options.progress?(value) to report upload progress (0.0 to 1.0)
        // Call completion(.success(UploadedFile(fileURL: remoteURL))) with the result
      }

      // Standalone file uploads
      func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
      ) {
        // Upload the file at localUrl to your CDN and call completion() with the result
      }

      func deleteAttachment(
        remoteUrl: URL,
        options: AttachmentDeleteOptions,
        completion: @escaping @Sendable (Error?) -> Void
      ) {
        // Delete the file from your CDN, then call completion(nil) or completion(error)
      }
    }

    mutating func usingYourOwnCDN() {
        // Assign to ChatClientConfig
        config.cdnStorage = CustomCDN()
    }
}
