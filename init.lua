-- 0. CHECKS ===========================================================================================================

-- nvim 0.12 is required for `vim.pack`.
if vim.fn.has("nvim-0.12") == 0 then
  error("[ERROR] Requires nvim 0.12")
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


-- 2. PLUGIN INSTALLATION ==============================================================================================

-- vim.api.nvim_create_autocmd("PackChanged", {
--   callback = function(ev)
--     -- if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" then
--     -- if ev.data.spec.name == "nvim-treesitter" and vim.tbl_contains({"install", "update"}, ev.data.kind) then
--     -- if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" or ev.data.kind == "install" then
--         require("nvim-treesitter").update()
--     -- end
--   end,
-- })

vim.pack.add {
  -- appearance
  "https://github.com/rebelot/kanagawa.nvim",
  -- "https://github.com/echasnovski/mini.icons",

  -- navigation
  "https://github.com/stevearc/oil.nvim",
  -- "https://github.com/ibhagwan/fzf-lua",

  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/neovim/nvim-lspconfig", -- data only
}


-- 3. PLUGIN SETUP =====================================================================================================

-- 3.a. kanagawa.nvim (colorscheme) ------------------------------------------------------------------------------------

require "kanagawa" .setup {
  colors = {
    theme = {
      all = {
        ui = {
          bg_gutter = "none",
        },
      },
    },
  },

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
}

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Parent Dir" })


-- 3.c. nvim-treesitter (treesitter parser management) -----------------------------------------------------------------

local ts_parsers = {
  "c",
  "lua",
  "markdown",
  "markdown_inline",
  "query",
  "vim",
  "vimdoc",
}

require "nvim-treesitter" .install(ts_parsers)

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

-- LSP servers to enable
local lsp_servers = {
  "lua_ls",
}

-- TODO: maybe move to after/lsp or .nvim/lsp since this is nvim specific settings
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          -- TODO: include plugin directories
          vim.env.VIMRUNTIME,
        },
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

vim.lsp.enable(lsp_servers)
