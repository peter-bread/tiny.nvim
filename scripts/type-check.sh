#!/usr/bin/env bash

set -euo pipefail

export NVIM_APPNAME=tiny.nvim

NVIM=${NVIM:-nvim}
generated=$(mktemp)
stderr=$(mktemp)

trap 'rm -f "$generated" "$stderr"' EXIT

"$NVIM" -l scripts/type-check.lua 2>"$stderr" | jq >"$generated"

cat "$stderr" >&2

{
  echo
  echo

  echo "--- generated.json ---"
  jq <"$generated"
  echo "--- end generated.json ---"
} &>2

emmylua_check . --config "$generated"
