// OpenUI 1.0 cases, added only when the generator runs against a 1.0 clone. Names get a `v1-` prefix.
// library: "chat" | "playground" | "mini" | "spec" (spec/fixtures/1.0/library.json)

/** Parser cases: [name, library, source]. Every non-mini one is also an evaluator `corpus-v1-*` case. */
export const v1ParserCases: [string, string, string][] = [
  // ─── Entry rule: `root`, else the first statement that calls the root component ───
  ["entry-root-statement-last", "chat", `header = CardHeader("Orders")
body = TextContent("Body")
root = Card([header, body])`],

  ["entry-first-calls-root-component-later", "chat", `$tab = "a"
intro = TextContent("intro")
main = Card([intro])
other = Card([TextContent("other")])`],

  ["entry-root-arrives-late", "chat", `intro = TextContent("Intro")
draft = Card([intro])
root = Card([intro, TextContent("Final")])`],

  ["entry-no-root-component-call", "chat", `title = CardHeader("Orders")
list = ListBlock([ListItem("a")])`],

  ["entry-root-not-a-component", "chat", `root = "hello"
t = TextContent("x")`],

  ["entry-root-ref-chain", "chat", `root = page
page = main
main = Card([TextContent("via refs")])`],

  ["entry-root-dropped-by-validation", "chat", `root = Card(42)`],

  ["entry-ternary-root", "chat", `$tab = "a"
root = $tab == "a" ? Card([TextContent("A")]) : Card([TextContent("B")])`],

  ["entry-ternary-root-refs-multiline", "chat", `$dark = true
root = $dark
  ? darkCard
  : lightCard
darkCard = Card([TextContent("Dark")])
lightCard = Card([TextContent("Light")])`],

  ["entry-ternary-root-not-a-component", "chat", `$x = 1
root = $x > 0 ? "yes" : "no"`],

  ["entry-no-root-name", "mini", `x = Title("t")
page = Stack([x])`],

  ["entry-root-statement-no-root-name", "mini", `root = Stack([Title("t")])`],

  // ─── Bare action steps (one @step without Action([...])) ───
  ["bare-steps", "chat", `$q = ""
save = Mutation("save", {q: $q})
data = Query("search", {q: $q}, {rows: []})
root = Card([Buttons([ask, open, run, refetch, reset, set, both])])
ask = Button("Ask", @ToAssistant("Tell me more"))
open = Button("Open", @OpenUrl("https://example.com"))
run = Button("Save", @Run(save))
refetch = Button("Refresh", @Run(data))
reset = Button("Clear", @Reset($q))
set = Button("Fill", @Set($q, "shoes"))
both = Button("Both", Action([@OpenUrl("https://example.com"), @ToAssistant("Summarize", {id: 1})]))`],

  ["bare-step-statements", "chat", `askStep = @ToAssistant("hi")
plan = Action([askStep, @OpenUrl("https://a.b")])
root = Card([Buttons([Button("One", askStep), Button("Plan", plan), Button("List", [@ToAssistant("x"), @OpenUrl("https://c.d")])])])`],

  ["invalid-steps", "chat", `$a = 1
root = Card([Buttons([b1, b2, b3, b4, b5, b6])])
b1 = Button("Run unknown", @Run(nothing))
b2 = Button("Set literal", @Set("a", 2))
b3 = Button("Set one arg", @Set($a))
b4 = Button("Open nothing", @OpenUrl())
b5 = Button("Empty", Action([]))
b6 = Button("Not a list", Action("x"))`],

  // ─── @Name(...) calls that are not built-ins or library functions ───
  ["unknown-functions", "chat", `root = Card([a, b, c, d])
a = TextContent(@Nope(1))
b = TextContent("x" + @Missing())
c = TextContent(@Upper("hi"))
d = TextContent("" + @Count([1, 2]))
v = @Unknown(2)`],

  ["unknown-function-in-query", "chat", `data = Query("t", {n: @Nope(1), c: @Count([1])}, {rows: []})
root = Card([TextContent("" + @Count(data.rows))])`],

  ["builtins-named-args", "mini", `root = Stack([@Count([1]), @Round(1.25, 1), @Sum([1, 2]), @Filter([1, 2], "", ">", 1), @Each([1], "n", n), @Sort([2, 1], "", "desc")])`],

  // ─── Library functions and actions (spec library: @Upper, @CopyToClipboard) ───
  ["spec-functions-and-actions", "spec", `$name = "ada"
root = Stack([t1, t2, t3, t4, t5, b1, b2, b3])
t1 = Text(@Upper("hi"))
t2 = Text(@Upper($name))
t3 = Text(@Upper(5))
t4 = Text(@Upper())
t5 = Text(@Upper("a", "b"))
b1 = Button("Copy", @CopyToClipboard("abc"))
b2 = Button("Bad copy", @CopyToClipboard(5))
b3 = Button("Share", null, "primary", @OpenUrl("https://openui.com"))`],

  ["spec-restricted-action-slot", "spec", `root = Stack([ok, bad, data])
ok = Button("Share", null, null, @CopyToClipboard("link"))
bad = Button("Ask", null, null, @ToAssistant("not allowed here"))
data = Button("Legacy", {type: "open_url", url: "https://openui.com"})`],

  // ─── The stream parser's `complete` flag: a trailing `$name` may still be growing ───
  ["complete-trailing-state-ref", "mini", `$count = 1
root = Stack([Title("n: " + $count), Title("" + $total`],

  ["complete-trailing-ref-seen-before", "mini", `root = Stack([$a, $a`],

  ["complete-trailing-query-arg", "chat", `root = Card([TextContent("" + @Count(data.rows))])
data = Query("search", {q: $searchTerm`],

  ["complete-closed-statement", "chat", `root = Card([TextContent($greeting)])
$greeting = "hi"
`],
];

export type EvalCase = {
  name: string;
  library: string;
  input: string;
  state?: Record<string, unknown>;
  refs?: Record<string, unknown>;
  /** Refs read at stream end: a query's defaults, a mutation `{status: "idle", data: null, error: null}`. */
  streamEndRefs?: boolean;
};

export const v1EvalCases: EvalCase[] = [
  {
    name: "v1-bare-steps",
    library: "chat",
    input: `$a = 0
u = "https://example.com/" + $a
q = Query("list", {a: $a}, {rows: []})
m = Mutation("save", {a: $a})
root = Card([Buttons([b1, b2, b3, b4, b5, b6])])
b1 = Button("Ask", @ToAssistant("x"))
b2 = Button("Set", @Set($a, 1))
b3 = Button("Run", @Run(q))
b4 = Button("Reset", @Reset($a))
b5 = Button("Open", @OpenUrl(u))
b6 = Button("Save", @Run(m))`,
    state: { $a: 3 },
    refs: { q: { rows: [{ id: 1 }] }, m: { status: "idle" } },
  },
  {
    name: "v1-action-flattening",
    library: "chat",
    input: `$a = 1
inner = Action([@OpenUrl("https://x.y"), @Set($a, 2)])
one = @Reset($a)
root = Card([Buttons([b1, b2, b3])])
b1 = Button("Nested", Action([@ToAssistant("a"), inner, Action([one, Action([@ToAssistant("deep")])])]))
b2 = Button("Junk", Action([@ToAssistant("kept"), null, "junk", 5, {foo: 1}, {type: "continue_conversation", message: "legacy"}]))
b3 = Button("List", [inner, @ToAssistant("b")])`,
  },
  {
    name: "v1-invalid-steps",
    library: "chat",
    input: `$a = 1
root = Card([Buttons([b1, b2, b3, b4, b5, b6, b7])])
b1 = Button("Run unknown", @Run(nothing))
b2 = Button("Set literal", @Set("a", 2))
b3 = Button("Set one arg", @Set($a))
b4 = Button("Reset none", @Reset())
b5 = Button("Empty", Action([]))
b6 = Button("Not a list", Action("x"))
b7 = Button("Mixed", Action([@Run(nothing), @ToAssistant("still runs")]))`,
  },
  {
    name: "v1-to-assistant-contexts",
    library: "chat",
    input: `$ctx = {id: 7}
root = Card([Buttons([c1, c2, c3, c4, c5, c6, c7, c8, c9, c10])])
c1 = Button("Object", @ToAssistant("m", {orderId: 42, tags: ["rush"]}))
c2 = Button("Array", @ToAssistant("m", [1, "two", null]))
c3 = Button("Number", @ToAssistant("m", 42))
c4 = Button("Zero", @ToAssistant("m", 0))
c5 = Button("False", @ToAssistant("m", false))
c6 = Button("Empty string", @ToAssistant("m", ""))
c7 = Button("Null", @ToAssistant("m", null))
c8 = Button("State", @ToAssistant("m", $ctx))
c9 = Button("String", @ToAssistant("m", "ctx"))
c10 = Button("Number message", @ToAssistant(5))`,
    state: { $ctx: { id: 9, tags: [] } },
  },
  {
    name: "v1-legacy-action-objects",
    library: "chat",
    input: `$topic = "pricing"
root = Card([Buttons([b1, b2, b3])])
b1 = Button("Legacy ask", {type: "continue_conversation", context: "ctx " + $topic})
b2 = Button("Legacy open", {type: "open_url", url: "https://openui.com"})
b3 = Button("No action")`,
  },
  {
    name: "v1-spec-functions",
    library: "spec",
    input: `$name = "ada"
$num = 5
root = Stack([t1, t2, t3, t4, t5, t6, t7])
t1 = Text(@Upper("hello"))
t2 = Text(@Upper($name))
t3 = Text(@Upper($num))
t4 = Text(@Upper($unset) == null ? "null" : "other")
t5 = Text(@Upper(@Upper("x")) + "!")
t6 = Text("" + @Count([1, 2]))
t7 = Text(@Each(["a", "b"], "s", @Upper(s)) + "")`,
  },
  {
    name: "v1-spec-custom-actions",
    library: "spec",
    input: `$name = "ada"
$count = 3
fake = {steps: [{type: "custom_action", name: "CopyToClipboard", params: {text: "x"}}]}
root = Stack([b1, b2, b3, b4, b5, b6, b7])
b1 = Button("Copy", @CopyToClipboard("abc"))
b2 = Button("Copy state", @CopyToClipboard($name))
b3 = Button("Copy missing", @CopyToClipboard($missing))
b4 = Button("Copy number", @CopyToClipboard($count))
b5 = Button("Both", Action([@CopyToClipboard(@Upper($name)), @ToAssistant("Copied")]))
b6 = Button("Share", null, null, @CopyToClipboard("link"))
b7 = Button("Fake", fake)`,
  },
  {
    name: "v1-stream-end-defaults",
    library: "chat",
    input: `$q = "x"
data = Query("search", {q: $q}, {rows: [{title: "Default A"}, {title: "Default B"}], total: 2})
save = Mutation("save", {q: $q})
root = Card([TextContent("Rows: " + @Count(data.rows)), TextContent("Total: " + data.total), TextContent("Save: " + save.status), TextContent(save.data == null ? "no data" : "data"), TextContent(save.error == null ? "no error" : "error"), Buttons([Button("Save", @Run(save))])])`,
    streamEndRefs: true,
  },
  {
    name: "v1-spec-stream-end-defaults",
    library: "spec",
    input: `$status = "open"
tickets = Query("listTickets", {status: $status}, {rows: [{title: "First"}], count: 1})
create = Mutation("createTicket", {status: $status})
root = Stack([Metric("Tickets", @Count(tickets.rows)), Text(@Upper(tickets.rows.title + "")), Text("Create: " + create.status), Button("Create", Action([@Run(create), @Run(tickets)]))])`,
    streamEndRefs: true,
  },
  {
    name: "v1-ternary-root",
    library: "chat",
    input: `$tab = "a"
root = $tab == "a" ? Card([TextContent("A")]) : Card([TextContent("B: " + $tab)])`,
    state: { $tab: "b" },
  },
  {
    name: "v1-ternary-root-null",
    library: "chat",
    input: `$open = false
root = $open ? Card([TextContent("Open")]) : null`,
  },
];
