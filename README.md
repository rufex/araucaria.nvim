# Araucaria

Araucaria is a Neovim plugin to navigate through RSpec files.

## Installation

Use your favorite plugin manager to install `Araucaria`. For example, with Lazy.vim:

```lua
  'rufex/araucaria.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim' -- Required by Telescope
  },
```

## How to use

Araucaria provides two commands:

- `:Araucaria` that opens a Telescope picker based on the current buffer, which should be a RSpec file.
- `:AraucariaAll` that opens a Telescope picker to select between all RSpec files in the project.

## Screenshots

### `:Araucaria`

![Araucaria](./assets/araucaria.png)

### `:AraucariaAll`

![AraucariaAll](./assets/araucaria_all.png)

## Roadmap

- [ ] Accept path as argument to `:Araucaria` command
- [ ] Add keymap to open picker `:Araucaria` when selecting a file in `:AracuariaAll`
- [ ] Add highlight groups to Telescope Picker in `:Araucaria`

## [Araucaria](https://en.m.wikipedia.org/wiki/Araucaria)

![Araucaria](https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Araucaria_araucana%2C_Zainuco%2C_Neuquen%2C_Argentina.jpg/1530px-Araucaria_araucana%2C_Zainuco%2C_Neuquen%2C_Argentina.jpg)

[Image by Dangelin5 - Own work, CC BY-SA 4.0](https://commons.wikimedia.org/w/index.php?curid=57620752)
