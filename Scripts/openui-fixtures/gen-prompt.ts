// System prompt goldens (prompt-goldens.json) from the upstream generateSystemPrompt.
// Usage: node --experimental-transform-types --no-warnings --import ./register.mjs gen-prompt.ts \
//          --clone <openui-clone> --out <prompt-goldens.json>
import { writeFileSync } from "node:fs";
import { librarySpecs, loadUpstream, parseArgs } from "./common.ts";

const args = parseArgs(["clone", "out"]);
const up = await loadUpstream(args.clone);
const { generateSystemPrompt } = up.prompt;
const { openuiChatPromptOptions, openuiPromptOptions } = up.promptOptions;
const specs = librarySpecs(args.clone);
const libraries: Record<string, any> = { chat: specs.chat, standard: specs.playground, spec: specs.spec };

const tools = [
  "list_hotels",
  {
    name: "search_hotels",
    description: "Search hotels in a city",
    inputSchema: {
      type: "object",
      properties: { city: { type: "string" }, maxPrice: { type: "number" }, sort: { type: "string", enum: ["price", "rating"] } },
      required: ["city"],
    },
    outputSchema: {
      type: "object",
      properties: {
        hotels: { type: "array", items: { type: "object", properties: { name: { type: "string" }, price: { type: "number" }, pool: { type: "boolean" } }, required: ["name"] } },
        total: { type: "integer" },
      },
    },
  },
  { name: "ping", inputSchema: {}, outputSchema: {} },
];

const cases: { name: string; library: string; options: any }[] = [
  { name: "chat-default", library: "chat", options: openuiChatPromptOptions },
  { name: "standard-default", library: "standard", options: openuiPromptOptions },
  { name: "chat-bare", library: "chat", options: {} },
  {
    name: "chat-tools-edit-inline",
    library: "chat",
    options: { ...openuiChatPromptOptions, tools, editMode: true, inlineMode: true, preamble: "You are Wanderlust, a travel assistant.", toolExamples: ["Example — tool:\n\nroot = Card([t])\nt = TextContent(\"x\")"] },
  },
  { name: "standard-bindings-only", library: "standard", options: { bindings: true, additionalRules: ["Be concise."] } },
  { name: "standard-toolcalls-no-bindings", library: "standard", options: { tools: ["a", "b"], bindings: false } },
];

if (up.v1) {
  cases.push(
    // builtinFunctions: lists @Count, @Sum, ... without toolCalls/bindings, or hides them with both on.
    { name: "v1-chat-builtin-functions", library: "chat", options: { builtinFunctions: true } },
    { name: "v1-chat-tools-no-builtin-functions", library: "chat", options: { ...openuiChatPromptOptions, tools, builtinFunctions: false } },
    { name: "v1-standard-bindings-no-builtin-functions", library: "standard", options: { bindings: true, builtinFunctions: false } },
    // The spec library (spec/fixtures/1.0/library.json): one function (@Upper), one action (@CopyToClipboard).
    { name: "v1-spec-default", library: "spec", options: {} },
    { name: "v1-spec-bindings", library: "spec", options: { bindings: true } },
    { name: "v1-spec-tools", library: "spec", options: { tools, preamble: "You build small dashboards." } },
    { name: "v1-spec-tools-no-builtin-functions", library: "spec", options: { tools: ["a", "b"], builtinFunctions: false } },
    { name: "v1-spec-builtin-functions-only", library: "spec", options: { builtinFunctions: true, bindings: false } },
  );
}

const out = cases.map((c) => {
  const library = libraries[c.library];
  return { name: c.name, library: c.library, options: c.options, prompt: generateSystemPrompt({ library, promptOptions: c.options }) };
});
writeFileSync(args.out, JSON.stringify(out, null, 1));
console.log(`${out.length} prompt goldens written to ${args.out}; chat-default length ${out[0].prompt.length}`);
