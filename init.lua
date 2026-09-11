-- 0. CHECKS ===========================================================================================================

-- nvim 0.12 is required for `vim.pack`.
if vim.fn.has "nvim-0.12" == 0 then
  error "[ERROR] Requires nvim 0.12"
end


-- 1. OPTIONS ==========================================================================================================

vim.g.mapleader       = " "
vim.g.maplocalleader  = "\\"

vim.o.number          = true
vim.o.relativenumber  = true

vim.o.autoindent      = true      -- copy indent from current line when starting a new line
vim.o.smartindent     = true      -- do smart autoindenting when starting a new line
vim.o.expandtab       = true      -- use spaces instead of tabs
vim.o.shiftwidth      = 2         -- size of indent
vim.o.tabstop         = 2         -- number of spaces tabs count for
vim.o.smarttab        = true      -- a <Tab> in front of a line inserts blanks according to 'shiftwidth'
vim.o.shiftround      = true      -- round indent

vim.o.ignorecase      = true      -- ignore case while searching
vim.o.smartcase       = true      -- override the 'ignorecase' option if the search pattern contains uppercase characters
vim.o.hlsearch        = true      -- highlight search matches
vim.o.incsearch       = true      -- highlight search matches while typing search command

vim.o.splitright      = true      -- vertical splits open on the right
vim.o.splitbelow      = true      -- horizontal splits open below

vim.o.scrolloff       = 8

vim.o.cursorline      = true
vim.o.signcolumn      = "yes"
vim.o.statuscolumn    = "%=%{v:relnum == 0 ? v:lnum : v:relnum} %s"


vim.o.list            = true      -- show invisible characters (e.g. trailing spaces)

vim.o.exrc            = true

vim.o.wrap            = false


-- 2. PLUGIN INSTALLATION ==============================================================================================

-- TODO: Make sure sync and async plugin installation works.
-- Sync is requried for bootstrap/headless scripts.

local build_group = vim.api.nvim_create_augroup("tiny.pack.build", {})

---Set build commands for plugins. These are commands that should be run after a plugin is installed or updated.
---@param name string Plugin name.
---@param fn fun() Build command.
local function build(name, fn)
  vim.api.nvim_create_autocmd("PackChanged", {
    once = true,
    group = build_group,
    desc = name,
    callback = function(ev)
      local kind = ev.data.kind
      -- Delete autocmd on wrong event kind
      if kind ~= "install" and kind ~= "update" then return true end
      -- Keep autocmd if we have the wrong name -- it might run on a later plugin
      if name ~= ev.data.spec.name then return false end

      -- Ensure plugin is loaded.
      if not ev.data.active then
        vim.cmd.packadd(name)
      end

      fn()

      -- Delete autocmd when done.
      return true
    end
  })
end

---Extended plugin spec.
---@class TinyPluginSpec : vim.pack.Spec
---@field build fun() Build command.

-- Common URL shorteners
local gh = function(x) return "https://github.com/" .. x end
local gl = function(x) return "https://gitlab.com/" .. x end
local cb = function(x) return "https://codeberg.org/" .. x end

---@type (string|TinyPluginSpec)[]
local plugins = {
  -- appearance
  gh "rebelot/kanagawa.nvim",
  -- "https://github.com/echasnovski/mini.icons",

  -- navigation
  gh "stevearc/oil.nvim",
  -- "https://github.com/ibhagwan/fzf-lua",

  {
    src = gh "nvim-treesitter/nvim-treesitter",
    version = "main",
    build = function()
      local ok, _ = pcall(function() require "nvim-treesitter" .update "all" end)
      if not ok then vim.notify "[ERROR] Failed to update nvim-treesitter parsers" end
    end
  },

  gh "neovim/nvim-lspconfig", -- data only
}

-- Prepare build commands before plugin installation
for _, p in ipairs(plugins) do
  if p.build then
    -- TODO: nil check?
    local name = p.name or p.src:match "/([^/]+)$"
    build(name, p.build)
  end
end

-- TODO: Maybe explicitly remove `build` field from specs?
-- For now this is not an issue as it is ignored.
vim.pack.add(plugins)

-- -- After plugin stuff is done, if there are any autocmds that haven't been run, log it and then clear the group.
-- -- This may not be desired, as you may update a plugin later in a session?? Need to investigate this.
--
-- -- Get desc/name of build autocmds that did not run.
-- local autocmds = vim.iter(vim.api.nvim_get_autocmds({ group = build_group }))
--   :map(function(a) return a.desc or "unknown" end)
--   :totable()
--
-- -- Pritn autocmds that did not run
-- vim.print(autocmds)
--
-- -- Delete autocmds that did not run
-- vim.api.nvim_del_augroup_by_id(build_group)

-- 3. PLUGIN SETUP =====================================================================================================

-- 3.a. kanagawa.nvim (colorscheme) ------------------------------------------------------------------------------------

---@diagnostic disable-next-line
require "kanagawa" .setup {
  colors = { theme = { all = { ui = { bg_gutter = "none" } } } },

  ---@param colors KanagawaColors
  overrides = function(colors)
    local theme = colors.theme

    return {
      -- dark popup menus
      Pmenu = { bg = theme.ui.bg_p1 },
      PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
      PmenuSbar = { bg = theme.ui.bg_m1 },
      PmenuThumb = { bg = theme.ui.bg_p2 },
    }
  end,
}

vim.cmd.colorscheme "kanagawa"


-- 3.b. oil.nvim (file explorer) ---------------------------------------------------------------------------------------

---@diagnostic disable-next-line
require "oil" .setup {
  columns = {
    "icon",
    "permissions",
    "size",
    "mtime",
  },
  view_options = {
    show_hidden = true,
  },
  -- Skip the confirmation popup for simple operations (:h oil.skip_confirm_for_simple_edits)
  skip_confirm_for_simple_edits = true,
  float = {
    border = "solid",
    max_width = 0.8,
    max_height = 0.6,
  },
}

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Oil" })
-- vim.keymap.set("n", "-", require "oil" .open_float, { desc = "Oil (Float)" })


-- 3.c. nvim-treesitter (treesitter parser management) -----------------------------------------------------------------

require "nvim-treesitter" .install {
  "c",
  "lua",
  "markdown",
  "markdown_inline",
  "query",
  "vim",
  "vimdoc",
}

vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable treesitter highlighting and indents",
  callback = function(args)
    local filetype = args.match
    local lang = vim.treesitter.language.get_lang(filetype)
    if lang and vim.treesitter.language.add(lang) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.treesitter.start()
    end
  end
})


-- 4. LSP ==============================================================================================================

-- If there is a config file, use that. Otherwise, assume neovim config.
-- TODO: Perhaps add a mechanism to opt-in to the Neovim config, e.g. an
-- environment variable, file marker etc. Then in cases where there is no
-- config file and no opt-in, nothing will be used.
vim.lsp.config("emmylua_ls", {
  on_init = function(client)
    -- If the workspace has its own emmylua_ls/lua_ls config file, defer to it.
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.emmyrc.json")
        or vim.uv.fs_stat(path .. "/.luarc.json"))
      then
        client.config.settings = {}
      end
    end
  end,
  settings = {
    emmylua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      -- Make the server aware of Neovim runtime files.
      workspace = {
        -- library = {
        --   vim.env.VIMRUNTIME,
        -- },
        -- Or pull in all of 'runtimepath'. May be slower!
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})

vim.lsp.enable { "emmylua_ls" }


-- 5. KEYMAPS ==========================================================================================================

-- TODO: The default <C-l> is useful, especially now we have multicursor.
-- Need to come up with a new keymap for that type of thing.
-- See `:h CTRL-L-default`.

-- 5.a. General --------------------------------------------------------------------------------------------------------

vim.keymap.set({ "n", "i", "s" }, "<esc>", function()
  vim.snippet.stop()  -- exit current snippet (native snippets only)
  vim.cmd "noh"       -- clear search highlighting
  return "<esc>"      -- standard esc behaviour
end, { expr = true, desc = "Escape+" }) -- expr to make sure "<esc>" is actually evaluated

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Write" })
vim.keymap.set("n", "<leader>x", "<cmd>x<cr>", { desc = "Write & Quit" })


-- 5.b. Navigate Splits ------------------------------------------------------------------------------------------------

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus left pane" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus lower pane" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus upper pane" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus right pane" })

-- 5.c. Open Splits ----------------------------------------------------------------------------------------------------

vim.keymap.set("n", "<leader>-", "<C-w>s", { desc = "Split below" })
vim.keymap.set("n", "<leader>|", "<C-w>v", { desc = "Split right" })
