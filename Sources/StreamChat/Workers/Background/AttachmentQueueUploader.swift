//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for attachments in a `.pendingUpload` state and uploads data from `localURL` to backend.
///
/// Uploading of the attachment has the following phases:
///     1. When an attachment with `pendingUpload` state local state appears in the db,
///     the uploaded enqueues it in the uploading queue.
///     2. When the attachment is being uploaded, its local state reflects the progress `.uploading(progress: [0, 1])`.
///     The message state is also updated so FRC receive message updates when attachments are changed.
///     3. If the operation is successful the local state of the attachment is changed to `.uploaded`.
///     If the operation fails the local state is set to `.uploadedFailed`.
///
// TODO:
/// - Upload attachments in order declared by `locallyCreatedAt`
/// - Start uploading attachments when connection status changes (offline -> online)
///
class AttachmentQueueUploader: Worker {
    @Atomic private var pendingAttachmentIDs: Set<AttachmentId> = []

    private let observer: StateLayerDatabaseObserver<ListResult, AttachmentDTO, AttachmentDTO>
    private let attachmentPostProcessor: UploadedAttachmentPostProcessor?
    private let attachmentUpdater = AnyAttachmentUpdater()
    private let attachmentStorage = AttachmentStorage()
    private let eventCenter: EventNotificationCenter
    private var continuations = [AttachmentId: CheckedContinuation<UploadedAttachment, Error>]()
    private let queue = DispatchQueue(label: "co.getStream.ChatClient.AttachmentQueueUploader", target: .global(qos: .utility))
    private var fileUploadConfig: AppSettings.UploadConfig?
    private var imageUploadConfig: AppSettings.UploadConfig?

    var minSignificantUploadingProgressChange: Double = 0.05

    init(
        database: DatabaseContainer,
        apiClient: APIClient,
        attachmentPostProcessor: UploadedAttachmentPostProcessor?,
        eventCenter: EventNotificationCenter
    ) {
        observer = StateLayerDatabaseObserver(
            context: database.backgroundReadOnlyContext,
            fetchRequest: AttachmentDTO.pendingUploadFetchRequest()
        )
        
        self.attachmentPostProcessor = attachmentPostProcessor
        self.eventCenter = eventCenter

        super.init(database: database, apiClient: apiClient)

        startObserving()
    }
    
    func setAppSettings(_ appSettings: AppSettings?) {
        queue.async { [weak self] in
            self?.fileUploadConfig = appSettings?.fileUploadConfig
            self?.imageUploadConfig = appSettings?.imageUploadConfig
        }
    }

    // MARK: - Private

    private func startObserving() {
        do {
            let items = try observer.startObserving(onContextDidChange: { [weak self] _, changes in
                self?.handleChanges(changes: changes)
            })
            let changes = items.map { ListChange.insert($0, index: .init(item: 0, section: 0)) }
            handleChanges(changes: changes)
        } catch {
            log.error("Failed to start AttachmentUploader worker. \(error)")
        }
    }

    private func handleChanges(changes: [ListChange<AttachmentDTO>]) {
        guard !changes.isEmpty else { return }

        // Only start uploading attachment when inserted and it is present in pendingAttachmentIds
        database.backgroundReadOnlyContext.perform { [weak self] in
            self?._pendingAttachmentIDs.mutate { pendingAttachmentIDs in
                let newAttachmentIds = Set(changes.attachmentIDs).subtracting(pendingAttachmentIDs)
                newAttachmentIds.forEach {
                    pendingAttachmentIDs.insert($0)
                }
                newAttachmentIds.forEach { id in
                    self?.uploadAttachment(with: id)
                }
            }
        }
    }

    private func uploadAttachment(with id: AttachmentId) {
        prepareAttachmentForUpload(with: id) { [weak self] result in
            switch result {
            case .failure(let error):
                if error is ClientError.AttachmentDoesNotExist {
                    self?.removePendingAttachment(with: id, result: .failure(error))
                } else {
                    self?.updateAttachmentIfNeeded(
                        attachmentId: id,
                        uploadedAttachment: nil,
                        newState: .uploadingFailed,
                        completion: {
                            self?.removePendingAttachment(with: id, result: .failure(error))
                        }
                    )
                }
            case .success(let attachment):
                self?.apiClient.uploadAttachment(
                    attachment,
                    progress: {
                        self?.updateAttachmentIfNeeded(
                            attachmentId: id,
                            uploadedAttachment: nil,
                            newState: .uploading(progress: $0),
                            completion: {}
                        )
                    },
                    completion: { result in
                        self?.updateAttachmentIfNeeded(
                            attachmentId: id,
                            uploadedAttachment: result.value,
                            newState: result.error == nil ? .uploaded : .uploadingFailed,
                            completion: {
                                self?.removePendingAttachment(with: id, result: result)
                            }
                        )
                    }
                )
            }
        }
    }

    private func prepareAttachmentForUpload(with id: AttachmentId, completion: @escaping (Result<AnyChatMessageAttachment, Error>) -> Void) {
        let attachmentStorage = self.attachmentStorage
        var model: AnyChatMessageAttachment?
        var attachmentLocalURL: URL?
        database.write { session in
            guard let attachment = session.attachment(id: id) else {
                throw ClientError.AttachmentDoesNotExist(id: id)
            }

            if let temporaryURL = attachment.localURL {
                do {
                    let localURL = try attachmentStorage.storeAttachment(id: id, temporaryURL: temporaryURL)
                    attachment.localURL = localURL
                } catch {
                    log.error("Could not copy attachment to local storage: \(error.localizedDescription)", subsystems: .offlineSupport)
                }
            }
            attachmentLocalURL = attachment.localURL
            model = attachment.asAnyModel()
        } completion: { [weak self] error in
            DispatchQueue.main.async {
                if let model {
                    // Attachment uploading state should be validated after preparing the local file (for ensuring the local file persists for retry)
                    if let attachmentLocalURL, self?.isAllowedToUpload(model.type, localURL: attachmentLocalURL) == false {
                        completion(
                            .failure(
                                ClientError.AttachmentUploadBlocked(
                                    id: id,
                                    attachmentType: model.type,
                                    pathExtension: attachmentLocalURL.pathExtension
                                )
                            )
                        )
                    } else {
                        completion(.success(model))
                    }
                } else if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(ClientError.Unknown("Incorrect completion handling in AttachmentQueueUploader")))
                }
            }
        }
    }
    
    private func isAllowedToUpload(_ attachmentType: AttachmentType, localURL: URL) -> Bool {
        switch attachmentType {
        case .image:
            return queue.sync { imageUploadConfig?.isAllowed(localURL: localURL) ?? true }
        case .audio, .file, .unknown, .video, .voiceRecording:
            return queue.sync { fileUploadConfig?.isAllowed(localURL: localURL) ?? true }
        default:
            return true
        }
    }

    private func removePendingAttachment(with id: AttachmentId, result: Result<UploadedAttachment, Error>) {
        _pendingAttachmentIDs.mutate { $0.remove(id) }
        notifyAPIRequestFinished(for: id, result: result)
    }

    private func updateAttachmentIfNeeded(
        attachmentId: AttachmentId,
        uploadedAttachment: UploadedAttachment?,
        newState: LocalAttachmentState,
        completion: @escaping () -> Void = {}
    ) {
        database.write({ [minSignificantUploadingProgressChange, weak self] session in
            guard let attachmentDTO = session.attachment(id: attachmentId) else { return }

            var stateHasChanged: Bool {
                guard
                    case let .uploading(lastProgress) = attachmentDTO.localState,
                    case let .uploading(currentProgress) = newState
                else {
                    return attachmentDTO.localState != newState
                }

                return (currentProgress - lastProgress) >= minSignificantUploadingProgressChange
            }

            guard stateHasChanged else { return }

            // Update attachment local state.
            attachmentDTO.localState = newState

            let message = attachmentDTO.message

            // When all attachments finish uploading, mark message pending send
            if newState == .uploaded {
                let allAttachmentsAreUploaded = message.attachments
                    .filter { $0.localState != .uploaded }
                    .isEmpty

                // We only want to make a message to be resent when it is in failed state
                // If we did not check the state, when editing a message, it would resend an existing message
                if allAttachmentsAreUploaded && message.localMessageState == .sendingFailed {
                    message.localMessageState = .pendingSend
                }

                self?.eventCenter.process(AllAttachmentsUploadedEvent(message: try message.asModel()))
            }
            
            // If attachment failed upload, mark message as failed
            if newState == .uploadingFailed {
                message.localMessageState = .sendingFailed
            }

            if var uploadedAttachment = uploadedAttachment {
                self?.updateRemoteUrl(of: &uploadedAttachment)
                if let processedAttachment = self?.attachmentPostProcessor?.process(uploadedAttachment: uploadedAttachment) {
                    uploadedAttachment = processedAttachment
                }
                attachmentDTO.data = uploadedAttachment.attachment.payload
                self?.removeDataFromLocalStorage(for: attachmentId)
            }
        }, completion: {
            if let error = $0 {
                log.error("Error changing localState for attachment with id \(attachmentId) to `\(newState)`: \(error)")
            }
            completion()
        })
    }

    /// Update the remote url for each attachment payload type. Every other payload
    /// update should be handled by the ``AttachmentUploader``.
    private func updateRemoteUrl(of uploadedAttachment: inout UploadedAttachment) {
        var attachment = uploadedAttachment.attachment

        attachmentUpdater.update(&attachment, forPayload: ImageAttachmentPayload.self) { payload in
            payload.imageURL = uploadedAttachment.remoteURL
        }

        attachmentUpdater.update(&attachment, forPayload: VideoAttachmentPayload.self) { payload in
            payload.videoURL = uploadedAttachment.remoteURL
            payload.thumbnailURL = uploadedAttachment.thumbnailURL
        }

        attachmentUpdater.update(&attachment, forPayload: AudioAttachmentPayload.self) { payload in
            payload.audioURL = uploadedAttachment.remoteURL
        }

        attachmentUpdater.update(&attachment, forPayload: FileAttachmentPayload.self) { payload in
            payload.assetURL = uploadedAttachment.remoteURL
        }

        attachmentUpdater.update(&attachment, forPayload: VoiceRecordingAttachmentPayload.self) { payload in
            payload.voiceRecordingURL = uploadedAttachment.remoteURL
        }

        uploadedAttachment.attachment = attachment
    }

    private func removeDataFromLocalStorage(for attachmentId: AttachmentId) {
        database.write { [weak attachmentStorage] session in
            guard let attachmentLocalURL = session.attachment(id: attachmentId)?.localURL else { return }
            attachmentStorage?.removeAttachment(at: attachmentLocalURL)
        }
    }
}

private extension Array where Element == ListChange<AttachmentDTO> {
    var attachmentIDs: [AttachmentId] {
        compactMap {
            switch $0 {
            case let .insert(dto, _), let .update(dto, _):
                return dto.attachmentID
            case .move, .remove:
                return nil
            }
        }
    }
}

private class AttachmentStorage {
    enum Constants {
        static let path = "LocalAttachments"
    }

    private let fileManager: FileManager
    private lazy var baseURL: URL = {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        return base.appendingPathComponent(Constants.path)
    }()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        do {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        } catch {
            log.error("Could not create a directory to store attachments: \(error.localizedDescription)")
        }
    }

    /// Since iOS 8, we cannot use absolute paths to access resources because the intermediate folders can change between sessions/app runs. The content of it, when
    /// using `.documentsDirectory`, is stable though.
    /// Because of that, if the file is already in our storage, the only thing we will do is to return a fresh and valid url to access it.
    func storeAttachment(id: AttachmentId, temporaryURL: URL) throws -> URL {
        // The file name should be composed by the id of the attachment so that it is unique.
        let fileExtension = temporaryURL.pathExtension
        let attachmentId = [id.cid.rawValue, id.messageId, String(id.index)].joined(separator: "-")
        let fileId = "\(attachmentId).\(fileExtension)"
        let sandboxedURL = baseURL.appendingPathComponent(fileId)

        // If the attachment is already sandboxed, return it.
        if fileExists(at: sandboxedURL) {
            return sandboxedURL
        }

        // If not, copy the data of the temporary url to the sandbox directory.
        try Data(contentsOf: temporaryURL).write(to: sandboxedURL)
        return sandboxedURL
    }

    func removeAttachment(at localURL: URL) {
        guard fileExists(at: localURL) else { return }
        do {
            try fileManager.removeItem(at: localURL)
        } catch {
            log.info("Unable to remove attachment at \(localURL): \(error.localizedDescription)")
        }
    }

    private func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}

// MARK: - Chat State Layer

extension AttachmentQueueUploader {
    func waitForAPIRequest(attachmentId: AttachmentId) async throws -> UploadedAttachment {
        try await withCheckedThrowingContinuation { continuation in
            registerContinuation(for: attachmentId, continuation: continuation)
        }
    }
    
    private func registerContinuation(
        for attachmentId: AttachmentId,
        continuation: CheckedContinuation<UploadedAttachment, Error>
    ) {
        queue.async {
            self.continuations[attachmentId] = continuation
        }
    }
    
    private func notifyAPIRequestFinished(
        for attachmentId: AttachmentId,
        result: Result<UploadedAttachment, Error>
    ) {
        queue.async {
            guard let continuation = self.continuations.removeValue(forKey: attachmentId) else { return }
            continuation.resume(with: result)
        }
    }
}
