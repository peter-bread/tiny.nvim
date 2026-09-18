#!/usr/bin/env bash

export NVIM_APPNAME=tiny.nvim

NVIM=${NVIM:-nvim}

"$NVIM" -l scripts/type-check.lua 2>&1 | jq >generated.json

emmylua_check . --config generated.json

rm generated.json
