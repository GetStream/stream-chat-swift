//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Evaluated actions are plans: `{steps: [...]}`. A step call is a one-step plan and an invalid
// step an empty one.
@available(iOS 17.0, macOS 14.0, *)
enum ActionPlan {
    // Upstream keeps the custom steps real calls made in a WeakSet, so data (an object literal,
    // `$state`, an `@Each` item) can't pose as a custom action. Values have no identity here, so
    // those steps carry a token data can't know.
    static let callTokenKey = "__openuiCall"
    static let callToken = OpenUIValue.string(UUID().uuidString)

    static let empty: OpenUIValue = ["steps": []]

    static func plan(_ steps: [OpenUIValue]) -> OpenUIValue {
        .object(["steps": .array(steps)])
    }

    static func customStep(name: String, params: OpenUIValue) -> OpenUIValue {
        ["type": .string(ActionStepType.customAction), "name": .string(name), "params": params, callTokenKey: callToken]
    }

    static func isPlan(_ value: OpenUIValue?) -> Bool {
        if case .object(let object)? = value, case .array? = object["steps"] { return true }
        return false
    }

    static func steps(of value: OpenUIValue?) -> [OpenUIValue] {
        guard isPlan(value) else { return [] }
        return value?["steps"]?.arrayValue ?? []
    }

    /// Flattens plans (and stray step objects) into one plan; other values are dropped.
    static func flatten(_ values: [OpenUIValue]) -> OpenUIValue {
        let flattened = values.flatMap { value -> [OpenUIValue] in
            if isPlan(value) { return steps(of: value) }
            switch value {
            case .object(let object) where object.contains("type"): return [value]
            case .element: return [value]
            default: return []
            }
        }
        return ownSteps(plan(flattened))
    }

    /// Drops the custom steps no real call made.
    static func ownSteps(_ plan: OpenUIValue) -> OpenUIValue {
        guard case .object(var object) = plan, case .array(let steps)? = object["steps"] else { return plan }
        let own = steps.filter { step in
            step["type"]?.stringValue != ActionStepType.customAction || step[callTokenKey] == callToken
        }
        guard own.count != steps.count else { return plan }
        object["steps"] = .array(own)
        return .object(object)
    }
}
