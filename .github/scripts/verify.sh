#!/usr/bin/env bash
#
# Post-implementation checks: typecheck, lint, tests, build.
# Each check is optional and only runs if the project supports it, so this stays
# correct as the repo grows (e.g. once a "test" script or ESLint config exists).
#
# Reads (env):
#   VERIFY_REPORT        - path to write the markdown report (default: verify-report.md)
#   GITHUB_OUTPUT        - if set, writes passed=true|false
#   GITHUB_STEP_SUMMARY  - if set, appends the report to the job summary
#
# Exit code: 0 if every check that ran passed, 1 otherwise.

# Intentionally NOT using `set -e`: we want every check to run even if an
# earlier one fails, then report the aggregate result.
set -uo pipefail

REPORT="${VERIFY_REPORT:-verify-report.md}"
FAILED=0

{
  echo "## Verification"
  echo ""
} > "$REPORT"

has_script() {
  node -e "process.exit((require('./package.json').scripts||{})['$1'] ? 0 : 1)" 2>/dev/null
}

have_eslint_config() {
  ls eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts \
     .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.json .eslintrc.yml .eslintrc.yaml \
     >/dev/null 2>&1
}

run_check() {
  local name="$1"; shift
  echo "::group::$name ($*)"
  local out status
  out=$("$@" 2>&1); status=$?
  echo "$out"
  echo "::endgroup::"

  if [ "$status" -eq 0 ]; then
    echo "- ✅ **$name** — passed" >> "$REPORT"
  else
    FAILED=1
    {
      echo "- ❌ **$name** — failed (exit $status)"
      echo ""
      echo "<details><summary>Last lines of $name output</summary>"
      echo ""
      echo '```'
      printf '%s\n' "$out" | tail -n 50
      echo '```'
      echo ""
      echo "</details>"
    } >> "$REPORT"
  fi
}

skip_check() {
  echo "- ⏭️ **$1** — skipped ($2)" >> "$REPORT"
}

# --- Typecheck (always available; tsconfig is present) ---
run_check "Typecheck" pnpm exec tsc --noEmit

# --- Lint (only with an ESLint config; run without --fix so it's a real check) ---
if have_eslint_config; then
  run_check "Lint" pnpm exec eslint .
else
  skip_check "Lint" "no ESLint config found"
fi

# --- Tests ---
if has_script test; then
  run_check "Tests" pnpm run test
else
  skip_check "Tests" 'no "test" script in package.json'
fi

# --- Build ---
if has_script build; then
  run_check "Build" pnpm run build
else
  skip_check "Build" 'no "build" script in package.json'
fi

{
  echo ""
  if [ "$FAILED" -eq 0 ]; then
    echo "**Result: ✅ all checks passed**"
  else
    echo "**Result: ❌ one or more checks failed**"
  fi
} >> "$REPORT"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  if [ "$FAILED" -eq 0 ]; then
    echo "passed=true" >> "$GITHUB_OUTPUT"
  else
    echo "passed=false" >> "$GITHUB_OUTPUT"
  fi
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$REPORT" >> "$GITHUB_STEP_SUMMARY"
fi

exit "$FAILED"
