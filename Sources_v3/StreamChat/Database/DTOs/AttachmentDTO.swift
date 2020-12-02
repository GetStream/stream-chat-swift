//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(AttachmentDTO)
class AttachmentDTO: NSManagedObject {
    /// An attachment hash.
    @NSManaged var attachmentHash: String
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
    
    static func load(hash: String, context: NSManagedObjectContext) -> AttachmentDTO? {
        let request = NSFetchRequest<AttachmentDTO>(entityName: AttachmentDTO.entityName)
        request.predicate = NSPredicate(format: "attachmentHash == %@", hash)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(queryHash: String, context: NSManagedObjectContext) -> AttachmentDTO {
        if let existing = Self.load(hash: queryHash, context: context) {
            return existing
        }
        
        let new = AttachmentDTO(context: context)
        return new
    }
}

extension NSManagedObjectContext: AttachmentDatabaseSession {
    func saveAttachment<ExtraData: AttachmentExtraData>(
        payload: AttachmentPayload<ExtraData>,
        messageId: MessageId,
        cid: ChannelId
    ) throws -> AttachmentDTO {
        let dto = AttachmentDTO.loadOrCreate(queryHash: payload.customHash, context: self)
        dto.attachmentHash = payload.customHash
        dto.title = payload.title
        dto.author = payload.author
        dto.text = payload.text
        dto.type = payload.type.rawValue
        dto.actions = payload.actions.isEmpty ? nil : try JSONEncoder.stream.encode(payload.actions)
        dto.url = payload.url
        dto.imageURL = payload.imageURL
        dto.imagePreviewURL = payload.imagePreviewURL
        dto.file = payload.file == nil ? nil : try JSONEncoder.stream.encode(payload.file)
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        
        if let messageDTO = MessageDTO.load(id: messageId, context: self) {
            dto.message = messageDTO
            messageDTO.attachments.insert(dto)
        } else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }
        
        if let channelDTO = ChannelDTO.load(cid: cid, context: self) {
            dto.channel = channelDTO
            channelDTO.attachments.insert(dto)
        } else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }
        
        return dto
    }
    
    func saveAttachment<ExtraData: ExtraDataTypes>(
        attachment: _ChatMessageAttachment<ExtraData>,
        messageId: MessageId,
        cid: ChannelId
    ) throws -> AttachmentDTO {
        let dto = AttachmentDTO.loadOrCreate(queryHash: attachment.hash, context: self)
        dto.attachmentHash = attachment.hash
        dto.title = attachment.title
        dto.author = attachment.author
        dto.text = attachment.text
        dto.type = attachment.type.rawValue
        dto.actions = attachment.actions.isEmpty ? nil : try JSONEncoder.stream.encode(attachment.actions)
        dto.url = attachment.url
        dto.imageURL = attachment.imageURL
        dto.file = attachment.file == nil ? nil : try JSONEncoder.stream.encode(attachment.file)
        dto.extraData = try JSONEncoder.default.encode(attachment.extraData)
        
        if let messageDTO = MessageDTO.load(id: messageId, context: self) {
            dto.message = messageDTO
            messageDTO.attachments.insert(dto)
        } else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }
        
        if let channelDTO = ChannelDTO.load(cid: cid, context: self) {
            dto.channel = channelDTO
            channelDTO.attachments.insert(dto)
        } else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }
        
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
                "Failed to decode extra data for Attachment with hash: <\(dto.attachmentHash)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = .defaultValue
        }
        
        return .init(
            title: dto.title,
            author: dto.author,
            text: dto.text,
            type: .init(rawValue: dto.type),
            actions: dto.decoded([AttachmentAction].self, from: dto.actions) ?? [],
            url: dto.url,
            imageURL: dto.imageURL,
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
                "Failed to decode extra data for Attachment with hash: <\(dto.attachmentHash)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = .defaultValue
        }
        
        return .init(
            type: .init(rawValue: dto.type),
            title: dto.title,
            url: dto.url,
            imageURL: dto.imageURL,
            file: dto.decoded(AttachmentFile.self, from: dto.file),
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
                    "Failed to decode \(type) for attachment with hash: <\(attachmentHash)>, using default value instead. "
                        + "Error: \(error)"
                )
                return nil
            }
        } else {
            return nil
        }
    }
}
