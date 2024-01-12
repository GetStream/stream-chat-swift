//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    private let observer: ListDatabaseObserver<AttachmentDTO, AttachmentDTO>
    private let attachmentPostProcessor: UploadedAttachmentPostProcessor?
    private let attachmentUpdater = AnyAttachmentUpdater()
    private let attachmentStorage = AttachmentStorage()

    var minSignificantUploadingProgressChange: Double = 0.05

    init(database: DatabaseContainer, apiClient: APIClient, attachmentPostProcessor: UploadedAttachmentPostProcessor?) {
        observer = .init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: AttachmentDTO.pendingUploadFetchRequest(),
            itemCreator: { $0 }
        )
        
        self.attachmentPostProcessor = attachmentPostProcessor

        super.init(database: database, apiClient: apiClient)

        startObserving()
    }

    // MARK: - Private

    private func startObserving() {
        do {
            try observer.startObserving()
            observer.onChange = { [weak self] in self?.handleChanges(changes: $0) }
            let changes = observer.items.map { ListChange.insert($0, index: .init(item: 0, section: 0)) }
            handleChanges(changes: changes)
        } catch {
            log.error("Failed to start AttachmentUploader worker. \(error)")
        }
    }

    private func handleChanges(changes: [ListChange<AttachmentDTO>]) {
        guard !changes.isEmpty else { return }

        var wasEmpty: Bool = false
        _pendingAttachmentIDs.mutate { pendingAttachmentIDs in
            wasEmpty = pendingAttachmentIDs.isEmpty
            changes.pendingUploadAttachmentIDs.forEach { pendingAttachmentIDs.insert($0) }
        }
        if wasEmpty {
            uploadNextAttachment()
        }
    }

    private func uploadNextAttachment() {
        guard let attachmentID = pendingAttachmentIDs.first else { return }

        prepareAttachmentForUpload(with: attachmentID) { [weak self] attachment in
            guard let attachment = attachment else {
                self?.removeAttachmentIDAndContinue(attachmentID)
                return
            }

            self?.apiClient.uploadAttachment(
                attachment,
                progress: {
                    self?.updateAttachmentIfNeeded(
                        attachmentId: attachmentID,
                        uploadedAttachment: nil,
                        newState: .uploading(progress: $0),
                        completion: {}
                    )
                },
                completion: { result in
                    self?.updateAttachmentIfNeeded(
                        attachmentId: attachmentID,
                        uploadedAttachment: result.value,
                        newState: result.error == nil ? .uploaded : .uploadingFailed,
                        completion: {
                            self?.removeAttachmentIDAndContinue(attachmentID)
                        }
                    )
                }
            )
        }
    }

    private func prepareAttachmentForUpload(with id: AttachmentId, completion: @escaping (AnyChatMessageAttachment?) -> Void) {
        let attachmentStorage = self.attachmentStorage
        database.write { session in
            guard let attachment = session.attachment(id: id) else { return }

            if let temporaryURL = attachment.localURL {
                do {
                    let localURL = try attachmentStorage.storeAttachment(id: id, temporaryURL: temporaryURL)
                    attachment.localURL = localURL
                } catch {
                    log.error("Could not copy attachment to local storage: \(error.localizedDescription)", subsystems: .offlineSupport)
                }
            }

            let model = attachment.asAnyModel()

            DispatchQueue.main.async {
                completion(model)
            }
        }
    }

    private func removeAttachmentIDAndContinue(_ id: AttachmentId) {
        _pendingAttachmentIDs.mutate { $0.remove(id) }
        uploadNextAttachment()
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
                let allAttachmentsAreUploaded = message.attachments.filter { $0.localState != .uploaded }.isEmpty
                // We only want to make a message to be resent when it is in failed state
                // If we did not check the state, when editing a message, it would resend an existing message
                if allAttachmentsAreUploaded && message.localMessageState == .sendingFailed {
                    message.localMessageState = .pendingSend
                }
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
    var pendingUploadAttachmentIDs: [AttachmentId] {
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
        let fileExtension = temporaryURL.pathExtension
        let fileName = temporaryURL.deletingPathExtension().lastPathComponent
        let attachmentId = [id.cid.rawValue, id.messageId, String(id.index)].joined(separator: "-")
        let fileId = "\(fileName)-\(attachmentId).\(fileExtension)"
        let sandboxedURL = baseURL.appendingPathComponent(fileId)

        guard !fileExists(at: sandboxedURL) else {
            return sandboxedURL
        }

        // Copy data to local path
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
