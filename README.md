## What is this?

This is not meant to be a replacement for `rust-tools.nvim`. It does *not* offer all of the capabilities that `rust-tools.nvim` offers nor will it ever do so. 

Instead it simply provides inlay hints in the style of `coc.nvim` for users relying on `rust-analyzer`.

## Why not just use `rust-tools.nvim`?

If you are trying to turn neovim into an IDE-like environment then this plugin is not for you. I happen to fall in the camp of those who prefer to use neovim as a *text-editor*.

Inlay hints were the only thing I needed from the set of features offered by `rust-tools.nvim` hence this plugin provides *exactly* that.

## Usage

Using `lazy.nvim` in your config file, you simply call `setup`:

```lua
require("lazy").setup {
    "snom3ad/ra.nvim",
    config = function()
        require("ra_nvim").setup()
    end,
}
```

### Further Notes

This plugin is a temporary solution while [native support](https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/inlay_hint.lua) for inlay-hints get stabilized in neovim. Contains no dependency to `lspconfig` or any other third party package and _also_ has crazy fast startup time:


![Startup Time Comparison](https://pasteboard.co/gDo7sXobBN5D.png)


Also I have seen a movement lately to get rid of the `setup` function. The premise of the argument is very convincing, however, I will defer this decision until a consensus has been been reached by the community at large on what is the best way to separate plugin initialization vs configuration.
