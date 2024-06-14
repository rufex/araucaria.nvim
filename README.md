# Araucaria

Araucaria is a Neovim plugin to navigate through RSpec files.

## Installation

Use your favorite plugin manager to install `Araucaria`. For example, with Lazy.vim:

```lua
  'rufex/araucaria.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-telescope/telescope.nvim',
  },
```

## How to use

Araucaria provides a command `:Araucaria` that opens a Telescope picker based on the current buffer, which should be a RSpec file.

## Roadmap

- [ ] Add highlight groups to Telescope Picker
- [ ] Accept path as argument to `:Araucaria` command
- [ ] New Telescope picker to select between all RSpec files

## [Araucaria](https://en.m.wikipedia.org/wiki/Araucaria)

![Araucaria](https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Araucaria_araucana%2C_Zainuco%2C_Neuquen%2C_Argentina.jpg/1530px-Araucaria_araucana%2C_Zainuco%2C_Neuquen%2C_Argentina.jpg)

[Image by Dangelin5 - Own work, CC BY-SA 4.0](https://commons.wikimedia.org/w/index.php?curid=57620752)
