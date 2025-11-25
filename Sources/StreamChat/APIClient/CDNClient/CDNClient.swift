//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An uploaded file.
public struct UploadedFile: Decodable {
    public let fileURL: URL
    public let thumbnailURL: URL?

    public init(fileURL: URL, thumbnailURL: URL? = nil) {
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
    }
}

/// The CDN client is responsible to upload files to a CDN.
public protocol CDNClient {
    static var maxAttachmentSize: Int64 { get }

    /// Uploads attachment as a multipart/form-data and returns only the uploaded remote file.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the uploaded file's information.
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    )

    /// Uploads attachment as a multipart/form-data and returns the uploaded remote file and its thumbnail.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the uploaded file's information.
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    )
    
    /// Uploads standalone attachment as a multipart/form-data and returns the uploaded remote file and its thumbnail.
    /// - Parameters:
    ///   - attachment: An attachment to upload.
    ///   - progress: A closure that broadcasts upload progress.
    ///   - completion: Returns the uploaded file's information.
    func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    )

    /// Deletes the attachment from the CDN, given the remote URL.
    /// - Parameters:
    ///   - remoteUrl: The remote url of the attachment.
    ///   - completion: Returns an error in case the delete operation fails.
    func deleteAttachment(
        remoteUrl: URL,
        completion: @escaping (Error?) -> Void
    )
}

public extension CDNClient {
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        uploadAttachment(attachment, progress: progress, completion: { (result: Result<URL, Error>) in
            switch result {
            case let .success(url):
                completion(.success(UploadedFile(fileURL: url, thumbnailURL: nil)))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }
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

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        uploadAttachment(attachment, progress: progress, completion: { (result: Result<UploadedFile, Error>) in
            switch result {
            case let .success(file):
                completion(.success(file.fileURL))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        guard
            let uploadingState = attachment.uploadingState,
            let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
            return completion(.failure(ClientError.AttachmentUploading(id: attachment.id)))
        }
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(with: attachment.id.cid, type: attachment.type)
        
        uploadAttachment(
            endpoint: endpoint,
            fileData: fileData,
            uploadingState: uploadingState,
            progress: progress,
            completion: completion
        )
    }
    
    func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        guard
            let uploadingState = attachment.uploadingState,
            let fileData = try? Data(contentsOf: uploadingState.localFileURL) else {
            return completion(.failure(ClientError.Unknown()))
        }

        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(type: attachment.type)
        
        uploadAttachment(
            endpoint: endpoint,
            fileData: fileData,
            uploadingState: uploadingState,
            progress: progress,
            completion: completion
        )
    }

    func deleteAttachment(
        remoteUrl: URL,
        completion: @escaping (Error?) -> Void
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
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadedFile, Error>) -> Void
    ) {
        // Encode locally stored attachment into multipart form data
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
