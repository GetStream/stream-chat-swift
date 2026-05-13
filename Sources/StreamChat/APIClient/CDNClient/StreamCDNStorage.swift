//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An uploaded file.
public struct UploadedFile: Sendable, Decodable {
    public let fileURL: URL
    public let thumbnailURL: URL?

    /// The chat message attachment associated with the upload, after any payload mutations
    /// performed by a custom ``CDNStorage`` implementation.
    ///
    /// Set this from `CDNStorage.uploadAttachment(_:options:completion:)` when your custom CDN
    /// returns extra metadata (e.g. title, codec, dimensions, signed thumbnail URLs) that you
    /// want to write into the attachment payload before the SDK persists it. Use
    /// ``AnyAttachmentUpdater`` to mutate the typed payload and pass the resulting attachment here.
    ///
    /// - Note: This property is only meaningful when returned from
    ///   ``CDNStorage/uploadAttachment(_:options:completion:)`` (the message-attached overload).
    ///   It is ignored by ``CDNStorage/uploadAttachment(localUrl:options:completion:)`` because
    ///   standalone file uploads have no message attachment context.
    public let attachment: AnyChatMessageAttachment?

    public init(
        fileURL: URL,
        thumbnailURL: URL? = nil,
        attachment: AnyChatMessageAttachment? = nil
    ) {
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.attachment = attachment
    }

    private enum CodingKeys: String, CodingKey {
        case fileURL
        case thumbnailURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        attachment = nil
    }
}

/// Default implementation of CDNStorage that uses Stream's API.
final class StreamCDNStorage: CDNStorage, @unchecked Sendable {
    private let decoder: RequestDecoder
    private let encoder: RequestEncoder
    private let session: URLSession
    @Atomic private var taskProgressObservers: [Int: NSKeyValueObservation] = [:]

    init(
        encoder: RequestEncoder,
        decoder: RequestDecoder,
        sessionConfiguration: URLSessionConfiguration
    ) {
        self.encoder = encoder
        session = URLSession(configuration: sessionConfiguration)
        self.decoder = decoder
    }

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {
        guard
            let uploadingState = attachment.uploadingState,
            let fileData = try? Data(contentsOf: uploadingState.localFileURL, options: .mappedIfSafe) else {
            return completion(.failure(ClientError.AttachmentUploading(id: attachment.id)))
        }
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(with: attachment.id.cid, type: attachment.type)

        uploadAttachment(
            endpoint: endpoint,
            fileData: fileData,
            uploadingState: uploadingState,
            progress: options.progress,
            completion: completion
        )
    }

    func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {
        let uploadingState: AttachmentUploadingState
        do {
            uploadingState = AttachmentUploadingState(
                localFileURL: localUrl,
                state: .pendingUpload,
                file: try .init(url: localUrl)
            )
        } catch {
            completion(.failure(error))
            return
        }

        guard let fileData = try? Data(contentsOf: localUrl, options: .mappedIfSafe) else {
            return completion(.failure(ClientError.Unknown()))
        }

        let isImage = uploadingState.file.type.isImage
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(type: isImage ? .image : .file)

        uploadAttachment(
            endpoint: endpoint,
            fileData: fileData,
            uploadingState: uploadingState,
            progress: options.progress,
            completion: completion
        )
    }

    func deleteAttachment(
        remoteUrl: URL,
        options: AttachmentDeleteOptions,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        let isImage = AttachmentFileType(ext: remoteUrl.pathExtension).isImage
        let endpoint = Endpoint<EmptyResponse>
            .deleteAttachment(
                url: remoteUrl,
                type: isImage ? .image : .file
            )

        encoder.encodeRequest(for: endpoint) { [weak self] (requestResult) in
            var urlRequest: URLRequest

            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error, subsystems: .httpRequests)
                completion(error)
                return
            }

            guard let self = self else {
                completion(ClientError.Unknown("StreamCDNStorage was deallocated"))
                return
            }

            self.session.dataTask(with: urlRequest, completionHandler: { _, _, error in
                completion(error)
            }).resume()
        }
    }

    private func uploadAttachment<ResponsePayload>(
        endpoint: Endpoint<ResponsePayload>,
        fileData: Data,
        uploadingState: AttachmentUploadingState,
        progress: (@Sendable (Double) -> Void)? = nil,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {
        let multipartFormData = MultipartFormData(
            fileData,
            fileName: uploadingState.localFileURL.lastPathComponent,
            mimeType: uploadingState.file.type.mimeType
        )

        encoder.encodeRequest(for: endpoint) { [weak self] (requestResult) in
            var urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error, subsystems: .httpRequests)
                completion(.failure(error))
                return
            }

            let data = multipartFormData.getMultipartFormData()
            urlRequest.addValue("multipart/form-data; boundary=\(MultipartFormData.boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data

            guard let self = self else {
                log.warning("Callback called while self is nil", subsystems: .httpRequests)
                completion(.failure(ClientError.Unknown("StreamCDNStorage was deallocated")))
                return
            }

            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let response: FileUploadPayload = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )
                    let file = UploadedFile(fileURL: response.fileURL, thumbnailURL: response.thumbURL)

                    completion(.success(file))
                } catch {
                    completion(.failure(error))
                }
            }

            if let progressListener = progress {
                let taskID = task.taskIdentifier
                self._taskProgressObservers.mutate { observers in
                    observers[taskID] = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                        progressListener(progress.fractionCompleted)
                        if progress.isFinished || progress.isCancelled {
                            self?._taskProgressObservers.mutate { observers in
                                observers[taskID]?.invalidate()
                                observers[taskID] = nil
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }
}
