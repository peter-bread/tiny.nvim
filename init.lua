-- 0. CHECKS ===========================================================================================================

if vim.fn.has "nvim-0.13" == 0 then
  error "requires nvim 0.13"
end


-- 1. OPTIONS ==========================================================================================================

-- Enable faster startup by caching compiled Lua modules
vim.loader.enable()

vim.g.mapleader       = " "
vim.g.maplocalleader  = "\\"

-- Fix markdown indentation settings.
-- See `:helpg markdown_recommended_style`.
-- See 'https://github.com/tpope/vim-markdown/commit/b78bbce3371a2eb56c89f618cd4ab2baadc9ee61'.
vim.g.markdown_recommended_style = 0

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
--
-- EDIT: Installation alone seems to work headlessly by default, but the build
-- commands do not. May need wrap some things with vim.async so we have the
-- option to do:
--
-- ```lua
-- require "tiny.pack" .setup(plugins):wait()
-- ```
--
-- EDIT:
--   HACK: We now have two options to customise plugin installation:
--   - `confirm = false` skips user confirmation
--   - `do_build = false` skips registering or executing build commands
--
--   We can use these for type-checking, where we just need plugins to be installed.
--   However, this is not enough for performing headless installs - we will still
--   need `vim.async` for that (probably).

---@type tiny.pack.Plugin[]
local plugins = {
  -- Colorscheme
  {
    src = "github:rebelot/kanagawa.nvim",
    config = function()
      -- Based on GitHub Colorblind Dark Mode Hex Tokens
      -- stylua: ignore
      local gh = {
        -- 1. Base 4 Colors
        add_bg        = "#15223a", -- Add line background
        add_inline_bg = "#234d87", -- Add word/inline background
        del_bg        = "#2c201b", -- Delete line background
        del_inline_bg = "#733d22", -- Delete word/inline background

        -- 2. GitHub Dark Mode Accents (for text/signs)
        add_fg = "#539bf5", -- GitHub blue text
        del_fg = "#e36049", -- GitHub orange/red text

        -- 3. Derived Cursor Line Backgrounds (halfway between line_bg and inline_bg)
        add_cursor_bg = "#1b2c4a",
        del_cursor_bg = "#382923",
      }

      -- local wave = require "kanagawa.colors" .setup { theme = "wave" }
      -- local theme = wave.theme
      -- local palette = wave.palette

      ---@diagnostic disable-next-line
      require "kanagawa" .setup {
        colors = {
          theme = {
            all = { ui = { bg_gutter = "none" } },
            wave = {
              -- diff filetype, *.diff / *.patch files
              -- e.g. hl groups: diffAdded, diffNewFile, @diff.plus
              vcs = {
                added   = gh.add_fg,
                removed = gh.del_fg,
              },
              -- vimdiff, and (presumably) other diff plugins
              -- e.g. hl groups: DiffAdd
              diff = {
                add    = gh.add_bg,
                delete = gh.del_bg,
                -- change = ...
                -- text   = ...
              },
            },
          },
        },

        ---@param colors KanagawaColors
        overrides = function(colors)
          local theme = colors.theme
          -- local palette = colors.palette

          -- We can also use
          -- require("kanagawa.lib.color")
          -- for advanced color mixing.

          local dark_popup_menus = {
            Pmenu       = {               bg = theme.ui.bg_p1 },
            PmenuSel    = { fg = "NONE",  bg = theme.ui.bg_p2 },
            PmenuSbar   = {               bg = theme.ui.bg_m1 },
            PmenuThumb  = {               bg = theme.ui.bg_p2 },
          }

          -- Neogit diff highlights.
          --
          -- For reference, these are the defaults:
          --  NeogitDiffAdditions            = { fg = palette.bg_green, ctermfg = 2 },
          --  NeogitDiffAdd                  = { bg = palette.line_green, fg = palette.bg_green, ctermfg = 2 },
          --  NeogitDiffAddHighlight         = { bg = palette.line_green, fg = palette.green, ctermfg = 2 },
          --  NeogitDiffAddCursor            = { bg = palette.bg1, fg = palette.green, ctermfg = 2 },
          --  NeogitDiffDeletions            = { fg = palette.bg_red, ctermfg = 1 },
          --  NeogitDiffDelete               = { bg = palette.line_red, fg = palette.bg_red, ctermfg = 1 },
          --  NeogitDiffDeleteHighlight      = { bg = palette.line_red, fg = palette.red, ctermfg = 1 },
          --  NeogitDiffDeleteCursor         = { bg = palette.bg1, fg = palette.red, ctermfg = 1 },
          --  NeogitDiffAddInline            = { bg = palette.inline_green, fg = palette.line_green, bold = palette.bold },
          --  NeogitDiffDeleteInline         = { bg = palette.inline_red, fg = palette.bg0, bold = palette.bold },
          local neogit_diff = {
            NeogitDiffAdd             = { bg = gh.add_bg },
            NeogitDiffAdditions       = { fg = gh.add_fg, bg = gh.add_bg },
            NeogitDiffAddHighlight    = { bg = gh.add_bg },
            NeogitDiffAddCursor       = { bg = gh.add_cursor_bg, bold = true },
            NeogitDiffAddInline       = { bg = gh.add_inline_bg, bold = true },

            NeogitDiffDelete          = { bg = gh.del_bg },
            NeogitDiffDeletions       = { fg = gh.del_fg, bg = gh.del_bg },
            NeogitDiffDeleteHighlight = { bg = gh.del_bg },
            NeogitDiffDeleteCursor    = { bg = gh.del_cursor_bg, bold = true },
            NeogitDiffDeleteInline    = { bg = gh.del_inline_bg, bold = true },
          }

          return vim.tbl_extend(
            "force",
            {},
            dark_popup_menus,
            neogit_diff
          )
        end,
      }

      vim.cmd.colorscheme "kanagawa"
    end,
  },

  -- Icons
  -- "github:echasnovski/mini.icons",

  -- File explorer
  "github:stevearc/oil.nvim",

  -- File finder
  {
    src = "github:dmtrKovalenko/fff",
    build = function() require "fff.download" .download_or_build_binary() end,
    config = function()
      local fff = require "fff"
      vim.keymap.set("n", "<leader>ff", fff.find_files, { desc = "Find Files" })
      vim.keymap.set("n", "<leader>fg", fff.live_grep, { desc = "Live Grep" })
    end,
  },
  -- "github:folke/snacks.nvim",
  -- "github:nvim-telescope/telescope.nvim",
  -- "github:ibhagwan/fzf-lua",

  -- Treesitter
  {
    src = "github:nvim-treesitter/nvim-treesitter",
    build = function() require "nvim-treesitter" .update "all" end
    -- build = ":TSUpdate",
  },

  -- Sane LSP configurations
  "github:neovim/nvim-lspconfig", -- data only
}

if vim.env.TINY_NVIM_CI == "1" then
  -- In CI, we may want to type-check the codebase. To do this, all plugins
  -- need to be installed and loaded, but they do not need to be configured.
  require "tiny.pack" .setup(plugins, { confirm = false, do_build = false })

  -- No additional configuration is required, so we can stop here.
  return
end

-- Setup plugins
require "tiny.pack" .setup(plugins, { do_config = true })


-- 3. PLUGIN SETUP =====================================================================================================

-- 3.b. oil.nvim (file explorer) ---------------------------------------------------------------------------------------

---@diagnostic disable-next-line
require "oil" .setup {
  columns = {
    "icon",
    "permissions",
    "size",
    "mtime",
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
