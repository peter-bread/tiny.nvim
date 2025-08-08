# Notes

Notes for 0.12.

## `vim.pack`

### Bootstrapping `lazy.nvim`

`vim.pack` makes bootstrapping `lazy.nvim` much simpler:

```lua
vim.pack.add({ "https://github.com/folke/lazy.nvim" })
require("lazy").setup()
```
