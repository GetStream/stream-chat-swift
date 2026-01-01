//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(AttachmentDTO)
class AttachmentDTO: NSManagedObject {
    /// An attachment id.
    @NSManaged private var id: String?
    var attachmentID: AttachmentId? {
        get {
            guard let id = self.id else { return nil }
            return AttachmentId(rawValue: id)
        }
        set { id = newValue?.rawValue }
    }

    /// An attachment type.
    @NSManaged private var type: String?
    var attachmentType: AttachmentType {
        get { AttachmentType(rawValue: type ?? AttachmentType.unknown.rawValue) }
        set { type = newValue.rawValue }
    }

    /// An attachment local upload state.
    @NSManaged private var localStateRaw: String?
    @NSManaged private var localProgress: Double
    var localState: LocalAttachmentState? {
        get {
            guard let localStateRaw = self.localStateRaw else { return nil }
            return LocalAttachmentState(rawValue: localStateRaw, progress: localProgress)
        }
        set {
            localStateRaw = newValue?.rawValue
            localProgress = newValue?.progress ?? 0
        }
    }
    
    /// An attachment local download state.
    @NSManaged private var localDownloadStateRaw: String?
    var localDownloadState: LocalAttachmentDownloadState? {
        get {
            guard let localDownloadStateRaw else { return nil }
            return LocalAttachmentDownloadState(rawValue: localDownloadStateRaw, progress: localProgress)
        }
        set {
            localDownloadStateRaw = newValue?.rawValue
            localProgress = newValue?.progress ?? 0
        }
    }

    /// An attachment local url.
    @NSManaged var localURL: URL?
    
    /// An attachment local relative path used for storing downloaded attachments.
    @NSManaged var localRelativePath: String?
    
    /// An attachment raw `Data`.
    @NSManaged var data: Data

    func clearLocalState() {
        localDownloadState = nil
        localRelativePath = nil
        localState = nil
        localURL = nil
    }
    
    // MARK: - Relationships

    @NSManaged var message: MessageDTO

    override func willSave() {
        super.willSave()

        guard !isDeleted && !message.isDeleted else {
            return
        }

        // When attachment changed, we need to propagate this change up to holding message
        if hasPersistentChangedValues, !message.hasChanges {
            // this will not change object, but mark it as dirty, triggering updates
            message.id = message.id
        }
    }

    static func load(id: AttachmentId, context: NSManagedObjectContext) -> AttachmentDTO? {
        load(by: id.rawValue, context: context).first
    }

    static func loadOrCreate(id: AttachmentId, context: NSManagedObjectContext) -> AttachmentDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id.rawValue)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.attachmentID = id
        return new
    }

    static func downloadedFetchRequest() -> NSFetchRequest<AttachmentDTO> {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AttachmentDTO.id, ascending: true)]
        request.predicate = NSPredicate(format: "localDownloadStateRaw == %@", LocalAttachmentDownloadState.downloaded.rawValue)
        return request
    }
    
    static func pendingUploadFetchRequest() -> NSFetchRequest<AttachmentDTO> {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AttachmentDTO.id, ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "localStateRaw == %@", LocalAttachmentState.pendingUpload.rawValue),
            NSPredicate(format: "message.draftOfChannel == nil"),
            NSPredicate(format: "message.draftOfThread == nil")
        ])
        return request
    }
    
    static func loadInProgressAttachments(context: NSManagedObjectContext) -> [AttachmentDTO] {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AttachmentDTO.id, ascending: true)]
        request.predicate = NSPredicate(format: "localStateRaw == %@", LocalAttachmentState.uploading(progress: 0).rawValue)
        return load(by: request, context: context)
    }
    
    static func loadAllDownloadedAttachments(context: NSManagedObjectContext) -> [AttachmentDTO] {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AttachmentDTO.id, ascending: true)]
        request.predicate = NSPredicate(format: "localDownloadStateRaw == %@", LocalAttachmentDownloadState.downloaded.rawValue)
        return load(by: request, context: context)
    }
}

// MARK: - Reset Ephemeral Values

extension AttachmentDTO: EphemeralValuesContainer {
    static func resetEphemeralRelationshipValues(in context: NSManagedObjectContext) {}
    
    static func resetEphemeralValuesBatchRequests() -> [NSBatchUpdateRequest] {
        let request = NSBatchUpdateRequest(entityName: AttachmentDTO.entityName)
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "localDownloadStateRaw == %@", LocalAttachmentDownloadState.downloadingFailed.rawValue),
            NSPredicate(format: "localDownloadStateRaw == %@", LocalAttachmentDownloadState.downloading(progress: 0).rawValue)
        ])
        request.propertiesToUpdate = [
            KeyPath.string(\AttachmentDTO.localDownloadStateRaw): NSNull(),
            KeyPath.string(\AttachmentDTO.localRelativePath): NSNull(),
            KeyPath.string(\AttachmentDTO.localStateRaw): NSNull(),
            KeyPath.string(\AttachmentDTO.localProgress): 0,
            KeyPath.string(\AttachmentDTO.localURL): NSNull()
        ]
        return [request]
    }
}

// MARK: - Attachment Database Session

extension NSManagedObjectContext: AttachmentDatabaseSession {
    func attachment(id: AttachmentId) -> AttachmentDTO? {
        AttachmentDTO.load(id: id, context: self)
    }

    func saveAttachment(
        payload: MessageAttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)

        dto.attachmentType = payload.type
        dto.data = try JSONEncoder.default.encode(payload.payload)
        dto.message = messageDTO

        // Keep local state for downloaded attachments
        if dto.localDownloadState == nil {
            dto.clearLocalState()
        }

        return dto
    }

    func createNewAttachment(
        attachment: AnyAttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)

        dto.attachmentType = attachment.type

        dto.localURL = attachment.localFileURL
        dto.localState = attachment.localFileURL == nil ? .uploaded : .pendingUpload

        dto.data = try JSONEncoder.stream.encode(attachment.payload.asAnyEncodable)
        dto.message = messageDTO

        return dto
    }

    func delete(attachment: AttachmentDTO) {
        delete(attachment)
    }
    
    func allLocallyDownloadedAttachments() -> [AttachmentDTO] {
        AttachmentDTO.loadAllDownloadedAttachments(context: self)
    }
}

private extension AttachmentDTO {
    var downloadingState: AttachmentDownloadingState? {
        guard let localDownloadState else { return nil }
        let localFileURL: URL? = {
            guard let localRelativePath, !localRelativePath.isEmpty else { return nil }
            return URL.streamAttachmentLocalStorageURL(forRelativePath: localRelativePath)
        }()
        let file: AttachmentFile? = {
            // Most attachments contain the attachment file information
            if let file = try? JSONDecoder.stream.decode(AttachmentFile.self, from: data) {
                return file
            }
            // Try extracting it from the downloaded file
            if let localFileURL {
                return try? AttachmentFile(url: localFileURL)
            }
            return nil
        }()
        return AttachmentDownloadingState(
            localFileURL: localFileURL,
            state: localDownloadState,
            file: file
        )
    }
    
    var uploadingState: AttachmentUploadingState? {
        guard
            let localURL = localURL,
            let localState = localState
        else { return nil }

        do {
            return .init(
                localFileURL: localURL,
                state: localState,
                file: try AttachmentFile(url: localURL)
            )
        } catch {
            let id = attachmentID?.rawValue ?? ""
            log.error("""
                Failed to build uploading state for attachment with id: \(id) at \(localURL)
                Error: \(error.localizedDescription)
            """)
            return nil
        }
    }
}

extension AttachmentDTO {
    /// Snapshots the current state of `AttachmentDTO` and returns an immutable model object from it.
    func asAnyModel() -> AnyChatMessageAttachment? {
        guard !isDeleted else { return nil }
        
        guard let id = attachmentID else {
            log.debug("Attachment failed to be converted to model because ID is invalid.")
            return nil
        }
        return .init(
            id: id,
            type: attachmentType,
            payload: data,
            downloadingState: downloadingState,
            uploadingState: uploadingState
        )
    }

    /// Snapshots the current state of `AttachmentDTO` and returns its representation for used in API calls.
    /// It's possible to introduce custom attachment types outside the SDK.
    /// That is why `RawJSON` object is used for sending it to backend because SDK doesn't know the structure of custom attachment.
    func asRequestPayload() -> MessageAttachmentPayload? {
        guard
            let payload = try? JSONDecoder.default.decode(RawJSON.self, from: data)
        else {
            log.error("Internal error. Unable to decode attachment `data` for sending to backend.")
            return nil
        }

        return .init(type: attachmentType, payload: payload)
    }
}

extension LocalAttachmentState {
    var rawValue: String {
        switch self {
        case .unknown:
            return ""
        case .pendingUpload:
            return "pendingUpload"
        case .uploading:
            return "uploading"
        case .uploadingFailed:
            return "uploadingFailed"
        case .uploaded:
            return "uploaded"
        }
    }

    var progress: Double {
        switch self {
        case let .uploading(progress):
            return progress
        default:
            return 0
        }
    }

    init?(rawValue: String, progress: Double) {
        switch rawValue {
        case LocalAttachmentState.pendingUpload.rawValue:
            self = .pendingUpload
        case LocalAttachmentState.uploading(progress: 0).rawValue:
            self = .uploading(progress: progress)
        case LocalAttachmentState.uploadingFailed.rawValue:
            self = .uploadingFailed
        case LocalAttachmentState.uploaded.rawValue:
            self = .uploaded
        case LocalAttachmentState.unknown.rawValue:
            self = .unknown
        default:
            self = .unknown
        }
    }
}

extension LocalAttachmentDownloadState {
    var rawValue: String {
        switch self {
        case .downloading:
            return "downloading"
        case .downloadingFailed:
            return "downloadingFailed"
        case .downloaded:
            return "downloaded"
        }
    }
    
    var progress: Double {
        switch self {
        case let .downloading(progress):
            return progress
        default:
            return 0
        }
    }
    
    init?(rawValue: String, progress: Double) {
        switch rawValue {
        case LocalAttachmentDownloadState.downloaded.rawValue:
            self = .downloaded
        case LocalAttachmentDownloadState.downloadingFailed.rawValue:
            self = .downloadingFailed
        case LocalAttachmentDownloadState.downloading(progress: 0).rawValue:
            self = .downloading(progress: progress)
        default:
            return nil
        }
    }
}

extension ClientError {
    final class AttachmentDoesNotExist: ClientError {
        init(id: AttachmentId) {
            super.init("There is no `AttachmentDTO` instance in the DB matching id: \(id).")
        }
    }
    
    final class AttachmentUploadBlocked: ClientError {
        init(id: AttachmentId, attachmentType: AttachmentType, pathExtension: String) {
            super.init("`AttachmentDTO` with \(id) and type \(attachmentType) and path extension \(pathExtension) is blocked on the Stream dashboard.")
        }
    }

    final class AttachmentEditing: ClientError {
        init(id: AttachmentId, reason: String) {
            super.init("`AttachmentDTO` with id: \(id) can't be edited (\(reason))")
        }
    }

    final class AttachmentDecoding: ClientError {}

    final class AttachmentDownloading: ClientError {
        init(id: AttachmentId, reason: String) {
            super.init(
                "Failed to download attachment with id: \(id): \(reason)"
            )
        }
    }
    
    final class AttachmentUploading: ClientError {
        init(id: AttachmentId) {
            super.init(
                "Failed to upload attachment with id: \(id)"
            )
        }
    }
}
