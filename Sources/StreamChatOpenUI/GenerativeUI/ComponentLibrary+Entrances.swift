//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
extension ComponentLibrary {
    // The library with each of its parts coming in as it shows, as StreamChatAI brings in the
    // parts of a reply's UI and the app's components.
    var withEntrances: ComponentLibrary {
        ComponentLibrary(
            root: root,
            components: components.map { definition in
                guard let renderer = definition.renderer else { return definition }
                return OpenUIComponentDefinition(definition.schema) { context in
                    renderer(context).aiUIEntrance()
                }
            },
            componentGroups: componentGroups,
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: customActions
        )
    }
}
