//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine

// Lets a view follow an object it reads from without naming the object's type, such as the
// AIConversation an AIConversationView shows.
@available(iOS 15.0, macOS 12.0, *)
final class AIObservedChanges: ObservableObject {
    // Follows nothing, for a view that is given what it shows.
    @MainActor static let none = AIObservedChanges(ObservableObjectPublisher())

    let objectWillChange: ObservableObjectPublisher

    init(_ objectWillChange: ObservableObjectPublisher) {
        self.objectWillChange = objectWillChange
    }
}
