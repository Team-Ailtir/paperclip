import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const workflow = readFileSync(".github/workflows/ailtir-ci.yml", "utf8");

test("Ailtir CI covers the downstream and candidate branches", () => {
  assert.match(workflow, /push:\n\s+branches:\n\s+- ailtir\n\s+- "ailtir-candidate\/\*\*"/);
  assert.match(workflow, /pull_request:\n\s+branches:\n\s+- ailtir/);
});

test("Ailtir CI is read-only and cannot publish or deploy", () => {
  assert.match(workflow, /permissions:\n\s+contents: read/);
  assert.doesNotMatch(workflow, /packages:\s+write/);
  assert.doesNotMatch(workflow, /\baws-actions\//);
  assert.doesNotMatch(workflow, /\bdocker\/(?:login|build-push)-action/);
  assert.doesNotMatch(workflow, /\bpulumi\b/i);
  assert.doesNotMatch(workflow, /\bmake\s+(?:up|docker-push)\b/);
});

test("Ailtir CI runs the complete verification surface", () => {
  assert.match(workflow, /pnpm typecheck/);
  assert.match(workflow, /pnpm build/);
  assert.match(workflow, /pnpm test:run:general/);
  assert.match(workflow, /pnpm test:run:serialized/);
  assert.match(workflow, /PAPERCLIP_E2E_SKIP_LLM:\s+"true"/);
  assert.match(workflow, /name: Ailtir CI\n\s+if: \$\{\{ always\(\) \}\}/);
});
