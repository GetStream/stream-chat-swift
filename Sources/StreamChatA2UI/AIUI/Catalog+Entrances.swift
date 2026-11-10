//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension Catalog {
    // The catalog with each of its components coming in as it shows, as StreamChatAI brings in
    // the parts of a reply's UI.
    var withEntrances: Catalog {
        Catalog(
            catalogId: catalogId,
            title: title,
            description: description,
            instructions: instructions,
            components: components.values.map(\.withEntrance),
            functions: Array(functions.values)
        )
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension ComponentDefinition {
    var withEntrance: ComponentDefinition {
        let builder = builder
        return ComponentDefinition(
            name: name,
            description: description,
            properties: propertySchema,
            required: requiredProperties,
            allowedParents: allowedParents,
            allowedChildren: allowedChildren,
            examples: examples
        ) { context in
            AnyView(builder(context).aiUIEntrance())
        }
    }
}
