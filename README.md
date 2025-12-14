# ogp-preview.nvim

Neovim plugin to preview GitHub repository OGP (Open Graph Protocol) images using Sixel graphics.

## Requirements

- Neovim with LuaJIT (for FFI support)
- Terminal with Sixel support (e.g., foot, wezterm, ghostty, mlterm, xterm with Sixel)
- [chafa](https://hpjansson.org/chafa/) - Terminal graphics converter
- `curl`

## Installation

### lazy.nvim

```lua
{
  "yutkat/ogp-preview.nvim",
  config = function()
    require("ogp-preview").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "yutkat/ogp-preview.nvim",
  config = function()
    require("ogp-preview").setup()
  end,
}
```

## Configuration

```lua
require("ogp-preview").setup({
  -- Image display size (in terminal cells)
  width = 40,
  height = 20,

  -- Cache settings
  cache_dir = vim.fn.stdpath("cache") .. "/ogp-preview",
  cache_ttl = 86400, -- 24 hours

  -- Sixel converter command
  converter = "chafa",

  -- Fallback terminal cell size in pixels (used if auto-detection fails)
  cell_size = { 10, 20 },
})
```

## Usage

### Commands

- `:OgpPreview` - Show OGP preview for GitHub repository URL under cursor
- `:OgpPreviewClose` - Close the preview window
- `:OgpPreviewEnable` - Enable automatic preview on cursor move
- `:OgpPreviewDisable` - Disable automatic preview

### Supported URL Formats

- `https://github.com/owner/repo`
- `github.com/owner/repo`
- `owner/repo` (lazy.nvim style plugin names)

URLs with additional paths (e.g., `/issues/123`, `/pull/456`, `/blob/main/file.lua`) are automatically normalized to the repository root.
