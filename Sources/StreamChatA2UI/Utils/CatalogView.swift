//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI

/// Renders every example declared by a catalog's components.
///
/// This is a development tool: it exercises each component with a small,
/// self-contained A2UI message stream, which makes it easy to check rendering
/// and interaction without an agent.
@available(iOS 15.0, macOS 12.0, *)
public struct DebugCatalogView: View {
    @StateObject private var model: DebugCatalogModel

    /// The height applied to each example, when set.
    public let itemHeight: CGFloat?

    /// Creates a gallery of the examples of a catalog's components.
    public init(catalog: Catalog, itemHeight: CGFloat? = nil) {
        self.init(catalog: catalog, onAction: nil, itemHeight: itemHeight)
    }

    init(catalog: Catalog, onAction: ((RendererAction) -> Void)?, itemHeight: CGFloat? = nil) {
        self._model = StateObject(wrappedValue: DebugCatalogModel(catalog: catalog, onAction: onAction))
        self.itemHeight = itemHeight
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(model.surfaceIds, id: \.self) { surfaceId in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(surfaceId)
                            .font(.headline)
                        A2UISurface(host: model.processor, surfaceId: surfaceId)
                            .frame(height: itemHeight)
                    }
                }
            }
            .padding()
        }
    }
}

/// Loads catalog examples into a message processor for the debug gallery.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class DebugCatalogModel: ObservableObject {
    let processor: A2UIMessageProcessor

    @Published private(set) var surfaceIds: [String] = []

    private var cancellable: AnyCancellable?

    init(catalog: Catalog, onAction: ((RendererAction) -> Void)?) {
        processor = A2UIMessageProcessor(catalogs: [catalog], defaultCatalogId: catalog.catalogId)
        if let onAction {
            cancellable = processor.actions.sink(receiveValue: onAction)
        }

        for name in catalog.components.keys.sorted() {
            guard let definition = catalog.component(name) else { continue }
            for (index, example) in definition.examples.enumerated() {
                let suffix = definition.examples.count > 1 ? "-\(index + 1)" : ""
                let surfaceId = "\(name)\(suffix)"
                guard let components = Json.decode(example) as? JsonArray else {
                    a2uiLogger.error("Example \(surfaceId) is not a JSON array of components.")
                    continue
                }
                processor.handle(
                    .createSurface(
                        CreateSurfaceMessage(
                            surfaceId: surfaceId,
                            catalogId: catalog.catalogId,
                            components: A2UIMessageDecoder.components(from: components)
                        )
                    )
                )
                surfaceIds.append(surfaceId)
            }
        }
    }
}
