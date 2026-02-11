# hover-after-moved

Hover over a file after moved/copied it to another folder.

> [!IMPORTANT]
> Minimum version: yazi v25.5.31.

## Requirements

- [yazi >= 25.5.31](https://github.com/sxyazi/yazi)

> [!NOTE]
> Yazi >= 25.9.15 (use `yazi --debug`) also supports copy/yank action.

## Installation

Install the plugin:

```sh
ya pkg add boydaihungst/hover-after-moved
```

### Add setup function in `yazi/init.lua`.

```lua
require("hover-after-moved"):setup()
```
