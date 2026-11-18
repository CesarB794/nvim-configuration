# Configuración de Neovim (0.12+)

Config personal migrada de CoC.nvim a **LSP 100% nativo** (`vim.lsp`).
Sin Node.js residente: los servers solo se lanzan al abrir un buffer de su lenguaje.

## Instalación en una máquina nueva

### Windows (PowerShell)

```powershell
# Si ya existe un nvim antiguo, respáldalo primero
git clone https://github.com/CesarB794/nvim-configuration.git "$env:LOCALAPPDATA\nvim"
nvim  # el primer arranque instala vim-plug y los plugins automáticamente
```

### Linux / macOS

```bash
# respaldo previo si aplica: mv ~/.config/nvim ~/.config/nvim.bak
git clone https://github.com/CesarB794/nvim-configuration.git ~/.config/nvim
nvim
```

## Language servers (instalación por lenguaje, Nvim los detecta solo)

| Lenguaje | Server | Instalación |
|---|---|---|
| C/C++ | clangd | `winget install LLVM.LLVM` (añadir `LLVM\bin` al PATH) |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| Python | pyright | `pip install pyright` |
| TS/JS | ts_ls | `npm i -g typescript typescript-language-server` |
| JSON/HTML/CSS | — | `npm i -g vscode-langservers-extracted` |
| Vimscript | vimls | `npm i -g vim-language-server` |
| Clojure | clojure_lsp | https://clojure-lsp.io (descomentar en init.lua) |

Verificación: `:checkhealth vim.lsp`

## Estructura

- `init.lua` — toda la configuración (plugins con vim-plug, LSP nativo, keymaps)
- `colors/` — colorscheme local (spacecamp)
- `local.lua` — overrides por máquina (**no versionado**), opcional

## Atajos principales

`gd`/`gy`/`gi`/`gr` definición/tipo/impl/referencias · `K` hover · `[g`/`]g` diagnósticos ·
`<leader>rn` renombrar · `<leader>f` formatear · `<leader>a` code action ·
`<space>a` lista diagnósticos · `<space>o` outline · `<space>s` símbolos workspace ·
`<space>t` terminal · `<space>pp` ejecutar Python · `<space>w` explorador · `:Snip` snippets
