// Evaluator conformance fixtures (evaluator-conformance.json) from the upstream evaluator.
// Usage: node --experimental-transform-types --no-warnings --import ./register.mjs gen-eval.ts \
//          --clone <openui-clone> --parser-fixtures <parser-conformance.json> --out <evaluator-conformance.json>
import { writeFileSync } from "node:fs";
import * as z from "zod/v4";
import { librarySpecs, loadUpstream, parseArgs, readJSON, specRuntime } from "./common.ts";
import { v1EvalCases, type EvalCase } from "./v1-cases.ts";

const args = parseArgs(["clone", "parser-fixtures", "out"]);
const up = await loadUpstream(args.clone);
const { compileSchema, parse } = up.parser;
const { evaluate } = up.evaluator;
const { evaluateElementProps, evaluateRoot } = up.evaluateTree;
const { markReactive } = up.reactive;
const specs = librarySpecs(args.clone);

/** Props typed `$binding<...>` in the signature are reactive. */
function reactiveProps(spec: any): Set<string> {
  const out = new Set<string>();
  for (const [name, comp] of Object.entries<any>(spec.components)) {
    for (const m of (comp.signature as string).matchAll(/(\w+)\??: \$binding</g)) out.add(`${name}.${m[1]}`);
  }
  return out;
}

/** Evaluation only reads each component's prop keys, with the reactive mark on bindable props. */
function fakeLibrary(spec: any) {
  const reactive = reactiveProps(spec);
  const components: Record<string, unknown> = {};
  for (const name of Object.keys(spec.schema.$defs)) {
    const shape: Record<string, object> = {};
    for (const prop of Object.keys(spec.schema.$defs[name].properties ?? {})) {
      const s = {};
      if (reactive.has(`${name}.${prop}`)) markReactive(s);
      shape[prop] = s;
    }
    components[name] = { props: { shape } };
  }
  return { components } as any;
}

/** The spec library exactly as conformance.test.ts builds it (createLibrary + zod, toJSONSchema = library.json). */
function specLibrary(spec: any) {
  const { createLibrary, defineComponent } = up.library;
  return {
    ...createLibrary({
      components: Object.entries<any>(spec.components).map(([name, { signature, description }]) => {
        const bindable = new Set([...signature.matchAll(/(\w+)\??: \$binding</g)].map((m: any) => m[1]));
        const props = Object.keys(spec.schema.$defs[name].properties ?? {}).map((key) => {
          const s = z.any();
          if (bindable.has(key)) markReactive(s);
          return [key, s];
        });
        return defineComponent({ name, description, props: z.object(Object.fromEntries(props)), component: null });
      }),
      root: spec.root,
    }),
    toJSONSchema: () => spec.schema,
  };
}

type Lib = { cat: any; root: string; library: any; runtime?: { functions: any; actions: any } };
const libs: Record<string, Lib> = {};
for (const key of ["chat", "playground"]) {
  libs[key] = { cat: compileSchema(specs[key].schema), root: specs[key].root, library: fakeLibrary(specs[key]) };
}
if (up.v1) {
  libs.spec = {
    cat: compileSchema(specs.spec.schema),
    root: specs.spec.root,
    library: specLibrary(specs.spec),
    runtime: specRuntime(specs.spec),
  };
}

const cases: EvalCase[] = [];

// 1. Every parser-corpus case evaluated with empty state (exercises the tree walk on real programs).
// Spec-library cases read refs at stream end, as the upstream conformance runner does.
const parserFixtures = readJSON(args["parser-fixtures"]);
for (const c of parserFixtures) {
  if (c.library === "mini") continue;
  cases.push({ name: `corpus-${c.name}`, library: c.library, input: c.input, streamEndRefs: c.library === "spec" });
}

const rows = [
  { id: "1", title: "Alpha", status: "open", priority: "high", amount: 120, score: "4.5", tags: ["a"], created: "2026-01-02" },
  { id: "2", title: "beta", status: "closed", priority: "low", amount: 80.5, score: "3", tags: [], created: "2026-03-01" },
  { id: "3", title: "Gamma", status: "open", priority: "medium", amount: "45", score: 5, created: "2025-12-31" },
  { id: "4", title: "delta", status: "pending", priority: "high", amount: null, score: "n/a", created: "2026-02-15" },
];

// 2. Expression-focused cases (TextContent text props carry the evaluated expressions).
const exprs: string[] = [
  `"" + 0.1 + 0.2`, `1 / 3`, `10 % 3`, `-7 % 3`, `5 / 0`, `5 % 0`, `"5" * "2"`, `"abc" * 2`, `true + 1`, `null + 1`,
  `"a" + null`, `[1, 2] + "x"`, `{a: 1} + ""`, `1e21 + ""`, `1e-7 + ""`, `-0 + ""`, `123456789.123456789 + ""`,
  `5 == "5"`, `0 == ""`, `null == 0`, `true == "1"`, `true == "true"`, `[1] == 1`, `"" == []`, `null == null`, `"a" != "b"`,
  `0 || "x"`, `"" && 1`, `!!"0"`, `!0`, `!null`, `3 > "2"`, `"10" < "9"`, `"a" >= 1`, `-"3"`, `-true`,
  `$n * 2 + 1`, `$s + "!"`, `$missing + 1`, `$missing == null`, `$flag ? "on" : "off"`, `$n > 3 && $s == "hi"`,
  `data.rows.title`, `data.rows.length`, `data.rows[1].title`, `data.rows[9]`, `data.rows[-1]`, `data.rows["0"].id`, `data.total`,
  `data.rows.amount`, `data.nested.deep.value`, `data.missing.deeper`, `$s.length`, `$s[1]`, `$arr[0]`, `$obj.k`, `$obj["k"]`,
  `@Count(data.rows)`, `@Count("abc")`, `@Sum(data.rows.amount)`, `@Avg(data.rows.score)`, `@Avg([])`, `@Min(data.rows.amount)`,
  `@Max([3, "7", true])`, `@First(data.rows).title`, `@Last(data.rows).id`, `@First([])`, `@Round(2.5)`, `@Round(-2.5)`,
  `@Round(1.005, 2)`, `@Round(1234.5678, 2)`, `@Round(1234.5678, -2)`, `@Abs(-3)`, `@Floor(-1.5)`, `@Ceil(1.2)`, `@Floor("x")`,
  `@Count(@Filter(data.rows, "status", "==", "open"))`, `@Filter(data.rows, "amount", ">", 50).title`,
  `@Filter(data.rows, "title", "contains", "a").id`, `@Filter(data.rows, "title", "contains", null).id`,
  `@Filter(data.rows, "score", ">=", 4).id`, `@Filter(data.rows, "priority", "!=", "high").id`, `@Filter(data.rows, "x", "??", 1)`,
  `@Sort(data.rows, "amount", "desc").id`, `@Sort(data.rows, "amount").id`, `@Sort(data.rows, "title").title`,
  `@Sort(data.rows, "created", "desc").id`, `@Sort(data.rows, "score").id`, `@Sort([3, "10", 2, "1"], "")`, `@Sort("notarray", "x")`,
  `@Each(data.rows, "r", r.title + ":" + r.status)`, `@Each(data.rows, r, r.id)`, `@Each(data.total, "r", r)`,
  `@Each([1, 2, 3], "n", n * $n)`, `@Each(data.rows, "r", @Each(r.tags, "t", r.id + t))`,
  `$n = $n + 1`, `@Count(data.rows) > 3 ? "many" : "few"`, `mut.status`, `mut.data.id`, `(mut.status == "success") + ""`,
];
const state = { $n: 4, $s: "hi", $flag: true, $arr: ["x", "y"], $obj: { k: "v" }, $name: "Ada", $show: true, $showModal: true, $visible: true };
const refs = {
  data: { rows, total: 4, nested: { deep: { value: 42 } } },
  mut: { status: "success", data: { id: "m1" } },
};
const body = exprs.map((e, i) => `t${i} = TextContent(${e})`).join("\n");
const header = `data = Query("list", {status: $s, limit: $n}, {rows: []}, 30)\nmut = Mutation("create", {title: $name})\n`;
cases.push({
  name: "expressions",
  library: "chat",
  input: `${header}root = Card([${exprs.map((_, i) => `t${i}`).join(", ")}])\n${body}`,
  state,
  refs,
});

// 3. Reactive bindings, actions, and Each templates.
cases.push({
  name: "reactive-and-actions",
  library: "chat",
  input: `$name = "Ada"
$role = "eng"
$show = true
$picked = null
data = Query("list", {role: $role}, {rows: []})
mut = Mutation("save", {name: $name, role: $role})
root = Card([form, cond, list, tbl, btns, callout])
form = Form("f", btns, [FormControl("Name", Input("name", "ph", "text", {required: true}, $name)), FormControl("Role", Select("role", [SelectItem("eng", "Engineer")], null, null, $role))])
cond = $show ? Input("inline", "Inline", "text", null, $name) : TextContent("hidden")
list = ListBlock(@Each(data.rows, "r", ListItem(r.title, r.status, null, null, Action([@Set($picked, r.id), @ToAssistant("Pick " + r.title, r.id)]))))
tbl = Table([Col("Title", data.rows.title), Col("Edit", @Each(data.rows, "r", Input("e" + r.id, r.title, "text", null, $name)))])
btns = Buttons([Button("Save", Action([@Run(mut), @Run(data), @Reset($name, $role), @OpenUrl("https://x.y/" + $role)]), "primary"), Button("Toggle", Action([@Set($show, !$show)]))])
callout = Callout("success", "Saved", "Done " + $name, $show)`,
  state: { $name: "Ada", $role: "eng", $show: true },
  refs: { data: { rows }, mut: { status: "idle" } },
});

cases.push({
  name: "playground-modal-and-bindings",
  library: "playground",
  input: `$showModal = false
$days = "7"
root = Stack([filter, modal, chart])
filter = Select("days", [SelectItem("7", "7 days"), SelectItem("30", "30 days")], null, null, $days)
modal = Modal("Edit", $showModal, [TextContent("Days: " + $days)])
chart = BarChart(data.rows.day, [Series("Views", data.rows.views)])
data = Query("analytics", {days: $days}, {rows: [{day: "Mon", views: 1}]})`,
  state: { $showModal: true, $days: "30" },
  refs: { data: { rows: [{ day: "Mon", views: 10 }, { day: "Tue", views: 20 }] } },
});

// 4. 1.0 additions.
if (up.v1) cases.push(...v1EvalCases);

function unwrap(v: any) {
  return v && typeof v === "object" && !Array.isArray(v) && "value" in v ? v.value : v;
}

const out = cases.map((c) => {
  const lib = libs[c.library];
  const result = parse(c.input, lib.cat, lib.root);
  const store: Record<string, unknown> = { ...result.stateDeclarations, ...(c.state ?? {}) };
  let refs: Record<string, unknown> = c.refs ?? {};
  const ctx: any = {
    getState: (n: string) => unwrap(store[n]),
    resolveRef: (n: string) => (refs as any)[n],
    ...(lib.runtime ?? {}),
  };
  if (c.streamEndRefs) {
    // At stream end no fetch has returned: a query reads its defaults, a mutation is idle.
    const resolved: Record<string, unknown> = {};
    for (const q of result.queryStatements) {
      resolved[q.statementId] = q.defaultsAST ? (evaluate(q.defaultsAST, ctx) ?? null) : null;
    }
    for (const m of result.mutationStatements) resolved[m.statementId] = { status: "idle", data: null, error: null };
    refs = JSON.parse(JSON.stringify(resolved));
  }
  const errors: unknown[] = [];
  const evalCtx = { ctx, library: lib.library, store: null, errors };
  const evaluatedRoot = evaluateRoot
    ? evaluateRoot(result, evalCtx)
    : result.root
      ? evaluateElementProps(result.root, evalCtx)
      : null;
  const queries = result.queryStatements.map((q: any) => ({
    statementId: q.statementId,
    toolName: q.toolAST ? evaluate(q.toolAST, ctx) : "",
    args: q.argsAST ? evaluate(q.argsAST, ctx) : null,
    defaults: q.defaultsAST ? evaluate(q.defaultsAST, ctx) : null,
    refresh: q.refreshAST ? evaluate(q.refreshAST, ctx) : null,
  }));
  const fixture: Record<string, unknown> = {
    name: c.name,
    library: c.library,
    input: c.input,
    state: c.state ?? {},
    refs,
    evaluatedRoot,
    queries,
  };
  if (up.v1) fixture.runtimeErrors = errors;
  return fixture;
});

writeFileSync(args.out, JSON.stringify(out));
console.log(`${out.length} evaluator cases written to ${args.out}`);
