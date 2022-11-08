//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The uploaded file information.
public struct UploadedFile {
    /// The original file remote url.
    public let remoteURL: URL
    /// The preview/thumbnail file remote url.
    public let remotePreviewURL: URL?

    public init(remoteURL: URL, remotePreviewURL: URL?) {
        self.remoteURL = remoteURL
        self.remotePreviewURL = remotePreviewURL
    }
}

/// The CDN client is responsible to upload files to a CDN.
public protocol CDNClient {
    /// Uploads attachment as a multipart/form-data and returns only the uploaded remote file.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the file uploaded information.
    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    )
}

/// Default implementation of CDNClient that uses Stream CDN
class StreamCDNClient: CDNClient {
    static var maxAttachmentSize: Int64 { 100 * 1024 * 1024 }

    private let decoder: RequestDecoder
    private let encoder: RequestEncoder
    private let session: URLSession
    /// Keeps track of uploading tasks progress
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

    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        guard
            let uploadingState = attachment.uploadingState,
            let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
            return completion(.failure(ClientError.AttachmentUploading(id: attachment.id)))
        }
        // Encode locally stored attachment into multipart form data
        let multipartFormData = MultipartFormData(
            fileData,
            fileName: uploadingState.localFileURL.lastPathComponent,
            mimeType: uploadingState.file.type.mimeType
        )
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(with: attachment.id.cid, type: attachment.type)

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
                return
            }

            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let decodedResponse: FileUploadPayload = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )

                    let uploadedFile = UploadedFile(
                        remoteURL: decodedResponse.fileURL,
                        remotePreviewURL: decodedResponse.previewURL
                    )

                    completion(.success(uploadedFile))
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
