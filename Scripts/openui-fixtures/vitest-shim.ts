// Minimal stand-in for vitest so the upstream conformance runner can run under plain Node.
const tests: { name: string; fn: () => unknown }[] = [];
const after: (() => unknown)[] = [];
export function describe(_name: string, body: () => void) {
  body();
}
export function it(name: string, fn: () => unknown) {
  tests.push({ name, fn });
}
export function afterAll(fn: () => unknown) {
  after.push(fn);
}
export const expect = Object.assign(() => ({}), {
  fail(message: string): never {
    throw new Error(message);
  },
});
export async function runAll(): Promise<number> {
  let failed = 0;
  for (const t of tests) {
    try {
      await t.fn();
      console.log(`pass ${t.name}`);
    } catch (e) {
      failed++;
      console.log(`FAIL ${t.name}\n  ${e instanceof Error ? e.message : String(e)}`);
    }
  }
  for (const fn of after) await fn();
  console.log(`${tests.length - failed}/${tests.length} upstream conformance cases pass`);
  return failed;
}
