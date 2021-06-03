//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
class AttachmentUploader: Worker {
    @Atomic private var pendingAttachmentIDs: Set<AttachmentId> = []

    private let observer: ListDatabaseObserver<AttachmentDTO, AttachmentDTO>

    var minSignificantUploadingProgressChange: Double = 0.05

    override init(database: DatabaseContainer, apiClient: APIClient) {
        observer = .init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: AttachmentDTO.pendingUploadFetchRequest(),
            itemCreator: { $0 }
        )

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
        
        var wasEmpty: Bool!
        _pendingAttachmentIDs.mutate { pendingAttachmentIDs in
            wasEmpty = pendingAttachmentIDs.isEmpty
            changes.pendingUploadAttachmentIDs.forEach { pendingAttachmentIDs.insert($0) }
        }
        if wasEmpty {
            uploadNextAttachment()
        }
    }

    private func uploadNextAttachment() {
        database.write { [weak self] session in
            guard
                let attachmentID = self?.pendingAttachmentIDs.first
            else { return }

            guard
                let attachment = session.attachment(id: attachmentID)?.asAnyModel()
            else {
                self?.removeAttachmentIDAndContinue(attachmentID)
                return
            }

            self?.apiClient.uploadAttachment(
                attachment,
                progress: {
                    self?.updateAttachmentIfNeeded(
                        attachmentID,
                        newState: .uploading(progress: $0)
                    )
                },
                completion: { result in
                    self?.updateAttachmentIfNeeded(
                        attachmentID,
                        newState: result.error == nil ? .uploaded : .uploadingFailed,
                        attachmentUpdates: { attachmentDTO in
                            guard case let .success(url) = result else { return }
                            attachmentDTO.update(uploadedFileURL: url)
                        },
                        completion: {
                            self?.removeAttachmentIDAndContinue(attachmentID)
                        }
                    )
                }
            )
        }
    }

    private func removeAttachmentIDAndContinue(_ id: AttachmentId) {
        _pendingAttachmentIDs.mutate { $0.remove(id) }
        uploadNextAttachment()
    }

    private func updateAttachmentIfNeeded(
        _ id: AttachmentId,
        newState: LocalAttachmentState,
        attachmentUpdates: @escaping (AttachmentDTO) throws -> Void = { _ in },
        completion: @escaping () -> Void = {}
    ) {
        database.write({ [minSignificantUploadingProgressChange] session in
            guard let attachmentDTO = session.attachment(id: id) else { return }

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

            // Apply further attachment updates.
            try attachmentUpdates(attachmentDTO)
        }, completion: {
            if let error = $0 {
                log.error("Error changing localState for attachment with id \(id) to `\(newState)`: \(error)")
            }
            completion()
        })
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
