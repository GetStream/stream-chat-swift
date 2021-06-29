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

    /// An attachment type.
    @NSManaged private var type: String
    var attachmentType: AttachmentType {
        get { .init(rawValue: type) }
        set { type = newValue.rawValue }
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
    /// An attachment raw `Data`.
    @NSManaged var data: Data?
    
    // MARK: - Relationships
    
    @NSManaged var message: MessageDTO
    @NSManaged var channel: ChannelDTO

    override func willSave() {
        super.willSave()

        // When attachment changed, we need to propagate this change up to holding message
        if hasPersistentChangedValues, !message.hasChanges {
            // this will not change object, but mark it as dirty, triggering updates
            message.id = message.id
        }
    }
    
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
        payload: MessageAttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO {
        guard let messageDTO = message(id: id.messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: id.messageId)
        }

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        
        dto.attachmentType = payload.type
        dto.data = try JSONEncoder.default.encode(payload.payload)
        dto.channel = channelDTO
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

        guard let channelDTO = channel(cid: id.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: id.cid)
        }

        let dto = AttachmentDTO.loadOrCreate(id: id, context: self)
        
        dto.attachmentType = attachment.type

        dto.localURL = attachment.localFileURL
        dto.localState = attachment.localFileURL == nil ? .uploaded : .pendingUpload

        dto.data = try JSONEncoder.stream.encode(attachment.payload?.asAnyEncodable)
        dto.channel = channelDTO
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

    func asModel<T: Decodable>(payloadType: T.Type = T.self) -> _ChatMessageAttachment<T>? {
        guard
            let payload = payload(ofType: payloadType)
        else { return nil }

        return .init(
            id: attachmentID,
            type: attachmentType,
            payload: payload,
            uploadingState: uploadingState
        )
    }

    /// Helper decoding method that logs error only if object exists.
    /// Returns `nil` if `Data` for decoding is `nil`.
    func payload<T: Decodable>(ofType type: T.Type = T.self) -> T? {
        guard let data = data else { return nil }

        do {
            return try JSONDecoder.default.decode(type, from: data)
        } catch {
            log.error(
                "Failed to decode attachment of type:\(type) with hash: <\(id)>, "
                    + "falling back to ChatMessageCustomAttachment."
                    + "Error: \(error)"
            )
            return nil
        }
    }
}

extension AttachmentDTO {
    /// Snapshots the current state of `AttachmentDTO` and returns an immutable model object from it.
    func asAnyModel() -> AnyChatMessageAttachment? {
        let attachment: AnyChatMessageAttachment?

        switch attachmentType {
        case .image:
            attachment = asModel(payloadType: ImageAttachmentPayload.self)?.asAnyAttachment
        case .file:
            attachment = asModel(payloadType: FileAttachmentPayload.self)?.asAnyAttachment
        case .video:
            attachment = asModel(payloadType: VideoAttachmentPayload.self)?.asAnyAttachment
        case .giphy:
            attachment = asModel(payloadType: GiphyAttachmentPayload.self)?.asAnyAttachment
        case .linkPreview:
            attachment = asModel(payloadType: LinkAttachmentPayload.self)?.asAnyAttachment
        default:
            attachment = data.map {
                .init(
                    id: attachmentID,
                    type: attachmentType,
                    payload: $0 as Any,
                    uploadingState: uploadingState
                )
            }
        }

        if attachment == nil {
            log.error("Failed to decode attachment of type: \(attachmentType)")
        }

        return attachment
    }
    
    /// Snapshots the current state of `AttachmentDTO` and returns its representation for used in API calls.
    /// It's possible to introduce custom attachment types outside the SDK.
    /// That is why `RawJSON` object is used for sending it to backend because SDK doesn't know the structure of custom attachment.
    func asRequestPayload() -> MessageAttachmentPayload? {
        guard
            let data = data,
            let payload = try? JSONDecoder.default.decode(RawJSON.self, from: data)
        else {
            log.error("Internal error. Unable to decode attachment `data` for sending to backend.")
            return nil
        }

        return .init(type: attachmentType, payload: payload)
    }

    func update(uploadedFileURL: URL) {
        switch attachmentType {
        case .image:
            guard var image: ImageAttachmentPayload = payload() else {
                log.assertionFailure(
                    "Image payload must be decoded to provide the `imageURL` before sending"
                )
                return
            }
            image.imageURL = uploadedFileURL
            data = try? JSONEncoder.stream.encode(image)
        case .video:
            guard var video: VideoAttachmentPayload = payload() else {
                log.assertionFailure(
                    "Video payload must be decoded to provide the `videoURL` before sending"
                )
                return
            }
            video.videoURL = uploadedFileURL
            data = try? JSONEncoder.stream.encode(video)
        default:
            guard var file: FileAttachmentPayload = payload() else {
                log.assertionFailure(
                    "File payload must be decoded to provide the `assetURL` before sending"
                )
                return
            }
            file.assetURL = uploadedFileURL
            data = try? JSONEncoder.stream.encode(file)
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

    class AttachmentDecoding: ClientError {}
    
    class AttachmentUploading: ClientError {
        init(id: AttachmentId) {
            super.init(
                "Failed to upload attachment with id: \(id)"
            )
        }
    }
}
