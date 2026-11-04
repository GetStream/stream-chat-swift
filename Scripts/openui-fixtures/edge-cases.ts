// Hand-written edge cases for the conformance corpus. Each entry: [name, library, source].
// library: "chat" | "playground" | "mini"
export const edgeCases: [string, string, string][] = [
  ["basic-card", "chat", `root = Card([header, body])
header = CardHeader("Hello", "World")
body = TextContent("Some **markdown** text")`],

  ["comments", "chat", `// leading comment
root = Card([t1, t2]) // trailing comment
# python style comment
t1 = TextContent("not // a comment")
t2 = TextContent("not # a comment either") # but this is`],

  ["fenced-with-prose", "chat", "Here's your answer:\n\n```openui-lang\nroot = Card([t])\nt = TextContent(\"Inside fence\")\n```\n\nLet me know if you want changes."],

  ["two-fences", "chat", "```openui-lang\nroot = Card([a, b])\na = TextContent(\"A\")\n```\nsome text\n```\nb = TextContent(\"B\")\n```"],

  ["unclosed-fence", "chat", "```openui-lang\nroot = Card([a])\na = TextContent(\"streaming"],

  ["single-quotes", "chat", `root = Card([a, b])
a = TextContent('single \\'quoted\\' text\\nnext line')
b = TextContent('tab\\there and backslash \\\\ and \\x unknown')`],

  ["unicode-escapes", "chat", `root = Card([a, b, c])
a = TextContent("caf\\u00e9 \\u2014 na\\u00efve \\ud83d\\ude00")
b = TextContent("emoji raw 🎉 and ümlaut")
c = TextContent("escaped \\"quotes\\" and \\\\ backslash and \\/ slash")`],

  ["raw-newline-in-string", "chat", `root = Card([a])
a = TextContent("line one
line two with \\"escape\\" kept raw")`],

  ["numbers", "mini", `root = Stack([-5, 3.14, 1e3, 1e21, 1e-7, 0.000001, 123456789012345680000, -0.5, 1.5e-10, 2E+5, 0x10, 1e, 007])`],

  ["minus-disambiguation", "mini", `root = Stack([a - 1, a -1, a-1, -a, - 1, (1)-1, [1]-1, "x"-1, $s-1, @Count(a)-1, 3 - -2])
a = 5`],

  ["operators", "mini", `root = Stack([a + b * c - d / e % f, a == b && c != d || !e, a > b, a < b, a >= b, a <= b, (a + b) * c, -a * b, !a == b, a & b, a | b])`],

  ["ternaries", "mini", `$x = 3
root = Stack([$x > 2 ? "big" : "small", $x == 1 ? "one" : $x == 2 ? "two" : "many", cond
  ? yes
  : no, a ? b ? c : d : e])
cond = true
yes = "Y"
no = "N"`],

  ["member-index", "mini", `data = Query("tool", {}, {rows: [{title: "a", n: 1}], meta: {total: 2}})
root = Stack([data.rows.title, data.meta.total, data.rows[0].title, data["meta"]["total"], @First(data.rows).title, data.rows.length, a.0, a.1.5, a.$b, a.true, a.(x)])`],

  ["state-vars", "mini", `$a = [1, 2, 3]
$b = {x: 1, y: "two"}
$c = "s" + "t"
$d = $a
$e = Title("component in state")
root = Stack([$a, $b.x, $c, $undeclared, $d])`],

  ["assign-expression", "mini", `$count = 0
root = Stack([$count = $count + 1, Action([@Set($count, $count + 1)])])`],

  ["query-mutation", "chat", `$days = "7"
$title = ""
data = Query("analytics", {days: $days, q: $title}, {rows: []}, 30)
static = Query("static_tool", {}, {value: 0})
create = Mutation("create_item", {title: $title, days: $days})
$q = Query("dollar_query", {}, {})
root = Card([tbl, btn, status])
tbl = Table([Col("Day", data.rows.day), Col("Views", data.rows.views, "number")])
btn = Button("Create", Action([@Run(create), @Run(data), @Reset($title), @ToAssistant("Created", "ctx"), @OpenUrl("https://example.com")]))
status = create.status == "error" ? Callout("error", "Failed", create.error) : null`],

  ["inline-query", "chat", `root = Card([TextContent("" + Query("tool", {}, {}).x), t])
t = TextContent(Query("x", {}, {}))`],

  ["actions-without-at", "chat", `root = Card([b1, b2, b3])
b1 = Button("Plain")
b2 = Button("Bare", Action([Run(data), Set($x, 1)]))
b3 = Button("Legacy", {type: "continue_conversation", context: "ctx"})
data = Query("t", {}, {})`],

  ["each", "chat", `rows = Query("list", {}, {rows: [{id: "1", status: "open", title: "A"}]})
root = Card([tbl, tags, nested])
tbl = Table([Col("Title", rows.rows.title), Col("Actions", @Each(rows.rows, "t", Button("Edit", Action([@Set($editId, t.id)]))))])
tags = TagBlock(@Each(rows.rows, "item", item.status))
nested = Steps(@Each(rows.rows, "r", StepsItem(r.title, "" + @Count(@Each(rows.rows, "inner", inner.id)))))`],

  ["each-shadowing-and-ref-var", "chat", `t = TextContent("statement t")
items = [1, 2]
root = Card([t, list])
list = TagBlock(@Each(items, t, "" + t))
bad = @Each(items, "")`],

  ["builtins-without-at", "mini", `rows = [1, 2, 3]
root = Stack([Count(rows), Sum(rows) + 1, @Sum(rows), @Round(@Avg(rows), 2), @Filter(rows, "", ">", 1), @Sort(rows, "", "desc")])`],

  ["unknown-in-expression", "chat", `$show = true
root = Card([$show ? Ghost("x") : TextContent("y"), Phantom()])`],

  ["cycles", "chat", `root = Card([a, root])
a = Card([b])
b = Card([a, TextContent("leaf")])`],

  ["duplicates", "chat", `root = Card([a])
a = TextContent("first")
a = TextContent("second")
root = Card([a, a])`],

  ["orphans-and-states", "chat", `root = Card([used])
used = TextContent("used")
orphan1 = TextContent("orphan")
orphan2 = "plain value"
$state = 1
q = Query("t", {}, {})
m = Mutation("t", {})`],

  ["entry-no-root-first-component", "chat", `$x = 1
values = [1, 2]
main = Card([TextContent("main")])
other = Card([TextContent("other")])`],

  ["entry-rootname-statement", "chat", `intro = TextContent("intro")
Card = Card([intro])`],

  ["entry-rootname-component", "chat", `x = TextContent("x")
page = Card([x])`],

  ["entry-only-values", "chat", `a = 1
b = "two"`],

  ["entry-only-state", "chat", `$a = 1`],

  ["validation-errors", "chat", `root = Card([h, c, t, s, img])
h = CardHeader(123, true)
c = Callout("bogus-variant", "Title", "Desc")
t = TextContent()
s = Slider("budget", "continuous", "low", 100)
img = Image(null)`],

  ["excess-and-null-args", "chat", `root = Card([TextContent("a", "large", "extra", 4), Separator(null, null), TextContent(null)])`],

  ["garbage-lines", "chat", `this is not a statement
= Card([])
root = Card([t])
123 = TextContent("bad id")
t = TextContent("ok") trailing garbage tokens ) ] }
t2 TextContent("missing equals")
"str" = 5`],

  ["empty", "chat", ``],
  ["whitespace-only", "chat", "   \n\t\n  "],
  ["comments-only", "chat", "// nothing here\n# nor here"],

  ["truncated-string", "chat", `root = Card([a, b])
a = TextContent("complete")
b = TextContent("partial str`],

  ["truncated-object", "chat", `root = Card([t])
t = Table([Col("A", [1, 2`],

  ["truncated-escape", "chat", `root = Card([t])
t = TextContent("ends with backslash \\`],

  ["object-keys", "mini", `root = Stack([{a: 1, "b c": 2, 3: "three", $d: 4, Type: 5, true: 6, a: 7}, {x: 1,}, {y 2}, {: 3}])`],

  ["deep-nesting", "mini", `root = Stack([[[[[[[[[[1]]]]]]]]], {a: {b: {c: {d: {e: [1, {f: "g"}]}}}}}])`],

  ["crlf", "chat", "root = Card([a, b])\r\na = TextContent(\"crlf a\")\r\nb = TextContent(\"crlf b\")\r\n"],

  ["tabs-and-spaces", "chat", "root\t=\tCard([ a ,\tb ])\n\ta = TextContent(\t\"tab\"\t)\n    b = TextContent(  \"spaces\"  )"],

  ["unicode-identifiers", "chat", `root = Card([café])
café = TextContent("x")
naïve = TextContent("y")`],

  ["sources-and-citations", "chat", `root = Card([t], [src1, {title: "Inline", sourceName: "Site"}])
t = TextContent("Fact one [1] and two [2].")
src1 = {title: "First", sourceName: "Example", url: "https://example.com"}`],

  ["forms", "chat", `$role = "engineer"
root = Card([form])
form = Form("contact", btns, [f1, f2, f3, f4])
f1 = FormControl("Name", Input("name", "Your name", "text", {required: true, minLength: 2}))
f2 = FormControl("Email", Input("email", "you@example.com", "email", {required: true, email: true}, $email))
f3 = FormControl("Role", Select("role", [SelectItem("engineer", "Engineer"), SelectItem("pm", "PM")], null, {required: true}, $role))
f4 = FormControl("Budget", Slider("budget", "discrete", 500, 10000, 500, [2500], "Budget (USD)"))
btns = Buttons([Button("Submit", Action([@ToAssistant("Submit")]), "primary"), Button("Cancel", null, "secondary")])`],

  ["playground-stack-modal", "playground", `$showModal = false
root = Stack([title, row, modal], "column", "l")
title = TextContent("Dashboard", "large-heavy")
row = Stack([Card([TextContent("A")], "sunk"), Card([TextContent("B")])], "row", "m", "center", "between", true)
modal = Modal("Edit", $showModal, [Form("edit", Buttons([Button("Save", Action([@Set($showModal, false)]))]), [])])`],

  ["charts", "chat", `root = Card([bar, line, pie, scatter, radar])
bar = BarChart(["Q1", "Q2"], [Series("A", [1, 2]), Series("B", [3, 4])], "stacked", "Quarter", "Revenue", 240)
line = LineChart(["Mon", "Tue"], [Series("Views", [10, 20])], "natural")
pie = PieChart(["Low", "High"], [3, 7], "donut", "semiCircular")
scatter = ScatterChart([ScatterSeries("S", [Point(1, 2), Point(3, 4, 5)])], "x", "y")
radar = RadarChart(["Speed", "Power"], [Series("Car", [5, 8])])`],

  ["multiline-call", "chat", `root = Card([
  header,
  TextContent(
    "multi line call"
  )
])
header = CardHeader(
  "Title",
  "Subtitle"
)`],

  ["ternary-continuation-after-blank-lines", "mini", `$a = 1
root = Stack([x])
x = $a == 1

  ? "one"

  : "other"
y = 2`],

  ["edit-patch-style", "chat", `root = Card([header, chart, tbl])
chart = PieChart(["Open", "Closed"], [@Count(@Filter(tickets.rows, "status", "==", "open")), @Count(@Filter(tickets.rows, "status", "==", "closed"))], "donut")`],

  ["weird-tokens", "mini", `root = Stack([@, $, @1, $1, ?, :, ., ;, ~, \`, a ?? b, a === b, a !== b, => x])`],
];
