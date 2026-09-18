#!/usr/bin/env bash

set -euo pipefail

export NVIM_APPNAME=tiny.nvim

NVIM=${NVIM:-nvim}
generated=$(mktemp)

trap 'rm -f "$generated"' EXIT

"$NVIM" -l scripts/type-check.lua | jq >"$generated"

echo
echo "--- generated.json ---"
cat "$generated" | jq
echo "--- end generated.json ---"

emmylua_check . --config "$generated"
