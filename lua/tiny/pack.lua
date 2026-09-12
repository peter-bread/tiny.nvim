---Extended plugin spec.
---@class tiny.pack.Spec : vim.pack.Spec
---
---Build command. This is executed after a plugin is installed or updated.
---
---It can in the form of:
--- - `fun()`: function that builds the plugin
--- - `":Command"`: a Neovim command
---
---Specifically, it runs on a `:h PackChanged` event.
---
---TODO: Pass some kind of context to the build function.
---TODO: Allow more forms, e.g. shell commands, `vim.system`, lists of commands,
---      etc.
---@field build? string|fun()

---Plugin.
---
---A `string` is equivalent to `{ src = "<string>" }`.
---@alias tiny.pack.Plugin string | tiny.pack.Spec

---@class tiny.pack
local M = {
  url = {}
}

local build_group = vim.api.nvim_create_augroup("tiny.pack.build", {})

---Set build commands for plugins. These are commands that should be run after
---a plugin is installed or updated.
---@param name string Plugin name.
---@param fn string|fun() Build command.
local function build(name, fn)
  vim.validate("name", name, "string")
  vim.validate("fn", fn, { "string", "function" })

  vim.api.nvim_create_autocmd("PackChanged", {
    group = build_group,
    desc = name,
    callback = function(ev)
      local kind = ev.data.kind
      if kind ~= "install" and kind ~= "update" then return end
      if name ~= ev.data.spec.name then return end

      -- Ensure plugin is loaded
      if not ev.data.active then vim.cmd.packadd(name) end

      if type(fn) == "function" then
        fn()
        return
      end

      if type(fn) == "string" then
        -- If it starts with a colon, treat it as a Neovim command
        if fn:sub(1, 1) == ":" then vim.cmd(fn:sub(2)) end
      end
    end
  })
end

---Install plugins.
---@param plugins tiny.pack.Plugin[]
function M.add(plugins)
  -- Prepare build commands before plugin installation
  for _, p in ipairs(plugins) do
    if type(p) == "table" and p.build ~= nil then
      -- TODO: Check vim.pack source code for more robust name resolution
      local name = p.name or p.src:match "/([^/]+)$"
      if not name then
        -- TODO: Log that name could not be determined
        goto continue
      end
      build(name, p.build)
    end
    ::continue::
  end

  -- TODO: Maybe explicitly remove `build` field from specs?
  -- For now this is not an issue as it is ignored.
  vim.pack.add(plugins)
end

---@param x string
function M.url.gh(x)
  return "https://github.com/" .. x
end

---@param x string
function M.url.gl(x)
  return "https://gitlab.com/" .. x
end

---@param x string
function M.url.cb(x)
  return "https://codeberg.org/" .. x
end

return M
