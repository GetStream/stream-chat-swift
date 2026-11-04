//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A tool the model can call via `Query()`/`Mutation()` (shape inspired by MCP's tool schema).
@available(iOS 17.0, macOS 14.0, *)
struct ToolSpec: Sendable, Hashable {
    var name: String
    var description: String?
    var inputSchema: OpenUIValue
    var outputSchema: OpenUIValue

    init(name: String, description: String? = nil, inputSchema: OpenUIValue = [:], outputSchema: OpenUIValue = [:]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
    }
}

/// A tool listed in the prompt: just a name, or a full spec.
@available(iOS 17.0, macOS 14.0, *)
enum ToolDescriptor: Sendable, Hashable {
    case name(String)
    case spec(ToolSpec)
}

/// A named group of components in the prompt, with optional usage notes.
@available(iOS 17.0, macOS 14.0, *)
struct ComponentGroup: Sendable, Hashable {
    var name: String
    var components: [String]
    var notes: [String]

    init(name: String, components: [String], notes: [String] = []) {
        self.name = name
        self.components = components
        self.notes = notes
    }
}

/// Options for system prompt generation (mirrors `PromptOptions` in `@openuidev/lang-core`).
@available(iOS 17.0, macOS 14.0, *)
struct PromptOptions: Sendable, Hashable {
    /// Replaces the default preamble.
    var preamble: String?
    var additionalRules: [String]
    /// Examples (static/layout patterns).
    var examples: [String]
    /// Examples using Query/Mutation.
    var toolExamples: [String]
    var tools: [ToolDescriptor]
    /// Incremental editing instructions (the model outputs only changed statements).
    var editMode: Bool
    /// Text + fenced code responses (the model can answer without generating UI).
    var inlineMode: Bool
    /// `Query()`, `Mutation()`, `@Run`. Defaults to `true` when tools are provided.
    var toolCalls: Bool?
    /// `$variables`, `@Set`, `@Reset`. Defaults to `toolCalls`.
    var bindings: Bool?
    /// Lists the built-in functions (`@Count`, `@Sum`, ...). Defaults to `toolCalls || bindings`.
    var builtinFunctions: Bool?

    init(
        preamble: String? = nil,
        additionalRules: [String] = [],
        examples: [String] = [],
        toolExamples: [String] = [],
        tools: [ToolDescriptor] = [],
        editMode: Bool = false,
        inlineMode: Bool = false,
        toolCalls: Bool? = nil,
        bindings: Bool? = nil,
        builtinFunctions: Bool? = nil
    ) {
        self.preamble = preamble
        self.additionalRules = additionalRules
        self.examples = examples
        self.toolExamples = toolExamples
        self.tools = tools
        self.editMode = editMode
        self.inlineMode = inlineMode
        self.toolCalls = toolCalls
        self.bindings = bindings
        self.builtinFunctions = builtinFunctions
    }
}

/// Everything needed to render a system prompt.
@available(iOS 17.0, macOS 14.0, *)
struct PromptSpec: Sendable, Hashable {
    struct Component: Sendable, Hashable {
        var name: String
        var signature: String
        var description: String?

        init(name: String, signature: String, description: String? = nil) {
            self.name = name
            self.signature = signature
            self.description = description
        }
    }

    var root: String?
    var components: [Component]
    var componentGroups: [ComponentGroup]
    /// The library's functions, listed with the built-in ones.
    var functions: [Component]
    /// The library's custom actions, listed with the built-in action steps.
    var actions: [Component]
    var options: PromptOptions

    init(
        root: String?,
        components: [Component],
        componentGroups: [ComponentGroup] = [],
        functions: [Component] = [],
        actions: [Component] = [],
        options: PromptOptions = PromptOptions()
    ) {
        self.root = root
        self.components = components
        self.componentGroups = componentGroups
        self.functions = functions
        self.actions = actions
        self.options = options
    }
}

/// Generates the OpenUI Lang system prompt (port of `generatePrompt` in `prompt.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum PromptGenerator {
    static let defaultPreamble = "You are an AI assistant that responds using openui-lang, a declarative UI language. Your ENTIRE response must be valid openui-lang code — no markdown, no explanations, just openui-lang."

    static func generate(_ spec: PromptSpec) -> String {
        let options = spec.options
        let rootName = spec.root ?? "Root"
        let hasTools = !options.tools.isEmpty
        let toolCalls = options.toolCalls ?? hasTools
        let bindings = options.bindings ?? toolCalls
        let supportsExpressions = toolCalls || bindings
        let usesActionExpression = spec.components.contains { $0.signature.contains("ActionExpression") || hasRestrictedSlot($0.signature) }

        var parts: [String] = []
        parts.append(options.preamble ?? defaultPreamble)
        parts.append("")
        parts.append(syntaxRules(rootName: rootName, supportsExpressions: supportsExpressions, bindings: bindings))
        parts.append("")
        parts.append(componentSignatures(spec, toolCalls: toolCalls, bindings: bindings, usesActionExpression: usesActionExpression))

        // Library functions get the section alone when built-ins are not listed.
        let customFunctions = spec.functions.map(functionLine)
        if options.builtinFunctions ?? supportsExpressions {
            parts.append("")
            parts.append(builtinFunctionsSection(customFunctions, toolCalls: toolCalls))
        } else if !customFunctions.isEmpty {
            parts.append("")
            parts.append("## Built-in Functions\n\n" + customFunctions.joined(separator: "\n"))
        }
        if toolCalls {
            parts.append("")
            parts.append(querySection)
            parts.append("")
            parts.append(mutationSection)
        }
        // Library actions get the Action section alone when no component uses ActionExpression.
        let customActions = spec.actions.map { "- " + functionLine($0) }
        if usesActionExpression {
            parts.append("")
            parts.append(actionSection(toolCalls: toolCalls, bindings: bindings, custom: customActions))
        } else if !customActions.isEmpty {
            parts.append("")
            parts.append("\(actionHeader)\n\nPass one step, or Action([...]) with several steps, as a button's action.\n\nAvailable steps:\n" + customActions.joined(separator: "\n"))
        }
        if toolCalls && bindings {
            parts.append("")
            parts.append(interactiveFiltersSection)
        }
        if toolCalls {
            parts.append("")
            parts.append(toolWorkflowSection)
        }
        if hasTools {
            parts.append("")
            parts.append(toolsSection(options.tools))
        }

        parts.append("")
        parts.append(streamingRules(rootName: rootName, supportsExpressions: supportsExpressions, toolCalls: toolCalls))

        let allExamples = options.examples + options.toolExamples
        if !allExamples.isEmpty {
            parts.append("")
            parts.append("## Examples")
            parts.append("")
            for example in allExamples {
                parts.append(example)
                parts.append("")
            }
        }

        if options.editMode {
            parts.append("")
            parts.append(editModeSection)
        }
        if options.inlineMode {
            parts.append("")
            parts.append(inlineModeSection)
        }

        parts.append(importantRules(rootName: rootName, toolCalls: toolCalls, bindings: bindings))

        if !options.additionalRules.isEmpty {
            parts.append("")
            for rule in options.additionalRules {
                parts.append("- \(rule)")
            }
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - JSON Schema helpers

    static func jsonSchemaTypeString(_ schema: OpenUIValue) -> String {
        switch schema["type"]?.stringValue {
        case "string":
            if case .array(let values)? = schema["enum"] {
                return values.map { "\"\(JS.toString($0))\"" }.joined(separator: " | ")
            }
            return "string"
        case "number", "integer":
            return "number"
        case "boolean":
            return "boolean"
        case "array":
            if let items = schema["items"], !JS.isNullish(items) {
                return "\(jsonSchemaTypeString(items))[]"
            }
            return "any[]"
        case "object":
            if case .object(let properties)? = schema["properties"], !properties.isEmpty {
                let required = schema["required"]?.arrayValue?.compactMap(\.stringValue) ?? []
                let fields = properties.entries.map { key, value in
                    "\(key)\(required.contains(key) ? "" : "?"): \(jsonSchemaTypeString(value))"
                }
                return "{" + fields.joined(separator: ", ") + "}"
            }
            return "object"
        default:
            return "any"
        }
    }

    static func defaultValue(for schema: OpenUIValue) -> OpenUIValue {
        switch schema["type"]?.stringValue {
        case "string": return ""
        case "number", "integer": return 0
        case "boolean": return false
        case "array": return []
        case "object":
            if case .object(let properties)? = schema["properties"], !properties.isEmpty {
                return .object(properties.mapValues(defaultValue(for:)))
            }
            return [:]
        default:
            return .null
        }
    }

    // MARK: - Sections

    static func syntaxRules(rootName: String, supportsExpressions: Bool, bindings: Bool) -> String {
        var lines = [
            "## Syntax Rules",
            "",
            "1. Each statement is on its own line: `identifier = Expression`",
            "2. `root` is the entry point — every program must define `root = \(rootName)(...)`",
            "3. Expressions are: strings (\"...\"), numbers, booleans (true/false), null, arrays ([...]), objects ({...}), or component calls TypeName(arg1, arg2, ...)",
            "4. Use references for readability: define `name = ...` on one line, then use `name` later",
            "5. EVERY variable (except root) MUST be referenced by at least one other variable. Unreferenced variables are silently dropped and will NOT render. Always include defined variables in their parent's children/items array.",
            "6. Arguments are POSITIONAL (order matters, not names). Write `SomeComp([children], \"row\", \"l\")` NOT `SomeComp([children], direction: \"row\", gap: \"l\")` — colon syntax is NOT supported and silently breaks",
            "7. Optional arguments can be omitted from the end"
        ]
        var ruleNumber = 8
        if bindings {
            lines.append("\(ruleNumber). Declare mutable state with `$varName = defaultValue`. Components marked with `$binding` can read/write these. Undeclared $variables are auto-created with null default.")
            ruleNumber += 1
        }
        if supportsExpressions {
            let rules = [
                "String concatenation: `\"text\" + $var + \"more\"`",
                "Dot member access: `query.field` reads a field; on arrays it extracts that field from every element",
                "Index access: `arr[0]`, `data[index]`",
                "Arithmetic operators: +, -, *, /, % (work on numbers; + is string concat when either side is a string)",
                "Comparison: ==, !=, >, <, >=, <=",
                "Logical: &&, ||, ! (prefix)",
                "Ternary: `condition ? valueIfTrue : valueIfFalse`",
                "Parentheses for grouping: `(a + b) * c`"
            ]
            for rule in rules {
                lines.append("\(ruleNumber). \(rule)")
                ruleNumber += 1
            }
        }
        lines.append("- Strings use double quotes with backslash escaping")
        return lines.joined(separator: "\n")
    }

    // The built-in functions' prompt signatures, as upstream generates them from their schemas.
    static let builtinFunctionSignatures: [String: String] = [
        "Count": "Count(array: any[]) → number",
        "First": "First(array: any[]) → any",
        "Last": "Last(array: any[]) → any",
        "Sum": "Sum(numbers: number[]) → number",
        "Avg": "Avg(numbers: number[]) → number",
        "Min": "Min(numbers: number[]) → number",
        "Max": "Max(numbers: number[]) → number",
        "Sort": "Sort(array: any[], field: string, direction?: \"asc\" | \"desc\") → any[]",
        "Filter": "Filter(array: any[], field: string, operator: \"==\" | \"!=\" | \">\" | \"<\" | \">=\" | \"<=\" | \"contains\", value: any) → any[]",
        "Round": "Round(number: number, decimals?: number) → number",
        "Abs": "Abs(number: number) → number",
        "Floor": "Floor(number: number) → number",
        "Ceil": "Ceil(number: number) → number"
    ]

    static let eachSignature = "Each(array: any[], varName: string, template: any)"

    // The built-in action steps, in prompt order, with the flag each needs.
    static let builtinSteps: [(name: String, signature: String, description: String)] = [
        ("Run", "Run(ref: Query | Mutation)", "Execute a Mutation or re-fetch a Query (ref must be a declared Query/Mutation)"),
        (
            "ToAssistant",
            "ToAssistant(message: string, context?: any)",
            "Send a message to the assistant (for conversational buttons like \"Tell me more\", \"Explain this\"). The optional context is any value (object, array, string, number) passed to the assistant as hidden data, e.g. @ToAssistant(\"Show details\", {orderId: 42})"
        ),
        ("OpenUrl", "OpenUrl(url: string)", "Navigate to a URL"),
        ("Set", "Set(variable: $variable, value: any)", "Set a $variable to a specific value"),
        (
            "Reset",
            "Reset(variable: $variable)",
            "Reset $variables to their declared defaults; pass several to reset each (e.g. @Reset($title, $priority) restores $title=\"\" and $priority=\"medium\")"
        )
    ]

    static let actionHeader = "## Action — Button Behavior"

    /// The built-in steps the prompt lists: `@Run` needs tool calls, `@Set` and `@Reset` bindings.
    static func listedSteps(toolCalls: Bool, bindings: Bool) -> [(name: String, signature: String, description: String)] {
        builtinSteps.filter { step in
            switch step.name {
            case "Run": return toolCalls
            case "Set", "Reset": return bindings
            default: return true
            }
        }
    }

    static func functionLine(_ function: PromptSpec.Component) -> String {
        guard let description = function.description, !description.isEmpty else { return "@\(function.signature)" }
        return "@\(function.signature) — \(description)"
    }

    /// Whether a signature has a slot that takes only some steps: `share?: @CopyToClipboard | @OpenUrl`.
    static func hasRestrictedSlot(_ signature: String) -> Bool {
        signature.range(of: "[:|] @[A-Z]", options: .regularExpression) != nil
    }

    static func builtinFunctionsSection(_ custom: [String], toolCalls: Bool) -> String {
        let builtinLines = Builtins.definitions.map { definition in
            functionLine(PromptSpec.Component(
                name: definition.name,
                signature: builtinFunctionSignatures[definition.name] ?? definition.signature,
                description: definition.description
            ))
        }
        let lazyLines = Builtins.lazyDefinitions.map { functionLine(PromptSpec.Component(name: "Each", signature: eachSignature, description: $0.description)) }
        let lines = (builtinLines + lazyLines + custom).joined(separator: "\n")
        return """
        ## Built-in Functions

        Data functions prefixed with `@` to distinguish from components. These are the ONLY functions available — do NOT invent new ones.
        Use @-prefixed built-in functions (@Count, @Sum, @Avg, @Min, @Max, @Round) on \(toolCalls ? "Query results" : "data"). Do NOT hardcode computed values.

        \(lines)

        Builtins compose — output of one is input to the next:
        `@Count(@Filter(data.rows, "field", "==", "val"))` for KPIs/chart values, `@Round(@Avg(data.rows.score), 1)`, `@Each(data.rows, "item", Comp(item.field))` for per-item rendering.
        Array pluck: `data.rows.field` extracts a field from every row → use with @Sum, @Avg, charts, tables.

        IMPORTANT @Each rule: The loop variable (e.g. "item") is ONLY available inside the @Each template expression. Always inline the template — do NOT extract it to a separate statement.
        CORRECT: `list = @Each(rows, "t", Comp(t.name))`
        WRONG: `item = Comp(t.name)` then `list = @Each(rows, "t", item)`, because t is undefined in item.
        """
    }

    static let querySection = """
    ## Query — Live Data Fetching

    Fetch data from available tools. Returns defaults instantly, swaps in real data when it arrives.

    ```
    metrics = Query("tool_name", {arg1: value, arg2: $binding}, {defaultField: 0, defaultData: []}, refreshInterval?)
    ```

    - First arg: tool name (string)
    - Second arg: arguments object (may reference $bindings — re-fetches automatically on change)
    - Third arg: default data (rendered immediately before fetch resolves)
    - Fourth arg (optional): refresh interval in seconds (e.g. 30 for auto-refresh every 30s)
    - Use dot access on results: metrics.totalEvents, metrics.data.day (array pluck)
    - Query results must use regular identifiers: `metrics = Query(...)`, NOT `$metrics = Query(...)`
    - Manual refresh: `Button("Refresh", Action([@Run(query1), @Run(query2)]), "secondary")` — re-fetches the listed queries
    - Refresh all queries: create Action with @Run for each query
    """

    static let mutationSection = """
    ## Mutation — Write Operations

    Execute state-changing tool calls (create, update, delete). Unlike Query (auto-fetches on render), Mutation fires only on button click via Action.

    ```
    result = Mutation("tool_name", {arg1: $binding, arg2: "value"})
    ```

    - First arg: tool name (string)
    - Second arg: arguments object (evaluated with current $binding values at click time)
    - result.status: "idle" | "loading" | "success" | "error"
    - result.data: tool response on success
    - result.error: error message on failure
    - Mutation results use regular identifiers: `result = Mutation(...)`, NOT `$result`
    - Show loading state: `result.status == "loading" ? TextContent("Saving...") : null`
    """

    static func actionSection(toolCalls: Bool, bindings: Bool, custom: [String]) -> String {
        let steps = listedSteps(toolCalls: toolCalls, bindings: bindings).map { step in
            "- " + functionLine(PromptSpec.Component(name: step.name, signature: step.signature, description: step.description))
        } + custom

        var examples: [String] = []
        if toolCalls {
            examples.append("""
            Example — mutation + refresh + reset (PREFERRED pattern):
            ```
            $binding = "default"
            result = Mutation("tool_name", {field: $binding})
            data = Query("tool_name", {}, {rows: []})
            onSubmit = Action([@Run(result), @Run(data), @Reset($binding)])
            ```
            """)
        }
        examples.append("""
        Example — simple nav:
        ```
        viewBtn = Button("View", @OpenUrl("https://example.com"))
        ```
        """)

        var rules = [
            "- An action can be assigned to a variable or inlined: Button(\"Go\", onSubmit) and Button(\"Go\", Action([...])) both work"
        ]
        if toolCalls {
            rules.append("- If a @Run(mutation) step fails, remaining steps are skipped (halt on failure)")
            rules.append("- @Run(queryRef) re-fetches the query (fire-and-forget, cannot fail)")
        }

        return """
        \(actionHeader)

        An action wires a button click to operations. Pass one @-prefixed step bare, e.g. Button("Ask", @ToAssistant("Tell me more")). Put several steps in Action([...]), e.g. Button("Read", Action([@OpenUrl("https://example.com"), @ToAssistant("Summarize this page")])). Steps execute in order.
        Buttons without an action automatically send their label to the assistant (equivalent to @ToAssistant(label)).

        Available steps:
        \(steps.joined(separator: "\n"))

        \(examples.joined(separator: "\n\n"))

        \(rules.joined(separator: "\n"))
        """
    }

    static let interactiveFiltersSection = """
    ## Interactive Filters

    To let the user filter data with a dropdown:
    1. Declare a $variable with a default: `$dateRange = "14"`
    2. Create a Select with name, items, and binding: `Select("dateRange", [SelectItem("7", "Last 7 days"), ...], null, null, $dateRange)`
    3. Wrap in FormControl for a label: `FormControl("Date Range", Select(...))`
    4. Pass $dateRange in Query args: `Query("tool", {dateRange: $dateRange}, {defaults})`
    5. When the user changes the Select, $dateRange updates and the Query automatically re-fetches

    FILTER WIRING RULE: If a $binding filter is visible in the UI, EVERY relevant Query MUST reference that $binding in its args. Never show a filter dropdown while hardcoding the query args.

    Rules for $variables:
    - $variables hold simple values (strings or numbers), NOT arrays or objects
    - $variables must be bound to a Select/Input component via the value argument (last positional arg) to be interactive
    - Queries must use regular identifiers (NOT $variables): `metrics = Query(...)` not `$metrics = Query(...)`
    - **Auto-declare**: You do NOT need to explicitly declare $variables. If you use `$foo` without declaring it, the parser auto-creates `$foo = null`. You can still declare explicitly to set a default: `$days = "14"`

    ## Forms

    Simple form — no $bindings needed. Field values are managed internally by the Form via the name prop:
    ```
    contactForm = Form("contact", submitBtn, [nameField, emailField])
    nameField = FormControl("Name", Input("name", "Your name", "text", {required: true}))
    emailField = FormControl("Email", Input("email", "your@email.com", "email", {required: true, email: true}))
    submitBtn = Button("Submit")
    ```

    Use $bindings when you need to read field values elsewhere (in Action context, Query args, or conditionals). They are auto-declared:
    ```
    $role = "engineer"
    contactForm = Form("contact", submitBtn, [nameField, emailField, roleField])
    nameField = FormControl("Name", Input("name", "Enter your name", "text", {required: true}, $name))
    emailField = FormControl("Email", Input("email", "Enter your email", "email", {required: true, email: true}, $email))
    roleField = FormControl("Role", Select("role", [SelectItem("engineer", "Engineer"), SelectItem("designer", "Designer"), SelectItem("pm", "PM")], null, {required: true}, $role))
    submitBtn = Button("Submit")
    ```

    For form + mutation patterns (create, refresh, reset), see the Action section example above.

    IMPORTANT: Always add validation rules to form fields used with Mutations. Use OBJECT syntax: {required: true, email: true, minLength: 8}. The renderer shows error messages automatically and blocks submit when validation fails.
    """

    static let editModeSection = """
    ## Edit Mode

    The runtime merges by statement name: same name = replace, new name = append.
    Output ONLY statements that changed or are new. Everything else is kept automatically.

    ### Delete
    To remove a component, re-declare its parent without that component in the parent's children array. The removed component and any statements only it referenced are automatically garbage-collected.

    ### Patch size guide
    - Changing a title or label: 1 statement
    - Adding a component: 2-3 statements (the new component + parent update)
    - Removing a component: 1 statement (re-declare parent without the removed child)
    - Adding a filter + wiring to query: 3-5 statements
    - Restructuring into tabs: 5-10 statements

    ### Rules
    - Reuse existing statement names exactly — do not rename
    - Do NOT re-emit unchanged statements — the runtime keeps them
    - A typical edit patch is 1-10 statements, not 20+
    - If the existing code already satisfies the request, output only the root statement
    - NEVER output the entire program as a patch. Only output what actually changes
    - If you are about to output more than 10 statements, reconsider — most edits need fewer
    """

    static func streamingRules(rootName: String, supportsExpressions: Bool, toolCalls: Bool) -> String {
        var steps = ["1. `root = \(rootName)(...)` — UI shell appears immediately"]
        if supportsExpressions {
            steps.append("2. $variable declarations — state ready for bindings")
            if toolCalls {
                steps.append("3. Query statements — defaults resolve immediately so components render with data")
            }
            let count = steps.count
            steps.append("\(count + 1). Component definitions — fill in with data already available")
            steps.append("\(count + 2). Data values — leaf content last")
        } else {
            steps.append("2. Component definitions — fill in as they stream")
            steps.append("3. Data values — leaf content last")
        }
        return """
        ## Hoisting & Streaming (CRITICAL)

        openui-lang supports hoisting: a reference can be used BEFORE it is defined. The parser resolves all references after the full input is parsed.

        During streaming, the output is re-parsed on every chunk. Undefined references are temporarily unresolved and appear once their definitions stream in. This creates a progressive top-down reveal — structure first, then data fills in.

        **Recommended statement order for optimal streaming:**
        \(steps.joined(separator: "\n"))

        Always write the root = \(rootName)(...) statement first so the UI shell appears immediately, even before child data has streamed in.
        """
    }

    static let inlineModeSection = """
    ## Inline Mode

    You are in inline mode. You can respond in two ways:

    ### 1. Code response (when the user wants to CREATE or CHANGE the UI)
    Wrap openui-lang code in triple-backtick fences. You can include explanatory text before/after:

    Here's your dashboard:

    ```openui-lang
    root = RootComp([header, content])
    header = SomeHeader("Title")
    content = SomeContent("Hello world")
    ```

    I created a simple layout with a header.

    ### 2. Text-only response (when the user asks a QUESTION)
    If the user asks "what is this?", "explain the chart", "how does this work", etc. — respond with plain text. Do NOT output any openui-lang code. The existing dashboard stays unchanged.

    ### Rules
    - When the user asks for changes, output ONLY the changed/new statements in a fenced block
    - When the user asks a question, respond with text only — NO code. The dashboard stays unchanged.
    - The parser extracts code from fences automatically. Text outside fences is shown as chat.
    """

    static let toolWorkflowSection = """
    ## Data Workflow

    When tools are available, follow this workflow:
    1. FIRST: Call the most relevant tool to inspect the real data shape before generating code
    2. Use Query() for READ operations (data that should stay live) — NEVER hardcode tool results as literal arrays or objects
    3. Use Mutation() for WRITE operations (create, update, delete) — triggered by button clicks via @Run(mutationRef)
    4. Use the real data from step 1 as condensed Query defaults (3-5 rows) so the UI renders immediately
    5. Use @-prefixed builtins (@Count, @Filter, @Sort, @Sum) on Query results for KPIs and aggregations — the runtime evaluates these live on every refresh
    6. Hardcoded arrays are ONLY for static display data (labels, options) where no tool exists

    WRONG — you called a tool and got data back, but you inlined the results:
    ```
    openCount = 2
    item1 = SomeComp("first item title")
    item2 = SomeComp("second item title")
    list = SomeList([item1, item2])
    chart = SomeChart(["A", "B"], [12, 8])
    ```
    This is static — it shows stale data and won't update. Creating item1, item2, item3... manually is ALWAYS wrong when a tool exists.

    RIGHT — use Query() for live data, Mutation() for writes, @builtins to derive values:
    ```
    data = Query("tool_name", {}, {rows: []})
    openCount = @Count(@Filter(data.rows, "field", "==", "value"))
    list = @Each(data.rows, "item", SomeComp(item.title, item.field))
    createResult = Mutation("create_tool", {title: $title})
    submitBtn = Button("Create", Action([@Run(createResult), @Run(data), @Reset($title)]))
    ```
    Everything derives from the Query — when data refreshes, the entire dashboard updates automatically.
    """

    static func importantRules(rootName: String, toolCalls: Bool, bindings: Bool) -> String {
        var verifyLines = [
            "1. root = \(rootName)(...) is the FIRST line (for optimal streaming).",
            "2. Every referenced name is defined. Every defined name (other than root) is reachable from root."
        ]
        if toolCalls {
            verifyLines.append("3. Every Query result is referenced by at least one component.")
        }
        if bindings {
            verifyLines.append("\(toolCalls ? "4" : "3"). Every $binding appears in at least one component or expression.")
        }
        if toolCalls && bindings {
            verifyLines.append("5. Every visible filter $binding appears in at least one Query args object.")
        }
        return """
        ## Important Rules
        - Choose components that best represent the content (tables for comparisons, charts for trends, forms for input, etc.)

        ## Final Verification
        Before finishing, walk your output and verify:
        \(verifyLines.joined(separator: "\n"))
        """
    }

    static func toolSignature(_ tool: ToolSpec) -> String {
        var args = ""
        if case .object(let properties)? = tool.inputSchema["properties"], !properties.isEmpty {
            let required = tool.inputSchema["required"]?.arrayValue?.compactMap(\.stringValue) ?? []
            args = properties.entries.map { key, value in
                "\(key)\(required.contains(key) ? "" : "?"): \(jsonSchemaTypeString(value))"
            }.joined(separator: ", ")
        }
        let returnType = " → \(jsonSchemaTypeString(tool.outputSchema))"
        var line = "- \(tool.name)(\(args))\(returnType)"
        if let description = tool.description, !description.isEmpty {
            line += "\n  \(description)"
        }
        return line
    }

    static func toolsSection(_ tools: [ToolDescriptor]) -> String {
        var lines = [
            "## Available Tools",
            "",
            "Use these with Query() for read operations or Mutation() for write operations. The LLM decides which is appropriate based on the tool's purpose.",
            ""
        ]
        var specTools: [ToolSpec] = []
        for tool in tools {
            if case .name(let name) = tool { lines.append("- \(name)") }
        }
        for tool in tools {
            if case .spec(let spec) = tool {
                specTools.append(spec)
                lines.append(toolSignature(spec))
            }
        }
        if !specTools.isEmpty {
            lines.append("")
            lines.append("### Default values for Query results")
            lines.append("")
            lines.append("Use these shapes as minimal Query defaults:")
            for tool in specTools {
                lines.append("- \(tool.name): `\(OpenUIJSON.stringify(defaultValue(for: tool.outputSchema)))`")
            }
        }
        lines.append("")
        lines.append("CRITICAL: Use ONLY the tools listed above in Query() and Mutation() calls. Do NOT invent or guess tool names. If the user asks for functionality that doesn't match any available tool, use realistic mock data instead of fabricating a tool call.")
        return lines.joined(separator: "\n")
    }

    static func componentSignatures(_ spec: PromptSpec, toolCalls: Bool, bindings: Bool, usesActionExpression: Bool) -> String {
        var lines = [
            "## Component Signatures",
            "",
            "Arguments marked with ? are optional. Sub-components can be inline or referenced; prefer references for better streaming."
        ]
        if usesActionExpression {
            let steps = (listedSteps(toolCalls: toolCalls, bindings: bindings).map(\.name) + spec.actions.map(\.name)).map { "@\($0)" }
            lines.append("Props typed `ActionExpression` accept one @step, or Action([@steps...]) for several. See the Action section for available steps (\(steps.joined(separator: ", "))).")
            if spec.components.contains(where: { hasRestrictedSlot($0.signature) }) {
                lines.append("Props typed like `@OpenUrl | @ToAssistant` accept only the steps listed.")
            }
        }
        if bindings || spec.components.contains(where: { $0.signature.contains("$binding") }) {
            lines.append("Props marked `$binding<type>` accept a `$variable` reference for two-way binding.")
        }

        func format(_ component: PromptSpec.Component) -> String {
            if let description = component.description, !description.isEmpty {
                return "\(component.signature) — \(description)"
            }
            return component.signature
        }

        let byName = Dictionary(spec.components.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        if !spec.componentGroups.isEmpty {
            var grouped = Set<String>()
            for group in spec.componentGroups {
                lines.append("")
                lines.append("### \(group.name)")
                for name in group.components where !grouped.contains(name) {
                    guard let component = byName[name] else { continue }
                    grouped.insert(name)
                    lines.append(format(component))
                }
                lines.append(contentsOf: group.notes)
            }
            let ungrouped = spec.components.filter { !grouped.contains($0.name) }
            if !ungrouped.isEmpty {
                lines.append("")
                lines.append("### Other")
                lines.append(contentsOf: ungrouped.map(format))
            }
        } else {
            lines.append("")
            lines.append(contentsOf: spec.components.map(format))
        }
        return lines.joined(separator: "\n")
    }
}
