//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import Observation

/// A two-way bound form field (port of `resolveStateField`).
@available(iOS 17.0, macOS 14.0, *)
struct StateField {
    let name: String
    /// Current value (`nil` when unset).
    let value: OpenUIValue?
    /// Whether the field is bound to a `$variable`.
    let isReactive: Bool
    private let setter: (OpenUIValue?) -> Void

    init(name: String, value: OpenUIValue?, isReactive: Bool, setter: @escaping (OpenUIValue?) -> Void) {
        self.name = name
        self.value = value
        self.isReactive = isReactive
        self.setter = setter
    }

    func set(_ newValue: OpenUIValue?) {
        setter(newValue)
    }
}

/// Owns the state of one rendered OpenUI response: incremental parsing, `$variables` and form
/// state, `Query`/`Mutation` execution, prop evaluation and action handling.
///
/// This is the Swift counterpart of the React renderer's `useOpenUIState`. Feed it the response text
/// as it streams with ``update(response:isStreaming:)`` and render it with ``OpenUIView``.
/// Keep one runtime per message so state survives view recycling in chat lists.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class OpenUIRuntime {
    private(set) var library: ComponentLibrary
    let store: OpenUIStore
    @ObservationIgnored let queryManager: QueryManager

    /// The raw response text.
    private(set) var response: String?
    /// Whether the model is still streaming (inputs are disabled and queries wait until it ends).
    private(set) var isStreaming = false
    /// The raw parse result (runtime expressions unevaluated).
    private(set) var parseResult: ParseResult?
    /// The evaluated root element that is rendered.
    private(set) var root: ElementNode?
    /// Whether any query is fetching.
    private(set) var isQueryLoading = false
    /// Current structured errors (empty while streaming).
    private(set) var errors: [OpenUIError] = []

    /// Conversation and navigation actions (`@ToAssistant`, `@OpenUrl`, follow-ups, buttons without actions).
    @ObservationIgnored var onAction: (@MainActor (ActionEvent) -> Void)?
    /// Called on every user-driven state change, with the full state snapshot (persist it as-is).
    @ObservationIgnored var onStateUpdate: (@MainActor (OpenUIObject) -> Void)?
    /// Called with structured, LLM-friendly errors when streaming ends (and with `[]` when they clear).
    @ObservationIgnored var onError: (@MainActor ([OpenUIError]) -> Void)?

    @ObservationIgnored private var streamParser: OpenUIStreamParser
    @ObservationIgnored private var initialState: OpenUIObject?
    @ObservationIgnored private var storeInitKey: String?
    @ObservationIgnored private var isInitializingStore = false
    @ObservationIgnored private var lastErrorKey = ""
    @ObservationIgnored private var isRecomputing = false
    @ObservationIgnored private var needsRecompute = false
    @ObservationIgnored private var runtimeErrors: [OpenUIError] = []
    @ObservationIgnored private var functions: [String: OpenUIFunction]
    @ObservationIgnored private var customActions: [String: OpenUICustomAction]

    /// - Parameters:
    ///   - library: The component library the model was prompted with.
    ///   - toolProvider: Executes `Query`/`Mutation` tools.
    ///   - initialState: Previously persisted state (from ``onStateUpdate``). `$`-prefixed keys
    ///     restore bindings; other keys restore form state.
    init(library: ComponentLibrary, toolProvider: (any OpenUIToolProvider)? = nil, initialState: OpenUIObject? = nil) {
        self.library = library
        self.store = OpenUIStore()
        self.queryManager = QueryManager(toolProvider: toolProvider)
        self.streamParser = library.makeStreamParser()
        self.initialState = initialState
        self.functions = Self.byName(library.functions, name: \.name)
        self.customActions = Self.byName(library.customActions, name: \.name)
        store.onChange = { [weak self] key in self?.storeDidChange(key) }
        queryManager.onChange = { [weak self] in self?.queryManagerDidChange() }
    }

    // MARK: - Input

    /// Feeds the latest response text (the full text so far, not a delta).
    func update(response: String?, isStreaming: Bool) {
        let responseChanged = response != self.response
        let streamingChanged = isStreaming != self.isStreaming
        guard responseChanged || streamingChanged || parseResult == nil else { return }
        self.response = response
        self.isStreaming = isStreaming

        // The end of the stream completes a `$name` that was still streaming in.
        if responseChanged || streamingChanged || parseResult == nil {
            if let response, !response.isEmpty {
                parseResult = streamParser.set(response, complete: !isStreaming)
            } else {
                parseResult = nil
            }
        }
        initializeStoreIfNeeded()
        runQueryEffects()
        recompute()
        collectErrors()
    }

    // Takes a library that parses programs the same way, with other renderers, functions or
    // actions, and keeps the state of what it shows.
    func adopt(_ library: ComponentLibrary) {
        self.library = library
        functions = Self.byName(library.functions, name: \.name)
        customActions = Self.byName(library.customActions, name: \.name)
        recompute()
    }

    private static func byName<Value>(_ values: [Value], name: (Value) -> String) -> [String: Value] {
        Dictionary(values.map { (name($0), $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Restores persisted state (e.g. when re-rendering a stored message).
    func restore(state: OpenUIObject) {
        initialState = state
        storeInitKey = nil
        initializeStoreIfNeeded()
        recompute()
    }

    /// Reactivates query execution after ``dispose()``.
    func activate() {
        queryManager.activate()
        queryManager.onChange = { [weak self] in self?.queryManagerDidChange() }
        runQueryEffects()
    }

    /// Stops refresh timers and pending work.
    func dispose() {
        queryManager.dispose()
    }

    // MARK: - Evaluation

    /// Context used to evaluate expressions against the current state and query results.
    var evaluationContext: EvaluationContext {
        let store = self.store
        let queryManager = self.queryManager
        return EvaluationContext(
            getState: { name in Self.unwrapFieldValue(store.get(name)) },
            resolveRef: { name in queryManager.mutationResult(for: name) ?? queryManager.result(for: name) },
            functions: functions,
            actions: customActions
        )
    }

    /// Unwraps `{ value, componentType }` form entries.
    static func unwrapFieldValue(_ value: OpenUIValue?) -> OpenUIValue? {
        if case .object(let object)? = value, let wrapped = object["value"] { return wrapped }
        return value
    }

    /// Evaluates an expression against the current state.
    func evaluate(_ node: ASTNode) -> OpenUIValue? {
        Evaluator.evaluate(node, evaluationContext)
    }

    private func recompute() {
        if isRecomputing {
            needsRecompute = true
            return
        }
        isRecomputing = true
        defer { isRecomputing = false }
        var passes = 0
        repeat {
            needsRecompute = false
            passes += 1
            let (evaluated, errors) = PropEvaluator.evaluateRoot(parseResult, evaluationContext, library)
            runtimeErrors = errors
            if evaluated != root { root = evaluated }
            let loading = !queryManager.snapshot.loading.isEmpty
            if loading != isQueryLoading { isQueryLoading = loading }
        } while needsRecompute && passes < 8
    }

    private func initializeStoreIfNeeded() {
        guard parseResult != nil || initialState != nil else { return }
        let declarations = parseResult?.stateDeclarations ?? [:]
        let key = OpenUIJSON.stringify(.object(declarations)) + "::" + OpenUIJSON.stringify(initialState.map(OpenUIValue.object) ?? .null)
        guard key != storeInitKey else { return }
        storeInitKey = key

        isInitializingStore = true
        defer { isInitializingStore = false }
        var bindingDefaults = OpenUIObject()
        for (name, value) in initialState?.entries ?? [] {
            if name.hasPrefix("$") {
                bindingDefaults[name] = value
            } else {
                store.set(name, value)
            }
        }
        store.initialize(defaults: declarations, persisted: bindingDefaults)
    }

    private func runQueryEffects() {
        guard !isStreaming else { return }
        let context = evaluationContext
        let snapshot = store.snapshot

        let queryNodes: [QueryManager.QueryNode] = (parseResult?.queryStatements ?? []).map { statement in
            var deps: OpenUIValue?
            if let names = statement.deps, !names.isEmpty {
                var relevant = OpenUIObject()
                for name in names { relevant[name] = snapshot[name] ?? .null }
                deps = .object(relevant)
            }
            var refreshInterval: Double?
            if let refreshAST = statement.refreshAST, let value = Evaluator.evaluate(refreshAST, context) {
                refreshInterval = JS.toNumber(value)
            }
            return QueryManager.QueryNode(
                statementId: statement.statementId,
                toolName: statement.toolAST.flatMap { Evaluator.evaluate($0, context) }.map { JS.toString($0) } ?? "",
                args: statement.argsAST.map { Evaluator.evaluate($0, context) ?? .null } ?? .null,
                defaults: statement.defaultsAST.map { Evaluator.evaluate($0, context) ?? .null } ?? .null,
                deps: deps,
                refreshInterval: refreshInterval,
                complete: statement.complete
            )
        }
        queryManager.evaluateQueries(queryNodes)

        let mutationNodes = (parseResult?.mutationStatements ?? []).map { statement in
            QueryManager.MutationNode(
                statementId: statement.statementId,
                toolName: statement.toolAST.flatMap { Evaluator.evaluate($0, context) }.map { JS.toString($0) } ?? ""
            )
        }
        queryManager.registerMutations(mutationNodes)
    }

    private func storeDidChange(_ key: String) {
        if key.hasPrefix("$") {
            runQueryEffects()
            recompute()
        }
        if !isInitializingStore {
            onStateUpdate?(store.snapshot)
        }
    }

    private func queryManagerDidChange() {
        recompute()
        collectErrors()
    }

    private func collectErrors() {
        if isStreaming {
            if !errors.isEmpty { errors = [] }
            if !lastErrorKey.isEmpty {
                lastErrorKey = ""
                onError?([])
            }
            return
        }
        var collected: [OpenUIError] = []
        // A missing or unusable entry is reported by the parser as `no-root`.
        if let response, !response.isEmpty, (parseResult?.meta.statementCount ?? 0) == 0 {
            collected.append(OpenUIError(
                source: .parser,
                code: "parse-failed",
                message: "Response could not be parsed as valid openui-lang",
                hint: "The entire response must be valid openui-lang code starting with root = \(library.root ?? "Root")(...)"
            ))
        }
        if let validationErrors = parseResult?.meta.errors, !validationErrors.isEmpty {
            collected += OpenUIError.enriched(validationErrors, schema: library.jsonSchema, componentNames: library.componentNames)
        }
        collected += runtimeErrors
        collected += queryManager.snapshot.errors

        let key = collected.map(\.description).joined(separator: "\n") + "#\(collected.count)"
        guard key != lastErrorKey else { return }
        lastErrorKey = key
        errors = collected
        onError?(collected)
    }

    // MARK: - Form state

    /// Reads a field value: top level for `$bindings`, nested under `formName` for form fields.
    func fieldValue(formName: String?, name: String) -> OpenUIValue? {
        guard let formName else { return Self.unwrapFieldValue(store.get(name)) }
        guard case .object(let form)? = store.get(formName) else { return nil }
        return Self.unwrapFieldValue(form[name])
    }

    /// Writes a field value as `{ value, componentType }`.
    func setFieldValue(formName: String?, componentType: String?, name: String, value: OpenUIValue?, isSecret: Bool = false) {
        var wrapped: OpenUIObject = ["value": value ?? .null]
        if let componentType { wrapped["componentType"] = .string(componentType) }
        if isSecret { wrapped["secret"] = .bool(true) }
        guard let formName else {
            store.set(name, .object(wrapped))
            return
        }
        var form = store.get(formName)?.objectValue ?? [:]
        form[name] = .object(wrapped)
        store.set(formName, .object(form))
    }

    /// Resolves a field that may be bound to a `$variable` (reactive) or stored as form state.
    func stateField(
        name: String,
        binding: OpenUIValue?,
        formName: String?,
        componentType: String? = nil,
        isSecret: Bool = false
    ) -> StateField {
        // A secret, such as a password, never goes in a `$variable`, where any expression could
        // read it: it stays in the form's state, which leaves it out of what goes anywhere.
        if !isSecret, let target = ReactiveBinding.target(of: binding) {
            let expression = ReactiveBinding.expression(of: binding)
            return StateField(name: name, value: store.get(target), isReactive: true) { [weak self] newValue in
                guard let self else { return }
                var context = self.evaluationContext
                context.extraScope = ["$value": newValue ?? .null]
                let next = expression.map { Evaluator.evaluate($0, context) } ?? newValue
                self.store.set(target, next)
            }
        }
        let current = fieldValue(formName: formName, name: name)
        let fallback = isSecret && ReactiveBinding.target(of: binding) != nil ? nil : binding
        let value = JS.isNullish(current) ? (fallback ?? current) : current
        return StateField(name: name, value: value, isReactive: false) { [weak self] newValue in
            self?.setFieldValue(formName: formName, componentType: componentType, name: name, value: newValue, isSecret: isSecret)
        }
    }

    // Whether an image may load from `link`, as the model wrote it: only from a link written out
    // in the program, or one a tool returned. A link built from what the person typed is neither,
    // so an image can't send it to a server as they type, however it is split or encoded.
    func allowsImageLink(_ link: String) -> Bool {
        guard !link.isEmpty else { return false }
        if response?.contains(link) == true { return true }
        return Self.value(.object(queryManager.snapshot.values), contains: link)
    }

    private static func value(_ value: OpenUIValue, contains link: String) -> Bool {
        var pending = [value]
        while let next = pending.popLast() {
            switch next {
            case .string(let string) where string == link:
                return true
            case .array(let items):
                pending.append(contentsOf: items)
            case .object(let object):
                pending.append(contentsOf: object.entries.map(\.1))
            default:
                continue
            }
        }
        return false
    }

    /// The form state included with actions: `{ formName: fields }`, or the whole state.
    func formPayload(_ formName: String?) -> OpenUIObject {
        if let formName, case .object(let form)? = store.get(formName) {
            return [formName: .object(form)]
        }
        return store.snapshot
    }

    // MARK: - Actions

    /// Runs an action: a plan of steps (one step, or several in `Action([...])`, halting when a
    /// mutation fails), a legacy action object (`{ type, params }` / `{ type: "open_url", url }`), or,
    /// when `action` is `nil`, a continue-conversation event carrying `label`. Each step reads the
    /// form state when it runs, so an earlier `@Set` in the same plan is visible.
    func triggerAction(label: String, formName: String? = nil, action: OpenUIValue? = nil) async {
        if case .object(let object)? = action, object["steps"] == nil {
            let type = object["type"].flatMap { JS.isTruthy($0) ? JS.toString($0) : nil } ?? BuiltinActionType.continueConversation
            // Only a real call delivers a custom action; a legacy object can't pose as one.
            if customActions[type] != nil { return }
            var params = object["params"]?.objectValue ?? [:]
            if let url = object["url"], JS.isTruthy(url) { params["url"] = url }
            if let context = object["context"], JS.isTruthy(context) { params["context"] = context }
            onAction?(ActionEvent(
                type: type,
                params: params,
                humanFriendlyMessage: label,
                label: label,
                formState: formPayload(formName),
                formName: formName
            ))
            return
        }

        if ActionPlan.isPlan(action) {
            for step in ActionPlan.steps(of: action.map(ActionPlan.ownSteps)) {
                guard let type = step["type"]?.stringValue else { continue }
                switch type {
                case ActionStepType.run:
                    guard let statementId = step["statementId"]?.stringValue else { continue }
                    if step["refType"] == "mutation" {
                        let argsAST = parseResult?.mutationStatements.first { $0.statementId == statementId }?.argsAST
                        let arguments = argsAST.flatMap { evaluate($0)?.objectValue } ?? [:]
                        let succeeded = await queryManager.fireMutation(statementId, arguments: arguments)
                        if !succeeded { return }
                    } else {
                        queryManager.invalidate([statementId])
                    }
                case ActionStepType.continueConversation:
                    var params = OpenUIObject()
                    if let context = step["context"] { params["context"] = context }
                    onAction?(ActionEvent(
                        type: BuiltinActionType.continueConversation,
                        params: params,
                        humanFriendlyMessage: step["message"].map { JS.toString($0) } ?? "",
                        label: label,
                        formState: formPayload(formName),
                        formName: formName
                    ))
                case ActionStepType.openURL:
                    onAction?(ActionEvent(
                        type: BuiltinActionType.openURL,
                        params: ["url": step["url"] ?? .string("")],
                        humanFriendlyMessage: "",
                        formState: formPayload(formName),
                        formName: formName
                    ))
                case ActionStepType.customAction:
                    guard let name = step["name"]?.stringValue else { continue }
                    onAction?(ActionEvent(
                        type: name,
                        params: step["params"]?.objectValue ?? [:],
                        humanFriendlyMessage: "",
                        formState: formPayload(formName),
                        formName: formName
                    ))
                case ActionStepType.set:
                    guard let target = step["target"]?.stringValue, case .expression(let valueAST)? = step["valueAST"] else { continue }
                    store.set(target, evaluate(valueAST))
                case ActionStepType.reset:
                    let declarations = parseResult?.stateDeclarations ?? [:]
                    for target in step["targets"]?.arrayValue?.compactMap(\.stringValue) ?? [] {
                        store.set(target, declarations[target] ?? .null, pristine: true)
                    }
                default:
                    break
                }
            }
            return
        }

        onAction?(ActionEvent(
            type: BuiltinActionType.continueConversation,
            humanFriendlyMessage: label,
            label: label,
            formState: formPayload(formName),
            formName: formName
        ))
    }
}
