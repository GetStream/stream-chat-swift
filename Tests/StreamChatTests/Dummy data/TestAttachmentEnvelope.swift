//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

struct TestAttachmentEnvelope: AttachmentEnvelope, Equatable, Decodable {
    var type: AttachmentType = .custom(.unique)
    let name: String
    let number: Int
    
    init(name: String = .unique, number: Int = .random(in: 1...100)) {
        self.name = name
        self.number = number
    }
}
