//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(AttachmentDTO)
class AttachmentDTO: NSManagedObject {
    /// An attachment id.
    @NSManaged private var id: String
    var attachmentID: AttachmentId {
        get { AttachmentId(rawValue: id)! }
        set { id = newValue.rawValue }
    }

    /// An attachment type.
    @NSManaged private var type: String?
    var attachmentType: AttachmentType {
        get { AttachmentType(rawValue: type ?? AttachmentType.unknown.rawValue) }
        set { type = newValue.rawValue }
    }

    /// An attachment local state.
    @NSManaged private var localStateRaw: String
    @NSManaged private var localProgress: Double
    var localState: LocalAttachmentState? {
        get {
            LocalAttachmentState(rawValue: localStateRaw, progress: localProgress)
        }
        set {
            localStateRaw = newValue?.rawValue ?? ""
            localProgress = newValue?.progress ?? 0
        }
    }

    /// An attachment local url.
    @NSManaged var localURL: URL?
    /// An attachment raw `Data`.
    @NSManaged var data: Data
    
    // MARK: - Relationships
    
    @NSManaged var message: MessageDTO

    override func willSave() {
        super.willSave()

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

    static func pendingUploadFetchRequest() -> NSFetchRequest<AttachmentDTO> {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AttachmentDTO.id, ascending: true)]
        request.predicate = NSPredicate(format: "localStateRaw == %@", LocalAttachmentState.pendingUpload.rawValue)
        return request
    }
}

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
        
        dto.localURL = nil
        dto.localState = nil
        
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
}

private extension AttachmentDTO {
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
            log.error("""
                Failed to build uploading state for attachment with id: \(attachmentID).
                Error: \(error.localizedDescription)
            """)
            return nil
        }
    }
}

extension AttachmentDTO {
    /// Snapshots the current state of `AttachmentDTO` and returns an immutable model object from it.
    func asAnyModel() -> AnyChatMessageAttachment {
        .init(
            id: attachmentID,
            type: attachmentType,
            payload: data,
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

    func update(uploadedFileURL: URL) {
        let attachment = asAnyModel()
        let updatedPayload: AnyEncodable
        
        if let image = attachment.attachment(payloadType: ImageAttachmentPayload.self) {
            var payload = image.payload
            payload.imageURL = uploadedFileURL
            updatedPayload = payload.asAnyEncodable
        } else if let video = attachment.attachment(payloadType: VideoAttachmentPayload.self) {
            var payload = video.payload
            payload.videoURL = uploadedFileURL
            updatedPayload = payload.asAnyEncodable
        } else if let audio = attachment.attachment(payloadType: AudioAttachmentPayload.self) {
            var payload = audio.payload
            payload.audioURL = uploadedFileURL
            updatedPayload = payload.asAnyEncodable
        } else if let file = attachment.attachment(payloadType: FileAttachmentPayload.self) {
            var payload = file.payload
            payload.assetURL = uploadedFileURL
            updatedPayload = payload.asAnyEncodable
        } else {
            log.assertionFailure(
                "Attachment of type \(attachment.type) is not supposed to be updated with uploaded file URL."
            )
            return
        }
        
        do {
            data = try JSONEncoder.stream.encode(updatedPayload)
        } catch {
            log.assertionFailure(
                "Failed to encode updated payload for attachment with id \(attachmentID) after uploading."
            )
        }
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

extension ClientError {
    class AttachmentDoesNotExist: ClientError {
        init(id: AttachmentId) {
            super.init("There is no `AttachmentDTO` instance in the DB matching id: \(id).")
        }
    }

    class AttachmentEditing: ClientError {
        init(id: AttachmentId, reason: String) {
            super.init("`AttachmentDTO` with id: \(id) can't be edited (\(reason))")
        }
    }

    class AttachmentDecoding: ClientError {}
    
    class AttachmentUploading: ClientError {
        init(id: AttachmentId) {
            super.init(
                "Failed to upload attachment with id: \(id)"
            )
        }
    }
}
