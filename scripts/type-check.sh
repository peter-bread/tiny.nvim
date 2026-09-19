#!/usr/bin/env bash

set -euo pipefail

export NVIM_APPNAME=tiny.nvim

NVIM=${NVIM:-nvim}
generated=$(mktemp)
stderr=$(mktemp)

trap 'rm -f "$generated" "$stderr"' EXIT

"$NVIM" -l scripts/type-check.lua 2>"$stderr" | jq >"$generated"

cat "$stderr"

echo
echo

echo "--- generated.json ---"
jq <"$generated"
echo "--- end generated.json ---"

echo

# if [[ ${CI:-} == "true" ]]; then
if [[ ${GITHUB_ACTIONS:-} == "true" ]]; then
  emmylua_check . --config "$generated" --output-format github
else
  emmylua_check . --config "$generated"
fi
