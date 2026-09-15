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
---
---Config function to run after plugins are installed.
---TODO: Pass in some kind of context, `opts` field or similar if that gets
---      implemented
---@field config? fun()

---Plugin.
---
---A `string` is equivalent to `{ src = "<string>" }`.
---@alias tiny.pack.Plugin string | tiny.pack.Spec

---@class tiny.pack
local M = {
  -- TODO: Perhaps use https://github.com/neovim/neovim/discussions/37064.
  -- If so, are the url functions are still needed?
  url = {},
}

local build_group = vim.api.nvim_create_augroup("tiny.pack.build", {})

---Set build commands for plugins. These are commands that should be run after
---a plugin is installed or updated.
---@param name string Plugin name.
---@param fn string|fun() Build command.
local function register_build_command(name, fn)
  vim.validate("name", name, "string")
  -- TODO: Can we validate that the string starts with a colon here?
  vim.validate("fn", fn, { "string", "function" })

  vim.api.nvim_create_autocmd("PackChanged", {
    group = build_group,
    desc = name,
    callback = function(ev)
      local kind = ev.data.kind
      if kind ~= "install" and kind ~= "update" then return end
      if name ~= ev.data.spec.name then return end

      -- Ensure plugin is loaded
      if not ev.data.active then
        vim.cmd.packadd(name)
      end

      if type(fn) == "function" then
        fn()
        return
      end

      if type(fn) == "string" then
        -- If it starts with a colon, treat it as a Neovim command
        if fn:sub(1, 1) == ":" then
          vim.cmd(fn:sub(2))
        end
        return
      end
    end,
  })
end

---Convert `"some-plugin"` to `{ src = "some-plugin" }`.
---@param plugin tiny.pack.Plugin
---@return tiny.pack.Spec
local function plugin_to_spec(plugin)
  if type(plugin) == "table" then return plugin end
  return { src = plugin }
end

--- Normalize plugins into table form.
---
--- ```lua
--- { "some-plugin", { src = "other-plugin" } }
--- -- becomes
--- { { src = "some-plugin" }, { src = "other-plugin" } }
--- ```
---@param plugins tiny.pack.Plugin[]
---@return tiny.pack.Spec[]
---@see tiny.pack.Plugin
---@see tiny.pack.Spec
local function plugins_to_specs(plugins)
  return vim.iter(plugins):map(plugin_to_spec):totable()
end

---Extract name from a plugin spec.
---
---This should be kept in-sync with the logic used inside `vim.pack` itself.
---@param spec tiny.pack.Spec
---@see vim.pack.Spec
local function extract_name_from_spec(spec)
  -- TODO: Replace ' with "
  -- From neovim source code:
  -- runtime/lua/vim/pack.lua normalize_spec
  local name = spec.name or spec.src:gsub('%.git$', '')
  name = (type(name) == 'string' and name or ''):match('[^/]+$') or ''
  vim.validate("name", name, function(s) return type(s) == "string" and s ~= "" end, false, "non-empty string")
  return name
end

---Register build commands.
---@param specs tiny.pack.Spec[]
local function register_build_commands(specs)
  vim.iter(specs)
    :filter(function(spec) return spec.build end)
    :map(function(spec) return extract_name_from_spec(spec), spec.build end)
    :each(register_build_command)
end

---Install plugins.
---@param specs tiny.pack.Spec[]
---@private
function M.add(specs)
  register_build_commands(specs)

  -- TODO: Maybe explicitly remove `build` field from specs?
  -- For now this is not an issue as it is ignored.
  vim.pack.add(specs)
end

---Run `config` functions.
---@param specs tiny.pack.Spec[]
---@private
function M.config(specs)
  vim.iter(specs):each(function(spec)
    if spec.config and type(spec.config) == "function" then
      spec.config()
    end
  end)
end

-- TODO: Should `add` and `config` still be exposed even though they only accept
-- tiny.pack.Spec and not tiny.pack.Plugin.

---Setup all plugins.
---@param plugins tiny.pack.Plugin[] List of plugins.
---@param opts? tiny.pack.Opts Config.
function M.setup(plugins, opts)
  vim.validate("plugins", plugins, vim.islist)

  opts = resolve_config(opts)
  local specs = plugins_to_specs(plugins)

  M.add(specs)

  if opts.do_config then
    M.config(specs)
  end
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



---@class tiny.pack.Opts
---Run `config` functions if they exist.
---@field do_config bool

---@type tiny.pack.Opts
local DEFAULT_CONFIG = {
  do_config = false
}

---@param opts? tiny.pack.Opts
---@return tiny.pack.Opts
function resolve_config(opts)
  vim.validate("opts", opts, "table")
  return vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
end

return M
