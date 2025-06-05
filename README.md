Hyuga - A Hy Language Server
======================================

Forked from [hyuga](https://github.com/sakuraiyuta/hyuga). The intention was
to add `textDocument/documentSymbol` support so that I could list / jump to /
highlight functions and classes in my code. Since my hy skills are rather
limited, the result is rather hacky and probably not very performant. For this
reason, I did not intend to try and propose including these additions upstream.
So far it's working for me.

**This software is still in the experimental stage!**

## Features

- `textDocument/did{Open,Change}`
- `textDocument/completion`
- `textDocument/definition`
  - Jump to the definition. (Currently, this refers to hy-source only.)
- `textDocument/hover`
- `textDocument/documentSymbol`

## Install

### Global Install

```bash
pipx install git+https://github.com/maxkatzmann/hyuga.git
```

Also, ensure you installed `hy` the same way via `pipx`, not `pacman`/`yay`.

## Setup

### [Neovim](https://github.com/neovim/neovim) Lua Setup

Put the following somewhere in your nvim config

``` lua
-- Hy
vim.lsp.config.hy = {
  cmd = { 'hyuga' },
  filetypes = { 'hy' },
  root_markers = {
    'pyproject.toml',
    'uv.lock',
    '.git',
    vim.uv.cwd(),
  },
}
vim.lsp.enable 'hy'
```

## Development

### Setup

- Install [poetry](https://github.com/python-poetry/poetry).
- Clone this project: `git clone https://github.com/maxkatzmann/hyuga.git
- In project directory, execute `poetry install`.

### Run

If you want to run your local version, you can replace the global installation with

``` bash
pipx install --force /path/to/your/locally/checked-out/hyuga
```

### Test

```bash
poetry run pytest tests
```

## License

MIT
