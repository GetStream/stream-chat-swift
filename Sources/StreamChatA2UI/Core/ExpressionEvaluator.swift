//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Routes function calls that the renderer cannot execute locally.
///
/// A2UI v1.0 defines implicit fallback routing: when a function referenced by a
/// component tree is not registered locally, the renderer sends a
/// `callAgentFunction` message and renders a pending state until the agent
/// answers.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
protocol RemoteFunctionRouter: AnyObject {
    /// Returns the agent's answer for a call, dispatching it when needed.
    ///
    /// Implementations return `nil` while the call is in flight, the resolved
    /// value once the matching `agentFunctionResponse` has arrived, and throw
    /// when the agent answered with an error or did not answer in time.
    func agentFunctionValue(
        for name: String,
        catalogId: String?,
        arguments: [String: any Sendable],
        surfaceId: String,
        userActivated: Bool
    ) throws -> (any Sendable)?

    /// Reports a renderer-side error to the agent.
    /// Used for call boundary violations and failed evaluations.
    func report(_ error: RendererError)
}

/// Evaluates A2UI dynamic values, function calls and validation checks.
///
/// One evaluator is created per surface, because function resolution depends on
/// the surface's default catalog. Evaluation is synchronous: local functions run
/// immediately, while agent-routed functions return `nil` until their result
/// arrives.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class ExpressionEvaluator {
    /// The catalogs available for function resolution.
    let catalogs: CatalogRegistry

    /// The surface this evaluator belongs to.
    let surfaceId: String

    /// The default catalog id of the surface.
    let surfaceCatalogId: String?

    /// Host capabilities passed to function implementations.
    let services: RendererServices

    /// Receives calls that cannot be resolved locally.
    weak var remoteRouter: RemoteFunctionRouter?

    private var failureCount = 0
    private var userActivationDepth = 0
    private var interpolationDepth = 0

    /// Creates an evaluator for one surface.
    /// Pass the surface's default catalog id so unqualified calls resolve.
    init(
        catalogs: CatalogRegistry,
        surfaceId: String,
        surfaceCatalogId: String?,
        services: RendererServices = .default,
        remoteRouter: RemoteFunctionRouter? = nil
    ) {
        self.catalogs = catalogs
        self.surfaceId = surfaceId
        self.surfaceCatalogId = surfaceCatalogId
        self.services = services
        self.remoteRouter = remoteRouter
    }

    // MARK: - Dynamic values

    /// Evaluates a dynamic value in the given scope.
    /// Returns `nil` for missing properties and unresolved values.
    func evaluate(_ value: DynamicValue, in context: DataContext) -> (any Sendable)? {
        switch value {
        case .missing:
            return nil
        case let .literal(literal):
            return Json.normalized(literal)
        case let .binding(path):
            return context.value(at: path)
        case let .function(call):
            return invoke(call, in: context)
        }
    }

    /// Evaluates a raw wire value in the given scope.
    /// Nested arrays and objects are resolved recursively.
    func evaluateRaw(_ raw: (any Sendable)?, in context: DataContext) -> (any Sendable)? {
        guard let raw = Json.normalized(raw) else { return nil }

        if let map = raw as? JsonMap {
            switch DynamicValue(map) {
            case let .function(call):
                return invoke(call, in: context)
            case let .binding(path):
                return context.value(at: path)
            case let .literal(literal):
                return (literal as? JsonMap ?? [:]).compactMapValues { evaluateRaw($0, in: context) }
            case .missing:
                return nil
            }
        }
        if let array = raw as? JsonArray {
            return array.map { evaluateRaw($0, in: context) ?? NSNull() }
        }
        return raw
    }

    /// Evaluates a dynamic value and coerces it to a string.
    /// Coercion follows the A2UI type conversion rules.
    func string(_ value: DynamicValue, in context: DataContext) -> String? {
        Json.string(evaluate(value, in: context))
    }

    /// Evaluates a dynamic value and coerces it to a number.
    func double(_ value: DynamicValue, in context: DataContext) -> Double? {
        Json.double(evaluate(value, in: context))
    }

    /// Evaluates a dynamic value and coerces it to a boolean.
    func bool(_ value: DynamicValue, in context: DataContext) -> Bool? {
        Json.bool(evaluate(value, in: context))
    }

    /// Evaluates a dynamic value and coerces it to a list of strings.
    func stringArray(_ value: DynamicValue, in context: DataContext) -> [String]? {
        Json.stringArray(evaluate(value, in: context))
    }

    // MARK: - Function calls

    /// Evaluates a function call in the given scope.
    /// Arguments are resolved before the function runs.
    func invoke(_ call: FunctionCall, in context: DataContext) -> (any Sendable)? {
        let arguments = resolveArguments(call.arguments, in: context)
        return invoke(
            name: call.name,
            catalogId: call.catalogId,
            resolvedArguments: arguments,
            in: context
        )
    }

    /// Evaluates a function by name with already-resolved arguments.
    ///
    /// System functions are handled first, then the surface catalogs, and
    /// finally the agent through ``RemoteFunctionRouter``.
    func invoke(
        name: String,
        catalogId: String?,
        resolvedArguments: [String: any Sendable],
        in context: DataContext
    ) -> (any Sendable)? {
        if name.hasPrefix(A2UIProtocol.systemFunctionPrefix) {
            return invokeSystemFunction(name: name, arguments: resolvedArguments, in: context)
        }

        // There is no fallback to another catalog: a call resolves in its own catalog, or the surface's.
        guard let catalog = catalogs.resolveCatalog(entityCatalogId: catalogId, surfaceCatalogId: surfaceCatalogId) else {
            return fail(
                RendererError(
                    code: RendererError.Code.catalogNotFound,
                    message: (catalogId ?? surfaceCatalogId).map { "Catalog not found: \($0)" }
                        ?? "Function '\(name)' has no catalogId, and the surface has no default catalogId.",
                    surfaceId: surfaceId
                )
            )
        }
        if let definition = catalog.function(name) {
            guard definition.isRendererCallable else {
                return fail(
                    RendererError(
                        code: RendererError.Code.invalidFunctionCall,
                        message: "Function '\(name)' is agentOnly and cannot be bound to component properties.",
                        surfaceId: surfaceId
                    )
                )
            }
            guard !definition.requiresUserActivation || userActivationDepth > 0 else {
                return fail(
                    RendererError(
                        code: RendererError.Code.expressionError,
                        message: "Function '\(name)' requires a user gesture and can only run from an action.",
                        surfaceId: surfaceId
                    )
                )
            }
            return execute(definition, arguments: resolvedArguments, in: context)
        }

        guard let remoteRouter else {
            a2uiLogger.error("Function '\(name)' is not registered and no agent route is available.")
            failureCount += 1
            return nil
        }
        do {
            return try remoteRouter.agentFunctionValue(
                for: name,
                catalogId: catalogId,
                arguments: resolvedArguments,
                surfaceId: surfaceId,
                userActivated: userActivationDepth > 0
            )
        } catch {
            a2uiLogger.warning("Agent function '\(name)' failed: \(A2UIErrorFormatter.describe(error))")
            failureCount += 1
            return nil
        }
    }

    /// Runs `body` as the handler of a user gesture.
    ///
    /// Functions that require user activation, such as `openUrl`, only run
    /// inside this scope. Component actions are performed in it.
    func withUserActivation<Result>(_ body: () throws -> Result) rethrows -> Result {
        userActivationDepth += 1
        defer { userActivationDepth -= 1 }
        return try body()
    }

    /// Executes a function definition, reporting failures to the agent.
    /// Returns `nil` when the implementation throws.
    func execute(
        _ definition: FunctionDefinition,
        arguments: [String: any Sendable],
        in context: DataContext
    ) -> (any Sendable)? {
        do {
            return try definition.implementation(
                FunctionInvocation(
                    name: definition.name,
                    arguments: arguments,
                    context: context,
                    services: services,
                    evaluator: self
                )
            )
        } catch {
            let code = (error as? A2UIFunctionError)?.code
                ?? (error is A2UIExpressionError ? RendererError.Code.expressionError : RendererError.Code.executionError)
            return fail(RendererError(code: code, message: A2UIErrorFormatter.describe(error), surfaceId: surfaceId))
        }
    }

    /// Resolves the raw arguments of a call for `function`, throwing when any of them fails to evaluate.
    ///
    /// Used for agent-initiated calls, which must answer with an error rather
    /// than run with a missing argument. A binding to a missing value resolves to `null`.
    func resolveArgumentsThrowing(
        _ arguments: JsonMap,
        for function: String,
        in context: DataContext
    ) throws -> [String: any Sendable] {
        var resolved: [String: any Sendable] = [:]
        for key in arguments.keys.sorted() {
            let failuresBefore = failureCount
            let value = evaluateRaw(arguments[key], in: context)
            guard failureCount == failuresBefore else {
                throw A2UIFunctionError.invalidArgument(key, function: function, reason: "It could not be evaluated.")
            }
            resolved[key] = value ?? NSNull()
        }
        return resolved
    }

    private func fail(_ error: RendererError) -> (any Sendable)? {
        failureCount += 1
        remoteRouter?.report(error)
        return nil
    }

    /// Resolves the raw arguments of a call in the given scope.
    /// Nested bindings and calls are evaluated depth first.
    func resolveArguments(_ arguments: JsonMap, in context: DataContext) -> [String: any Sendable] {
        var resolved: [String: any Sendable] = [:]
        for (key, value) in arguments {
            if let evaluated = evaluateRaw(value, in: context) {
                resolved[key] = evaluated
            }
        }
        return resolved
    }

    // MARK: - Interpolation

    /// Interpolates a `formatString` template in the given scope.
    /// Unresolved expressions become empty strings; a template that doesn't parse throws.
    func interpolate(_ template: String, in context: DataContext) throws -> String {
        // A template can come from the data model and format itself, through formatString.
        guard interpolationDepth < A2UIProtocol.maxFunctionCallDepth else {
            throw A2UIExpressionError(
                "formatString templates nest more than \(A2UIProtocol.maxFunctionCallDepth) levels deep, "
                    + "such as a template in the data model that formats itself."
            )
        }
        interpolationDepth += 1
        defer { interpolationDepth -= 1 }
        var output = ""
        for segment in try A2UIExpressionParser.parseTemplate(template) {
            switch segment {
            case let .text(text):
                output += text
            case let .expression(expression):
                output += Json.stringify(evaluate(expression, in: context))
            }
        }
        return output
    }

    /// Evaluates a parsed template expression.
    /// Calls are dispatched through the regular function resolution path.
    func evaluate(_ expression: A2UIExpression, in context: DataContext) -> (any Sendable)? {
        switch expression {
        case let .literal(value):
            return Json.normalized(value)
        case let .path(path):
            return context.value(at: path)
        case let .call(name, arguments):
            var resolved: [String: any Sendable] = [:]
            for (key, argument) in arguments {
                if let value = evaluate(argument, in: context) {
                    resolved[key] = value
                }
            }
            return invoke(name: name, catalogId: nil, resolvedArguments: resolved, in: context)
        }
    }

    // MARK: - Validation

    /// Evaluates the failing checks of a component.
    ///
    /// Conditions that evaluate to a boolean are coerced into a validation
    /// result. A condition whose function fails is invalid, while one still
    /// waiting on data or on the agent passes, so streaming UIs are not
    /// disabled while data is arriving.
    ///
    /// The check's `message` is the fallback for a result that has none.
    func failingChecks(_ checks: [CheckRule], in context: DataContext) -> [ValidationResult] {
        checks.compactMap { rule in
            let failuresBefore = failureCount
            let value = evaluate(rule.condition, in: context)
            guard failureCount == failuresBefore else {
                return ValidationResult(isValid: false, message: rule.message ?? "This value could not be checked.")
            }
            let result = ValidationResult(coercing: value)
            guard !result.isValid else { return nil }
            // A check's own message overrides the default message of the function it calls, while a
            // result bound from the data model keeps its message.
            let message: String?
            switch rule.condition {
            case let .function(call):
                message = rule.message ?? result.message ?? ValidationFunctions.defaultMessage(forFunction: call.name)
            default:
                message = result.message ?? rule.message
            }
            return ValidationResult(isValid: false, code: result.code, message: message, severity: result.severity)
        }
    }

    // MARK: - System functions

    private func invokeSystemFunction(
        name: String,
        arguments: [String: any Sendable],
        in context: DataContext
    ) -> (any Sendable)? {
        switch name {
        case "@index":
            guard let index = context.itemIndex else {
                return fail(
                    RendererError(
                        code: RendererError.Code.expressionError,
                        message: "@index function can only be evaluated inside a collection template iteration scope.",
                        surfaceId: surfaceId
                    )
                )
            }
            let offset = Json.int(arguments["offset"]) ?? 0
            let (result, overflow) = index.addingReportingOverflow(offset)
            return overflow ? nil : result
        default:
            return fail(
                RendererError(
                    code: RendererError.Code.expressionError,
                    message: "Unknown system function '\(name)'.",
                    surfaceId: surfaceId
                )
            )
        }
    }
}
