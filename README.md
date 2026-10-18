# vim-turmeric

Vim and Neovim support for [Turmeric](https://github.com/turmeric-lang/turmeric)
(`.tur`, `.tur.sweet`, and `#lang r7rs` files): syntax highlighting, filetype
detection, Lisp indentation settings, and the Turmeric dark and light
colorschemes.

## Install

```vim
" vim-plug
Plug 'turmeric-lang/vim-turmeric'
```

```lua
-- lazy.nvim
{ "turmeric-lang/vim-turmeric", ft = "turmeric" }
```

Or by hand: clone this repo into `~/.vim/pack/turmeric/start/` (Vim) or
`~/.local/share/nvim/site/pack/turmeric/start/` (Neovim).

Use a colorscheme with `:colorscheme turmeric-dark` or `turmeric-light`.

## Tests

`bash tests/run.sh` loads the pack into a real `vim` and checks the highlight
group at specific positions. CI also checks the colorschemes against the
shared palette published in the compiler repo (`web/editor-palette.json`).

The compiler guide is
[vim-guide.md](https://github.com/turmeric-lang/turmeric/blob/main/docs/guides/vim-guide.md).
