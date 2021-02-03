//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

    /// An attachment local state.
    @NSManaged private var localStateRaw: String
    @NSManaged private var localProgress: Double
    var localState: LocalAttachmentState? {
        get { LocalAttachmentState(rawValue: localStateRaw, progress: localProgress) }
        set {
            localStateRaw = newValue?.rawValue ?? ""
            localProgress = newValue?.progress ?? 0
        }
    }

    /// An attachment local url.
    @NSManaged var localURL: URL?
    /// A title.
    @NSManaged var title: String?
    /// A file.
    @NSManaged var file: Data?
    
    /// An attachement raw string type.
    @NSManaged var type: String
    /// An attachment raw `Data`.
    @NSManaged var data: Data?
    
    // MARK: - Relationships
    
    @NSManaged var message: MessageDTO
    @NSManaged var channel: ChannelDTO
    
    static func load(id: AttachmentId, context: NSManagedObjectContext) -> AttachmentDTO? {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id.rawValue)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(id: AttachmentId, context: NSManagedObjectContext) -> AttachmentDTO {
        if let existing = Self.load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! AttachmentDTO
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
        payload: AttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }
        
        guard let type = payload.type.rawValue else {
            throw ClientError.MissingAttachmentType(id: id)
        }
        
        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        
        dto.type = type
        dto.data = try JSONEncoder.default.encode(payload.payload)
        dto.channel = channelDTO
        dto.message = messageDTO
        
        dto.localURL = nil
        dto.localState = nil
        
        return dto
    }
    
    func createNewAttachment(
        seed: ChatMessageAttachmentSeed,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }
        
        guard let type = seed.type.rawValue else {
            throw ClientError.MissingAttachmentType(id: id)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        dto.localURL = seed.localURL
        dto.localState = .pendingUpload
        dto.type = type
        dto.title = seed.fileName
        dto.file = try JSONEncoder.default.encode(seed.file)
        
        let attachment = ChatMessageDefaultAttachment(
            id: id,
            type: AttachmentType(rawValue: type),
            localURL: seed.localURL,
            localState: dto.localState,
            title: seed.fileName,
            file: seed.file
        )
        
        dto.data = try JSONEncoder.stream.encode(attachment)

        dto.channel = channelDTO
        dto.message = messageDTO
        
        return dto
    }
}

extension AttachmentDTO {
    /// Snapshots the current state of `AttachmentDTO` and returns an immutable model object from it.
    func asModel() -> ChatMessageAttachment {
        let type = AttachmentType(rawValue: self.type)
        
        switch type {
        case .custom:
            return ChatMessageRawAttachment(id: attachmentID, type: type, data: data)
        default:
            guard
                let data = data,
                var defaultAttachment = try? JSONDecoder.default.decode(ChatMessageDefaultAttachment.self, from: data)
            else {
                log.error(
                    "Unable to decode `ChatMessageDefaultAttachment` for built-in type." +
                        "Falling back to ChatMessageCustomAttachment"
                )
                return ChatMessageRawAttachment(id: attachmentID, type: type, data: self.data)
            }
            defaultAttachment.id = attachmentID
            defaultAttachment.localURL = localURL
            defaultAttachment.localState = localState
            return defaultAttachment
        }
    }
    
    /// Returns an object pending to upload.
    func asUploadingModel() -> ChatMessageDefaultAttachment? {
        guard
            let localState = localState,
            let localURL = localURL
        else {
            log.error("Failed to create pending upload model.")
            return nil
        }
        
        return ChatMessageDefaultAttachment(
            id: attachmentID,
            type: AttachmentType(rawValue: type),
            localURL: localURL,
            localState: localState,
            title: title ?? ""
        )
    }
    
    /// Snapshots the current state of `AttachmentDTO` and returns its representation for used in API calls.
    /// It's possible to introduce custom attachment types outside the SDK.
    /// That is why `RawJSON` object is used for sending it to backend because SDK doesn't know the structure of custom attachment.
    func asRequestPayload() -> RawJSON? { .create(fromDTO: self) }
}

private extension RawJSON {
    static func create(fromDTO dto: AttachmentDTO) -> RawJSON? {
        if let data = dto.data,
            let rawJSON = try? JSONDecoder.default.decode(RawJSON.self, from: data) {
            return rawJSON
        } else {
            log.error("Internal error. Unable to decode attachment `data` for sending to backend.")
            return nil
        }
    }
}

private extension AttachmentDTO {
    /// Helper decoding method that logs error only if object exists.
    /// Returns `nil` if `Data` for decoding is `nil`.
    func decoded<T: Decodable>(
        _ type: T.Type,
        from data: Data?
    ) -> T? {
        if let data = data {
            let object: T?
            do {
                object = try JSONDecoder.default.decode(type, from: data)
                return object
            } catch {
                log.error(
                    "Failed to decode \(type) for attachment with hash: <\(id)>, using default value instead. "
                        + "Error: \(error)"
                )
                return nil
            }
        } else {
            return nil
        }
    }
}

extension LocalAttachmentState {
    var rawValue: String {
        switch self {
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
        default:
            return nil
        }
    }
}

extension ClientError {
    class MissingAttachmentType: ClientError {
        init(id: AttachmentId) {
            super.init("Attachment type is missing for attachment with id: \(id).")
        }
    }
    
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
}
