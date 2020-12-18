//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    @NSManaged var title: String
    /// An author.
    @NSManaged var author: String?
    /// A description text.
    @NSManaged var text: String?
    /// A type (see `AttachmentType`).
    @NSManaged var type: String?
    /// Actions from a command (see `AttachmentAction`, `Command`).
    @NSManaged var actions: Data?
    /// A URL.
    @NSManaged var url: URL?
    /// An image URL.
    @NSManaged var imageURL: URL?
    /// An image preview URL.
    @NSManaged var imagePreviewURL: URL?
    /// A file description (see `AttachmentFile`).
    @NSManaged var file: Data?
    /// An extra data for the attachment.
    @NSManaged var extraData: Data
    
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

    func saveAttachment<ExtraData: AttachmentExtraData>(
        payload: AttachmentPayload<ExtraData>,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        dto.localURL = nil
        dto.localState = nil
        dto.title = payload.title
        dto.author = payload.author
        dto.text = payload.text
        dto.type = payload.type.rawValue
        dto.actions = try JSONEncoder.stream.encode(payload.actions)
        dto.url = payload.url
        dto.imageURL = payload.imageURL
        dto.imagePreviewURL = payload.imagePreviewURL
        dto.file = payload.file == nil ? nil : try JSONEncoder.stream.encode(payload.file)
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.channel = channelDTO
        dto.message = messageDTO
        
        return dto
    }
    
    func createNewAttachment<ExtraData: ExtraDataTypes>(
        seed: _ChatMessageAttachment<ExtraData>.Seed,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        dto.localURL = seed.localURL
        dto.localState = .pendingUpload
        dto.type = seed.type.rawValue
        dto.extraData = try JSONEncoder.default.encode(seed.extraData)
        dto.title = seed.fileName
        dto.file = try JSONEncoder.default.encode(seed.file)

        dto.author = nil
        dto.text = nil
        dto.actions = nil
        dto.url = nil
        dto.imageURL = nil
        dto.imagePreviewURL = nil

        dto.channel = channelDTO
        dto.message = messageDTO
        
        return dto
    }
}

extension AttachmentDTO {
    /// Snapshots the current state of `AttachmentDTO` and returns an immutable model object from it.
    func asModel<ExtraData: ExtraDataTypes>() -> _ChatMessageAttachment<ExtraData> { .create(fromDTO: self) }
    
    /// Snapshots the current state of `AttachmentDTO` and returns its representation for used in API calls.
    func asRequestPayload<ExtraData: AttachmentExtraData>() -> AttachmentRequestBody<ExtraData> { .create(fromDTO: self) }
}

private extension _ChatMessageAttachment {
    /// Create a ChatMessageAttachment  struct from its DTO
    static func create(fromDTO dto: AttachmentDTO) -> _ChatMessageAttachment {
        let extraData: ExtraData.Attachment
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.Attachment.self, from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for Attachment with hash: <\(dto.attachmentID)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = .defaultValue
        }
        
        return .init(
            id: dto.attachmentID,
            localURL: dto.localURL,
            localState: dto.localState,
            title: dto.title,
            author: dto.author,
            text: dto.text,
            type: .init(rawValue: dto.type),
            actions: dto.decoded([AttachmentAction].self, from: dto.actions) ?? [],
            url: dto.url,
            imageURL: dto.imageURL,
            imagePreviewURL: dto.imagePreviewURL,
            file: dto.decoded(AttachmentFile.self, from: dto.file),
            extraData: extraData
        )
    }
}

private extension AttachmentRequestBody {
    /// Create a ChatMessageAttachment  struct from its DTO
    static func create(fromDTO dto: AttachmentDTO) -> AttachmentRequestBody {
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for Attachment with hash: <\(dto.attachmentID)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = .defaultValue
        }

        let type = AttachmentType(rawValue: dto.type)
        
        return .init(
            type: type,
            title: dto.title,
            url: dto.url,
            imageURL: dto.imageURL,
            file: type == .image ? nil : dto.decoded(AttachmentFile.self, from: dto.file),
            extraData: extraData
        )
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
