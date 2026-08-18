#!/usr/bin/env bash
# Tarrock's one test command. Exit 0 means green.
#
#   bash godot/tests/run_all.sh
#
# Three stages, all of them blocking:
#
#   1. lint    - every .gd under the project loads. Static typing is enforced by
#                `debug/gdscript/warnings/untyped_declaration=2` in project.godot,
#                which turns an untyped var/parameter/return into a PARSE ERROR:
#                the script fails to load, so `--check-only --script <file>` exits
#                non-zero. That is the whole typing rule, enforced by the engine
#                rather than by review. The sweep exists because a script no test
#                loads (tools/, spike/) would otherwise rot untyped until someone
#                opened the game.
#   2. unit    - res://tests/runner.gd runs every res://tests/unit/**/*_test.gd.
#   3. scene   - the legacy scene tests, res://tests/*_test.gd, each in its own
#                process because each one boots a real scene and quits the tree.
#
# Two guards wrap every suite in stages 2 and 3:
#
#   * ENGINE ERRORS FAIL THE STAGE. A runtime script error (nonexistent method,
#     null dereference) does not stop GDScript: the engine prints
#     `SCRIPT ERROR: ...` and carries on, so a test could hit one, record no
#     assertion failure and be reported as a pass. Each stage is teed to a log and
#     any `ERROR:` / `SCRIPT ERROR:` / `USER ERROR:` line in it fails that stage,
#     exit code or not. Godot WARNINGs are left alone (the spike scenes emit some).
#     A green tree emits zero matching lines; if a legitimate one ever appears, fix
#     the cause or argue the exception here - do not widen the pattern quietly.
#   * TIMEOUTS FAIL THE STAGE. Every godot invocation runs under `timeout` (120s),
#     so a hung scene or a coroutine awaiting a signal that never fires reports a
#     FAIL instead of wedging the run. Without coreutils `timeout` the run warns
#     once and proceeds unbounded.
#
# Per-suite output is kept in full; nothing is swallowed. Works from any cwd.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
GODOT="${GODOT:-godot}"

if ! command -v "${GODOT}" >/dev/null 2>&1; then
	echo "run_all.sh: '${GODOT}' is not on PATH (set GODOT=/path/to/godot)" >&2
	exit 127
fi

# Seconds any single godot invocation may take before it is killed and failed.
SUITE_TIMEOUT_SECONDS=120

# Engine error lines. Anchored at column 0, which is where the engine prints them;
# a test that merely mentions the word in its own output is not matched.
ENGINE_ERROR_PATTERN='^(ERROR|SCRIPT ERROR|USER ERROR|USER SCRIPT ERROR):'

if command -v timeout >/dev/null 2>&1; then
	TIMED=(timeout "${SUITE_TIMEOUT_SECONDS}")
else
	echo "run_all.sh: WARNING - coreutils 'timeout' not found; suites run unbounded" >&2
	TIMED=()
fi

LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tarrock-tests.XXXXXX")"
trap 'rm -rf "${LOG_DIR}"' EXIT

passed=0
failed=0
failed_names=()

# Run one godot suite: tee its output to a log, then fail it on a non-zero exit,
# on a timeout, or on any engine error line in the log. Returns the suite's status.
run_suite() {
	local log="$1"
	shift
	"${TIMED[@]}" "$@" 2>&1 | tee "${log}"
	local status="${PIPESTATUS[0]}"
	if [[ "${status}" -eq 124 && "${#TIMED[@]}" -ne 0 ]]; then
		echo "--- TIMEOUT after ${SUITE_TIMEOUT_SECONDS}s"
		return 124
	fi
	if [[ "${status}" -ne 0 ]]; then
		return "${status}"
	fi
	local hits
	hits="$(grep -nE "${ENGINE_ERROR_PATTERN}" "${log}" || true)"
	if [[ -n "${hits}" ]]; then
		echo "--- engine error lines (a script error is a failure, not a pass):"
		echo "${hits}"
		return 1
	fi
	return 0
}

record() {
	local name="$1" status="$2"
	if [[ "${status}" -eq 0 ]]; then
		passed=$((passed + 1))
		echo "--- OK   ${name}"
	else
		failed=$((failed + 1))
		failed_names+=("${name}")
		echo "--- FAIL ${name} (exit ${status})"
	fi
}

echo "=== Tarrock test run: ${PROJECT_DIR}"

# Import first: the localization .translation and any new .tscn/.png must exist
# before a headless run can load them. Silent unless it fails.
import_log="$("${TIMED[@]}" "${GODOT}" --headless --path "${PROJECT_DIR}" --import 2>&1)"
if [[ $? -ne 0 ]]; then
	echo "${import_log}"
	echo "RUN_ALL: import failed"
	exit 1
fi

echo
echo "=== 1/3 lint: static typing (every .gd must load)"
lint_failures=0
while IFS= read -r script_path; do
	rel="${script_path#"${PROJECT_DIR}"/}"
	if ! out="$("${TIMED[@]}" "${GODOT}" --headless --path "${PROJECT_DIR}" --check-only --script "${rel}" 2>&1)"; then
		echo "${out}"
		lint_failures=$((lint_failures + 1))
	fi
done < <(find "${PROJECT_DIR}" -name '*.gd' -not -path '*/.godot/*' | sort)
if [[ "${lint_failures}" -eq 0 ]]; then
	record "lint (typing)" 0
else
	echo "${lint_failures} script(s) failed to load"
	record "lint (typing)" 1
fi

echo
echo "=== 2/3 unit tests (res://tests/unit)"
run_suite "${LOG_DIR}/unit.log" "${GODOT}" --headless --path "${PROJECT_DIR}" --script tests/runner.gd
record "unit tests" $?

echo
echo "=== 3/3 scene tests (res://tests/*_test.gd)"
while IFS= read -r test_path; do
	rel="${test_path#"${PROJECT_DIR}"/}"
	echo
	echo "--- ${rel}"
	run_suite "${LOG_DIR}/$(basename "${rel}").log" \
		"${GODOT}" --headless --path "${PROJECT_DIR}" --script "${rel}"
	record "${rel}" $?
done < <(find "${SCRIPT_DIR}" -maxdepth 1 -name '*_test.gd' | sort)

echo
if [[ "${failed}" -ne 0 ]]; then
	echo "failed suites: ${failed_names[*]}"
fi
echo "RUN_ALL: ${passed} suites passed, ${failed} failed"
[[ "${failed}" -eq 0 ]]
