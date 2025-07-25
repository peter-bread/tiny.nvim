-- OPTIONS =============================================================================================================

vim.o.number = true
vim.o.relativenumber = true

vim.o.autoindent      = true      -- copy indent from current line when starting a new line
vim.o.smartindent     = true      -- do smart autoindenting when starting a new line
vim.o.expandtab       = true      -- use spaces instead of tabs
vim.o.shiftwidth      = 2         -- size of indent
vim.o.tabstop         = 2         -- number of spaces tabs count for
vim.o.smarttab        = true      -- a <Tab> in front of a line inserts blanks according to 'shiftwidth'
vim.o.shiftround      = true      -- round indent

vim.o.splitright      = true      -- vertical splits open on the right
vim.o.splitbelow      = true      -- horizontal splits open below

vim.o.scrolloff       = 8

vim.o.cursorline      = true
vim.o.signcolumn      = "yes"
vim.o.statuscolumn    = "%=%{v:relnum == 0 ? v:lnum : v:relnum} %s"

-- PLUGIN INSTALLATION =================================================================================================

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
  "https://github.com/rebelot/kanagawa.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/oil.nvim",
}

-- PLUGIN SETUP ========================================================================================================

-- kanagawa.nvim (colorscheme) -----------------------------------------------------------------------------------------

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

-- oil.nvim (file explorer) --------------------------------------------------------------------------------------------

require "oil" .setup {}
vim.keymap.set("n", "-", "<cmd>Oil<cr>")

-- nvim-treesitter (treesitter parser management) ----------------------------------------------------------------------

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

vim.api.nvim_create_autocmd("FileType", { -- enable treesitter highlighting and indents
  callback = function(args)
    local filetype = args.match
    local lang = vim.treesitter.language.get_lang(filetype)
    if lang and vim.treesitter.language.add(lang) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.treesitter.start()
    end
  end
})

-- LSP =================================================================================================================

-- LSP servers to enable
local lsp_servers = {
  "lua_ls",
}

-- TODO: maybe move to after/lsp
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
