// Guards against drift between docs/contracts/streak_vectors.json and the inlined pgTAP
// vectors in supabase/tests/02_streak.test.sql (pgTAP cannot read repo files at runtime).
// Usage (repo root): deno run --allow-read supabase/scripts/check-streak-vectors.ts
type Vector = {
  name: string;
  start: string;
  duration: number | null;
  today: string;
  dates: string[];
  current: number;
  best: number;
  completed: number;
};

const root = new URL("../../", import.meta.url);
const { vectors } = JSON.parse(
  await Deno.readTextFile(new URL("docs/contracts/streak_vectors.json", root)),
) as { vectors: Vector[] };
const sql = await Deno.readTextFile(new URL("supabase/tests/02_streak.test.sql", root));

const expected = (v: Vector) => {
  const dates = v.dates.length === 0
    ? "'{}'::date[]"
    : `array[${v.dates.map((d) => `'${d}'`).join(",")}]::date[]`;
  return [
    `select results_eq(`,
    `  $$ select * from public.streak_from_dates(${dates}, '${v.start}', ${v.duration ?? "null"}, '${v.today}') $$,`,
    `  $$ values (${v.current}, ${v.best}, ${v.completed}) $$, 'vector: ${v.name}');`,
  ].join("\n");
};

const missing = vectors.filter((v) => !sql.includes(expected(v)));
const inlined = (sql.match(/'vector: /g) ?? []).length;
if (missing.length > 0 || inlined !== vectors.length) {
  for (const v of missing) console.error(`missing or different:\n${expected(v)}\n`);
  console.error(`json vectors: ${vectors.length}, inlined in SQL: ${inlined}`);
  Deno.exit(1);
}
console.log(`ok: ${vectors.length} streak vectors match 02_streak.test.sql`);
