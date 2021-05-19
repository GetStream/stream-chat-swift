//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// API client that handles working with content (e.g. uploading attachments)
public protocol CDNClient {
    /// - Parameters:
    ///   - attachment: An attachment to upload
    ///   - progress: A closure that broadcasts upload progress
    ///   - completion: Returns uploading result on upload completion or failure
    func uploadAttachment(
        _ attachment: ChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    )
}

/// Default implementation of CDNClient
class DefaultCDNClient: CDNClient {
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
      
    /// Uploads attachment as a multipart/form-data
    /// - Parameters:
    ///   - attachment: An attachment to upload
    ///   - progress: A closure that broadcasts upload progress
    ///   - completion: Returns uploading result on upload completion or failure
    func uploadAttachment(
        _ attachment: ChatMessageAttachment,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
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
            mimeType: uploadingState.localFileURL.attachmentFile?.type.mimeType
        )
        let endpoint = Endpoint<FileUploadPayload>.uploadAttachment(with: attachment.id, type: attachment.type)
        
        encoder.encodeRequest(for: endpoint) { [unowned self] (requestResult) in
            var urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error)
                completion(.failure(error))
                return
            }
            
            let data = multipartFormData.getMultipartFormData()
            urlRequest.addValue("multipart/form-data; boundary=\(MultipartFormData.boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data
            
            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let decodedResponse: FileUploadPayload = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )
                    completion(.success(decodedResponse.file))
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
