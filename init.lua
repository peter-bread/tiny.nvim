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

vim.o.pumheight       = 15        -- max height of pop-up menus
vim.o.winborder       = "solid"   -- default border style of floating windows


vim.o.list            = true      -- show invisible characters (e.g. trailing spaces)

vim.o.exrc            = true

vim.o.wrap            = false


-- 1.1. MORE CONFIG ======================================================================================================
-- TODO: Work out a better place to put this.

require("vim._core.ui2").enable({})

vim.api.nvim_create_autocmd({ "TextYankPost", "TextPutPost"}, {
  desc = "Highlight on yank and put",
  group = vim.api.nvim_create_augroup("tiny.hl", {}),
  callback = function()
    vim.hl.hl_op {}
  end,
})


-- 2. PLUGIN INSTALLATION ==============================================================================================

-- TODO: Make sure sync and async plugin installation works.
-- Sync is requried for bootstrap/headless scripts.

-- Common URL shorteners
local url = require "tiny.pack" .url

---@type tiny.pack.Plugin[]
local plugins = {
  -- Appearance
  url.gh "rebelot/kanagawa.nvim",
  -- url.gh "echasnovski/mini.icons",

  -- Navigation
  url.gh "stevearc/oil.nvim",
  -- url.gh "ibhagwan/fzf-lua",

  {
    src = url.gh "nvim-treesitter/nvim-treesitter",
    version = "main",
    build = function()
      local ok, _ = pcall(function() require "nvim-treesitter" .update "all" end)
      if not ok then vim.notify "[ERROR] Failed to update nvim-treesitter parsers" end
    end
  },

  url.gh "neovim/nvim-lspconfig", -- data only
}

require "tiny.pack" .add(plugins)


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
