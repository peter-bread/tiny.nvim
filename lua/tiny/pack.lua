--- Extended plugin spec.
---@class tiny.pack.Spec : vim.pack.Spec
---
--- Build command. This is executed after a plugin is installed or updated.
---
--- It can in the form of:
---  - `fun()`: function that builds the plugin
---  - `":Command"`: a Neovim command
---
--- Specifically, it runs on a `:h PackChanged` event.
---
--- TODO: Pass some kind of context to the build function.
--- TODO: Allow more forms, e.g. shell commands, `vim.system`, lists of commands,
---       etc.
---@field build? tiny.pack.BuildCommand
---
--- Config function to run after plugins are installed.
--- TODO: Pass in some kind of context, `opts` field or similar if that gets
---       implemented
---@field config? fun()

--- Plugin.
---
--- A `string` is equivalent to `{ src = "<string>" }`.
---@alias tiny.pack.Plugin string | tiny.pack.Spec

--- Build command.
---@alias tiny.pack.BuildCommand string | fun()

---@class tiny.pack
local M = {}

local build_group = vim.api.nvim_create_augroup("tiny.pack.build", {})

--- Set build commands for plugins. These are commands that should be run after
--- a plugin is installed or updated.
---@param name string Plugin name.
---@param build tiny.pack.BuildCommand Build command.
local function register_build_command(name, build)
  -- TODO: Should we specify non-empty string?
  vim.validate("name", name, "string")
  -- TODO: Can we validate that the string starts with a colon here?
  vim.validate("fn", build, { "string", "function" })

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

      if type(build) == "function" then
        build()
        return
      end

      if type(build) == "string" then
        -- If it starts with a colon, treat it as a Neovim command
        if build:sub(1, 1) == ":" then
          vim.cmd(build:sub(2))
        end
        return
      end
    end,
  })
end

--- Normalize plugins to spec tables.
---
--- If a `plugin` is a `tiny.pack.Spec`, it will stay the same.
--- If a `plugin` is a `string`, it will be converted into a `tiny.pack.Spec`.
---
--- ```lua
--- plugin_to_spec("some-plugin")
---  -- {  src = "some-plugin" }
---
--- plugin_to_spec({ src = "some-plugin" })
---  -- {  src = "some-plugin" }
--- ```
---@param plugin tiny.pack.Plugin
---@return tiny.pack.Spec
local function plugin_to_spec(plugin)
  if type(plugin) == "table" then return plugin end
  return { src = plugin }
end

--- Extract name from a plugin spec.
---
--- This should be kept in-sync with the logic used inside `vim.pack` itself.
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

--- Register build commands.
---@param specs tiny.pack.Spec[]
local function register_build_commands(specs)
  vim.iter(specs)
    :filter(function(spec) return spec.build end)
    :map(function(spec) return extract_name_from_spec(spec), spec.build end)
    :each(register_build_command)
end

--- Install plugins.
---@param specs tiny.pack.Spec[]
---@private
function M.add(specs)
  register_build_commands(specs)

  -- TODO: Maybe explicitly remove `build` field from specs?
  -- For now this is not an issue as it is ignored.
  vim.pack.add(specs)
end

--- Run `config` functions.
---@param specs tiny.pack.Spec[]
---@private
function M.config(specs)
  ---@diagnostic disable-next-line: access-invisible I think emmylua is getting confused.
  vim.iter(specs):each(function(spec)
    if spec.config and type(spec.config) == "function" then
      spec.config()
    end
  end)
end

-- TODO: Should `add` and `config` still be exposed even though they only accept
-- tiny.pack.Spec and not tiny.pack.Plugin.

---@param name string
---@param host_prefixes table<string, string>
---@see https://github.com/neovim/neovim/discussions/37064
local function expand_host(name, host_prefixes)
  for short, long in pairs(host_prefixes) do
    if vim.startswith(name, short .. ':') then
      return (name:gsub('^' .. short .. ':', long))
    end
  end
  return name
end

---@param spec tiny.pack.Spec
---@param host_prefixes table<string, string>
---@return tiny.pack.Spec
---@see https://github.com/neovim/neovim/discussions/37064
local function expand_prefix(spec, host_prefixes)
  spec.src = expand_host(spec.src, host_prefixes)
  return spec
end


--- User-facing options to override default configuration.
---@class (exact) tiny.pack.Opts
---
--- (default: `false`) Whether to run `config` functions if they exist.
---@field do_config? boolean
---
--- Mapping of short host prefixes to full host expansions.
---@field host_prefixes? table<string, string>

--- Fully resolved configuration.
---@class (exact) tiny.pack.Config
local DEFAULT_CONFIG = {
  ---@type boolean (default: `false`) Whether to run `config` functions if they exist.
  do_config = false,
  ---@type table<string, string> Mapping of short host prefixes to full host expansions.
  host_prefixes = {
    github = "https://github.com/",
    gitlab = "https://gitlab.com/",
    codeberg = "https://codeberg.org/",
  }
}

--- Merge user config with default config.
---@param opts? tiny.pack.Opts
---@return tiny.pack.Config
local function resolve_config(opts)
  vim.validate("opts", opts, "table", true)
  return vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
end

---@param plugins tiny.pack.Plugin[]
---@param config tiny.pack.Config
---@return tiny.pack.Spec[]
local function resolve_specs(plugins, config)
  vim.validate("plugins", plugins, vim.islist)
  vim.validate("config", config, "table")

  return vim.iter(plugins)
    :map(plugin_to_spec)
    :map(function(spec) return expand_prefix(spec, config.host_prefixes) end)
    :totable()
end

--- Setup all plugins.
---@param plugins tiny.pack.Plugin[] List of plugins.
---@param opts? tiny.pack.Opts Optional user configuration.
function M.setup(plugins, opts)
  vim.validate("plugins", plugins, vim.islist)
  vim.validate("opts", opts, "table", true)

  local config = resolve_config(opts)
  local specs = resolve_specs(plugins, config)

  M.add(specs)

  if config.do_config then
    M.config(specs)
  end
end

return M
