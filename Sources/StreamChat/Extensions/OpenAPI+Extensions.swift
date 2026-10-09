//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Forwards member access to a nested generated model.
///
/// The generator's `optimized_models` option decodes a model whose JSON embeds another model's
/// fields, such as `FullUserResponse` embedding a user, into one nested property (`user`) instead
/// of repeating those fields. Conforming lets call sites keep reading `fullUser.name` instead of
/// `fullUser.user.name`. It is a protocol because `@dynamicMemberLookup` has to be declared on the
/// type itself, and the generated declarations can't be edited.
@dynamicMemberLookup
protocol OpenAPIModelNesting {
    associatedtype NestedModel
    var nestedModel: NestedModel { get }
}

extension OpenAPIModelNesting {
    subscript<Value>(dynamicMember keyPath: KeyPath<NestedModel, Value>) -> Value {
        nestedModel[keyPath: keyPath]
    }
}

extension FullUserResponse: OpenAPIModelNesting {
    var nestedModel: UserPayload { user }
}

extension MessageWithChannelResponse: OpenAPIModelNesting {
    var nestedModel: MessageResponse { message }
}

extension SearchResultMessage: OpenAPIModelNesting {
    var nestedModel: MessageResponse { message }
}

extension ThreadStateResponse: OpenAPIModelNesting {
    var nestedModel: ThreadResponse { thread }
}
