# Notes

Notes for 0.12.

## `tiny.pack` and `vim.pack`

`tiny.pack` is small wrapper around `vim.pack`. The main problem it solves is
allowing plugin build commands to be defined as part of the plugin spec. It
does this by defining an autocommand for each build command that runs whenever
a plugin is installed or updated (see `:h PackChanged`). These autocmds need to
be created before `vim.pack.add` is called. See `:h vim.pack-events` for an
example. This custom interface abstracts that away.

### Just for installation

This is essentially a drop-in replacement for vanilla `vim.pack`.

```lua
---@type tiny.pack.Plugin[]
local plugins = {
  "github:stevearc/oil.nvim",

  {
    src = "github:dmtrKovalenko/fff",
    build = function() require "fff.download" .download_or_build_binary() end
  },
}

-- Install plugins
require "tiny.pack" .setup(plugins)

-- ...
-- ...
-- ...

-- Configure plugins separately:
-- Some plugin use a setup function...
require "oil" .setup {
  columns = {
    "icon",
    "permissions",
    "size",
    "mtime",
  },
}

-- ...others read from a global variable
vim.g.fff = {
  lazy_sync = true,
  -- ...
}
```

### Include plugin config in spec

> [!WARNING]
> This is experimental and subject to bugs and changes.

```lua
---@type tiny.pack.Plugin[]
local plugins = {
  {
    src = "github:stevearc/oil.nvim",
    config = function()
      require "oil" .setup {
        columns = {
          "icon",
          "permissions",
          "size",
          "mtime",
        },
      }
    end
  }

  {
    src = "github:dmtrKovalenko/fff",
    build = function() require "fff.download" .download_or_build_binary() end
    config = function()
      vim.g.fff = {
        lazy_sync = true,
      }
    end
  },
}

-- Install plugins and configure plugins
require "tiny.pack" .setup(plugins, { do_config = true })
```
