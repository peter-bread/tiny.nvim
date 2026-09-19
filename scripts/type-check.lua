-- Generate emmylua_ls config file to type check config.
--
-- Prints JSON string to stdout.
--
-- Usage:
--
-- nvim -l scripts/type-check.lua
--
-- Parts of this are subject to change. For the type checking to work:
-- - all plugins need to be installed and loaded, but not configured/setup
-- - emmylua_ls needs to be setup with all runtime files loaded in workspace.library
-- - all other configuration, e.g. options, keymaps etc, do not need to be loaded
--
-- This means that at some point, parts of the config may be split into smaller files,
-- or gated by checks, e.g. `if (not) in_ci_mode then ... end`.

vim.cmd("source init.lua")

vim.lsp.config("emmylua_ls", {
  settings = {
    emmylua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})

---@diagnostic disable-next-line: need-check-nil
local config = vim.lsp.config["emmylua_ls"].settings.emmylua
local json = vim.json.encode(config)

io.stderr:flush()
io.stdout:write(json, "\n")
io.stdout:flush()
