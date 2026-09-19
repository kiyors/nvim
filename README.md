# Neovim Setup & Features Guide

A fast, modern Neovim configuration built with lazy.nvim, Tree-sitter, blink-cmp, and advanced Git/Diff tooling.

## Key Highlights

- **Built-in `vim.lsp.config` & `vim.lsp.enable()`**: Native LSP management on Neovim 0.11+.
- **blink-cmp**: Modern completion engine with LSP, snippets, path, and buffer sources.
- **Multi-Language Diff & Patch Highlighting**: Full Tree-sitter injected syntax highlighting for `.patch` and `.diff` files across all configured languages.
- **Interactive Patch Review & Operations**: Dedicated buffer actions to inspect, apply, stage, reverse, quickfix-index, and navigate patches directly in Neovim.
- **Optimized Diff Engine**: Histogram diff algorithm with `linematch:60` for clean intra-line alignment.

---

## File Structure

```
~/.config/nvim/
├── after/
│   ├── ftplugin/
│   │   └── diff.lua              # Patch operations, navigation & jump-to-source
│   └── queries/
│       └── diff/
│           ├── highlights.scm    # High-priority diff sign highlights
│           └── injections.scm    # Dynamic multi-language syntax injections
├── lua/
│   └── kiyo/
│       ├── core/
│       │   ├── autocmds.lua      # Autocommands (whitespace guard for diffs)
│       │   └── options.lua       # Diffopt (histogram algorithm & linematch)
│       └── plugins/
│           ├── blink.lua         # Blink-cmp completion configuration
│           ├── colorscheme.lua   # Catppuccin with soft diff background tints
│           ├── git.lua           # Gitsigns, Diffview, Neogit setup
│           ├── lsp.lua           # LSP server definitions & settings
│           ├── mason.lua         # Mason package installer
│           └── treesitter.lua    # Parsers and syntax highlighting
├── plugin/
│   └── ft.lua                    # Custom filetype detections (.patch, .diff, etc.)
└── init.lua
```

---

## Git, Diff & Patch Workflows

### 1. Multi-Language Diff & Patch Highlighting
Opening any `.diff` or `.patch` file (or unified diff from git) dynamically injects the appropriate syntax parser based on the target filename:
- **Supported Languages**: C, C++, C#, TSX, JSX, Python, Go, Rust, Vue, Kotlin, Zig, Elm, Blade, Swift, CMake, Make, SCSS, JSON5, Protobuf, CUDA, and more.
- **Visual Contrast**:
  - **Additions (`@diff.plus`)**: Soft theme-blended green background (`#394545`) layered underneath language syntax highlighting.
  - **Deletions (`@diff.minus`)**: Soft theme-blended red background (`#493446`) layered underneath language syntax highlighting.
  - **Diff Signs (`@diff.plus.sign`, `@diff.minus.sign`)**: Bold high-contrast leading `+` and `-`.
  - **Hunk Headers (`@diff.location`)**: Distinct sapphire accent background.

### 2. Patch File Operations (`<leader>p` in diff buffers)
When viewing a `.patch` or `.diff` file, the following buffer-local shortcuts are available:

| Keymap | Action | Description |
|---|---|---|
| `<leader>pc` | **Check patch** | Runs `git apply --check` to verify the patch applies cleanly |
| `<leader>pa` | **Apply patch** | Runs `git apply` to apply changes directly to the working tree |
| `<leader>ps` | **Stage patch** | Runs `git apply --cached` to apply directly into Git's index (staging area) |
| `<leader>pr` | **Reverse patch** | Runs `git apply --reverse` to back out a previously applied patch |
| `<leader>p3` | **3-way merge apply** | Runs `git apply -3` to resolve conflicts if code has drifted |
| `<leader>pq` | **Load to Quickfix** | Indexes all files and hunks in the patch into the Quickfix list (`:copen`) |
| `<leader>py` | **Yank hunk** | Copies the current hunk under the cursor into the system clipboard (`+` register) |

### 3. Smart Navigation & Jump-to-Source
- **`<CR>` or `gf`**:
  - If cursor is on a **file header** (`diff --git a/... b/...`, `+++`, `---`), jumps directly to line 1 of that file.
  - If cursor is inside a **hunk**, calculates the exact target file and line number (accounting for deleted lines) and opens the file.
  - If the file was deleted (`+++ /dev/null`), falls back to the original file (`--- a/...`).
- **` ]c ` / ` [c `**: Jump to the next / previous diff hunk (`@@`).
- **` ]f ` / ` [f `**: Jump to the next / previous file header (`diff --git` or `---`).
- **` zc ` / ` zo ` / ` zM ` / ` zR `**: Native Tree-sitter diff folding to collapse/expand hunks and files.

### 4. Intra-Line Word Diff & Diffview
- `<leader>Gw`: Toggle inline word-diff highlighting (`gitsigns.toggle_word_diff()`) to see character-by-character changes in any modified file.
- `<leader>GL`: Toggle full-line diff background highlights (`gitsigns.toggle_linehl()`).
- `<leader>gv`: Open side-by-side git diff view (`:DiffviewOpen`).
- `<leader>gc`: Close git diff view (`:DiffviewClose`).
- `<leader>gh`: View git commit history of the current file (`:DiffviewFileHistory %`).
- `<leader>gH`: View git repository-wide commit history (`:DiffviewFileHistory`).
- `<leader>gt`: Toggle Diffview file tree panel (`:DiffviewToggleFiles`).

---

## LSP & Completion

### Default LSP Keybindings (Neovim 0.11+)
These work automatically when an LSP server is attached:

- `gd` - Go to definition
- `gD` - Go to declaration
- `gr` - Go to references
- `K` - Hover documentation
- `<C-k>` - Signature help (in insert mode)
- `<space>rn` - Rename symbol
- `<space>ca` - Code action
- `<space>f` - Format buffer

### Configured Language Servers
Configured via `mason.lua` and `lsp.lua`:
- **TypeScript/JavaScript**: `ts_ls`
- **HTML**: `html`
- **CSS / SCSS**: `cssls`
- **Lua**: `lua_ls`
- **Python**: `pyright`
- **Go**: `gopls`
- **Rust**: `rust_analyzer`
- **C/C++**: `clangd`
- **Vue**: `vue-language-server`
- **Zig**: `zls`
- **Kotlin**: `kotlin-language-server`
- **PHP/Blade**: `intelephense`

---

## Important Notes

> [!WARNING]
> On Neovim 0.11+, manual capability configuration for `vim.lsp.config` is unnecessary; blink-cmp capabilities are detected automatically.

> [!TIP]
> To enable inline virtual text diagnostics:
> ```lua
> vim.diagnostic.config({ virtual_text = true })
> ```
