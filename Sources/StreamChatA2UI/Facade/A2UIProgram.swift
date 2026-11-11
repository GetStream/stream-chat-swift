//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What is wrong with the A2UI messages of a reply, for a renderer with `catalog`: messages it
/// can't read, components it doesn't have, and references that lead nowhere.
///
/// An agent's instructions show it A2UI to write, which should render as it is: a broken example
/// teaches the model to write broken UI.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIProgram {
    /// The problems of the messages in `text`, or none when they render as written.
    static func problems(in text: String, catalog: Catalog) -> [String] {
        var problems: [String] = []
        var surfaces: [String: [String: Component]] = [:]
        var order: [String] = []
        for raw in A2UIStream.messages(in: text) {
            guard let json = Json.decodeMap(raw) else {
                problems.append("this isn't JSON: \(raw.prefix(80))")
                continue
            }
            let message: A2UIMessage
            do {
                message = try A2UIMessageDecoder.decode(json)
            } catch {
                problems.append("\(error)")
                continue
            }
            switch message {
            case let .createSurface(created):
                problems += duplicates(in: created.components, on: created.surfaceId)
                if let catalogId = created.catalogId, catalogId != catalog.catalogId {
                    problems.append("surface \(created.surfaceId) names the catalog \(catalogId), not \(catalog.catalogId)")
                }
                surfaces[created.surfaceId] = Dictionary(created.components.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
                order.append(created.surfaceId)
            case let .updateComponents(update):
                guard surfaces[update.surfaceId] != nil else {
                    problems.append("surface \(update.surfaceId) gets components before it is created")
                    continue
                }
                problems += duplicates(in: update.components, on: update.surfaceId)
                for component in update.components {
                    surfaces[update.surfaceId]?[component.id] = component
                }
            case let .updateDataModel(update) where surfaces[update.surfaceId] == nil:
                problems.append("surface \(update.surfaceId) gets data before it is created")
            case .updateDataModel, .deleteSurface:
                break
            case .callRendererFunction, .agentFunctionResponse:
                problems.append("a reply's UI calls no functions")
            }
        }
        if order.isEmpty {
            problems.append("nothing renders: there is no createSurface")
        }
        for surfaceId in order {
            problems += self.problems(of: surfaces[surfaceId] ?? [:], on: surfaceId, catalog: catalog)
        }
        return problems
    }

    private static func problems(of components: [String: Component], on surfaceId: String, catalog: Catalog) -> [String] {
        var problems: [String] = []
        var references: [String: [String]] = [:]
        for component in components.values.sorted(by: { $0.id < $1.id }) {
            if !A2UIIdentifier.isValid(component.id) {
                problems.append("\(component.id) isn't an identifier: use letters, digits and _, not starting with a digit")
            }
            guard let definition = catalog.component(component.type) else {
                problems.append("\(component.id) is a \(component.type), which the catalog doesn't have")
                continue
            }
            for missing in definition.requiredProperties where component.properties[missing] == nil {
                problems.append("\(component.id) is a \(component.type) without its \(missing)")
            }
            let known = Set(definition.propertySchema.keys).union(["checks", "weight"])
            for property in component.properties.keys.sorted() where !known.contains(property) {
                problems.append("\(component.id) is a \(component.type), which has no \(property)")
            }
            references[component.id] = definition.childReferences(of: component).map(\.id)
        }
        for (id, children) in references.sorted(by: { $0.key < $1.key }) {
            for child in children where components[child] == nil {
                problems.append("\(id) holds \(child), which is not defined")
            }
        }
        guard components[A2UIProtocol.rootComponentId] != nil else {
            return problems + ["surface \(surfaceId) has no component with the id root"]
        }
        var reached: Set<String> = []
        var next = [A2UIProtocol.rootComponentId]
        while let id = next.popLast() {
            guard reached.insert(id).inserted else { continue }
            next += references[id] ?? []
        }
        for id in components.keys.sorted() where !reached.contains(id) {
            problems.append("\(id) is defined but nothing holds it")
        }
        return problems + nestingProblems(references, on: surfaceId)
    }

    private static func duplicates(in components: [Component], on surfaceId: String) -> [String] {
        var seen: Set<String> = []
        var repeated: [String] = []
        for component in components where !seen.insert(component.id).inserted && !repeated.contains(component.id) {
            repeated.append(component.id)
        }
        return repeated.map { "surface \(surfaceId) defines \($0) more than once in one message" }
    }

    // A component that holds itself, directly or through others, never finishes rendering, and a
    // renderer stops at `A2UIProtocol.maxNestingDepth` levels.
    private static func nestingProblems(_ references: [String: [String]], on surfaceId: String) -> [String] {
        var problems: [String] = []
        var depths: [String: Int] = [:]
        var visiting: Set<String> = []
        var reportedCycle = false

        func depth(of id: String) -> Int {
            if let known = depths[id] { return known }
            guard visiting.insert(id).inserted else {
                if !reportedCycle {
                    problems.append("\(id) holds itself through its children, so it never finishes rendering")
                    reportedCycle = true
                }
                return 0
            }
            let deepest = (references[id] ?? []).filter { references[$0] != nil }.map(depth(of:)).max() ?? 0
            visiting.remove(id)
            depths[id] = deepest + 1
            return deepest + 1
        }

        if references[A2UIProtocol.rootComponentId] != nil,
           depth(of: A2UIProtocol.rootComponentId) > A2UIProtocol.maxNestingDepth {
            problems.append("surface \(surfaceId) nests components deeper than \(A2UIProtocol.maxNestingDepth) levels")
        }
        for id in references.keys.sorted() {
            _ = depth(of: id)
        }
        return problems
    }
}
