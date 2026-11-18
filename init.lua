-- ============================================================================
-- init.lua — Config Neovim (0.12+) — migrada de CoC.nvim a LSP 100% nativo
-- Este directorio es un repo git: en una máquina nueva,
--   git clone <repo> "$env:LOCALAPPDATA\nvim"
-- (Linux/macOS: git clone <repo> ~/.config/nvim)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Overrides por máquina (opcional, NO versionado: ver .gitignore)
-- Ej.: vim.g.python3_host_prog = 'D:/Python/python.exe'
-- ---------------------------------------------------------------------------
local local_cfg = vim.fn.stdpath('config') .. '/local.lua'
if vim.fn.filereadable(local_cfg) == 1 then
  dofile(local_cfg)
end

-- Python provider: primera opción que exista en esta máquina
if vim.g.python3_host_prog == nil then
  local py_candidates = {
    'C:\\Users\\Cesar\\AppData\\Local\\Programs\\Python\\Python310\\python.exe', -- Windows actual
    'python', -- lo que haya en PATH
  }
  for _, py in ipairs(py_candidates) do
    if vim.fn.executable(py) == 1 then
      vim.g.python3_host_prog = py
      break
    end
  end
end

-- ---------------------------------------------------------------------------
-- PowerShell como shell interno de Nvim (:!, :make, :terminal, <space>t)
-- ---------------------------------------------------------------------------
if vim.fn.has('win32') == 1 then
  vim.opt.shell = 'powershell.exe'
  vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
  vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s'
  vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
end

-- ---------------------------------------------------------------------------
-- Bootstrap de vim-plug (auto-instalación en máquinas nuevas)
-- ---------------------------------------------------------------------------
local plug_path = vim.fn.stdpath('data') .. '/site/autoload/plug.vim'
if vim.fn.filereadable(plug_path) == 0 then
  local ok = pcall(function()
    vim.fn.system({ 'curl', '-fLo', plug_path, '--create-dirs',
      'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' })
  end)
  if not ok or vim.v.shell_error ~= 0 then
    -- Fallback para Windows sin curl.exe
    vim.fn.system({
      'powershell', '-NoProfile', '-Command',
      ('iwr -UseBasicParsing -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile "%s"'):format(plug_path),
    })
  end
end

-- ---------------------------------------------------------------------------
-- Plugins (vim-plug, mismo gestor que ya tenías)

-- ---------------------------------------------------------------------------
-- Plugins (vim-plug, mismo gestor que ya tenías)
-- Eliminados: coc.nvim, gocode, YCM-Generator, vim-lsp-cxx-highlight,
--             ultisnips, python-syntax (todo reemplazado por lo nativo)
-- ---------------------------------------------------------------------------
local plug = vim.fn['plug#']
vim.call('plug#begin', vim.fn.stdpath('data') .. '/plugged')
plug('jaredgorski/spacecamp')            -- colorscheme (también existe en colors/)
plug('jiangmiao/auto-pairs')
plug('vim-airline/vim-airline')
plug('scrooloose/nerdtree', { on = 'NERDTreeToggle' })
plug('tpope/vim-fireplace')              -- Clojure
plug('junegunn/vim-easy-align')
plug('fatih/vim-go')                     -- tooling Go (complementa gopls)
plug('neovim/nvim-lspconfig')            -- catálogo de definiciones de servers
plug('rafamadriz/friendly-snippets')     -- snippets para :Snip (ver abajo)
plug('nvim-treesitter/nvim-treesitter', { branch = 'main', ['do'] = ':TSUpdate' })
plug('nvim-treesitter/nvim-treesitter-textobjects', { branch = 'main' })
vim.call('plug#end')

-- Primera ejecución en una máquina nueva: instalar lo que falte y recargar
local missing_plugins = {}
for _, spec in pairs(vim.g.plugs or {}) do
  if vim.fn.isdirectory(spec.dir) == 0 then
    missing_plugins[#missing_plugins + 1] = vim.fn.fnamemodify(spec.dir, ':t')
  end
end
if #missing_plugins > 0 then
  vim.notify('Instalando plugins faltantes: ' .. table.concat(missing_plugins, ', '))
  vim.cmd('PlugInstall --sync')
  vim.cmd('source $MYVIMRC')
end

-- ---------------------------------------------------------------------------
-- tree-sitter: resaltado por árbol de sintaxis real (requiere tree-sitter-cli
-- y un compilador de C en PATH; los parsers se compilan localmente).
-- ---------------------------------------------------------------------------
local ok_ts, ts = pcall(require, 'nvim-treesitter')
if ok_ts then
  -- Parsers de los lenguajes de uso diario (no-op si ya están instalados)
  ts.install({
    'c', 'cpp', 'go', 'python', 'typescript', 'javascript', 'json', 'html',
    'css', 'vim', 'vimdoc', 'lua', 'markdown', 'markdown_inline', 'clojure',
    'powershell',
  })

  -- Activar el resaltado nativo de Nvim; si no hay parser para el filetype,
  -- queda el resaltado por regex como fallback.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
    callback = function(args)
      if pcall(vim.treesitter.start, args.buf) then
        vim.bo[args.buf].syntax = '' -- evitar doble resaltado (treesitter + regex)
      end
    end,
  })
end

-- Text objects por símbolo con tree-sitter (restaura if/af/ic/ac de CoC,
-- con selección estructural precisa).
local ok_to, ts_select = pcall(require, 'nvim-treesitter-textobjects.select')
if ok_to then
  local to_opts = { silent = true }
  vim.keymap.set({ 'x', 'o' }, 'if', function() ts_select.select_textobject('@function.inner', 'textobjects') end, to_opts)
  vim.keymap.set({ 'x', 'o' }, 'af', function() ts_select.select_textobject('@function.outer', 'textobjects') end, to_opts)
  vim.keymap.set({ 'x', 'o' }, 'ic', function() ts_select.select_textobject('@class.inner', 'textobjects') end, to_opts)
  vim.keymap.set({ 'x', 'o' }, 'ac', function() ts_select.select_textobject('@class.outer', 'textobjects') end, to_opts)
end

-- ---------------------------------------------------------------------------
-- Opciones básicas (equivalente a tu init.vim)
-- ---------------------------------------------------------------------------
vim.opt.number = true
vim.opt.hidden = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.updatetime = 300
vim.opt.signcolumn = 'number'           -- signcolumn integrada en la columna de números
vim.opt.shortmess:append('c')           -- no saturar la pum con mensajes
vim.opt.cmdheight = 1
vim.opt.completeopt = 'menuone,noselect,popup'  -- necesario para el completado nativo LSP

-- Folding vía LSP cuando el server lo soporta (sustituye :Fold de CoC)
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.lsp.foldexpr()'
vim.opt.foldenable = false              -- no plegar todo al abrir (mismo efecto que antes)

vim.cmd('syntax enable')
vim.cmd('colorscheme spacecamp')

-- Config de auto-pairs que tenías
vim.g.AutoPairs = { ['('] = ')', ['['] = ']', ['{'] = '}', ["'"] = "'", ['"'] = '"', ['```'] = '```', ['`'] = '`' }

-- easy-align
vim.keymap.set('x', 'ga', '<Plug>(EasyAlign)')
vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)')

-- ---------------------------------------------------------------------------
-- LSP nativo: habilitar servers (se conectan solo al abrir un buffer del ft)
-- Si un server no está instalado, Nvim simplemente lo ignora sin errores.
-- ---------------------------------------------------------------------------
local servers = {
  'clangd',      -- C/C++   → winget install LLVM.LLVM  (o ya viene con Visual Studio)
  'gopls',       -- Go      → go install golang.org/x/tools/gopls@latest
  'pyright',     -- Python  → pip install pyright
  'ts_ls',       -- TS/JS   → npm i -g typescript typescript-language-server
  'jsonls',      -- JSON    → npm i -g vscode-langservers-extracted
  'html',        -- HTML    → npm i -g vscode-langservers-extracted
  'cssls',       -- CSS     → npm i -g vscode-langservers-extracted
  'vimls',       -- Vimscript → npm i -g vim-language-server
  'powershell_es', -- PowerShell (bundle en nvim-data/lsp; ver README)
  -- 'clojure_lsp', -- Clojure → instalar de https://clojure-lsp.io y descomentar
}
vim.lsp.enable(servers)

-- PowerShell LSP (PowerShellEditorServices de Microsoft)
-- Instalación: descargar el zip de
--   https://github.com/PowerShell/PowerShellEditorServices/releases
-- y extraerlo en stdpath('data')/lsp → queda /lsp/PowerShellEditorServices/...
-- (bundle_path apunta al PADRE del módulo: lspconfig añade
--  'PowerShellEditorServices/Start-EditorServices.ps1' a la ruta)
local pses_path = vim.fn.stdpath('data') .. '/lsp'
if vim.fn.isdirectory(pses_path .. '/PowerShellEditorServices') == 1 then
  vim.lsp.config('powershell_es', {
    bundle_path = pses_path,
    shell = 'powershell.exe', -- lspconfig usa 'pwsh' por defecto (no instalado aquí)
    -- lspconfig declara solo {'ps1'}, pero el filetype real de Nvim es 'powershell'
    filetypes = { 'powershell', 'ps1' },
  })
end

-- Ajustes para eliminar warnings de :checkhealth vim.lsp
-- (lspconfig declara filetypes que Nvim no tiene definidos y nunca ocurren)
vim.lsp.config('clangd', {
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
})
vim.lsp.config('gopls', {
  filetypes = { 'go', 'gomod', 'gowork' },
})

-- ---------------------------------------------------------------------------
-- Comportamiento al adjuntar un LSP: completado nativo + atajos estilo CoC
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- Completado nativo con auto-trigger (sustituye a CoC)
    if client:supports_method('textDocument/completion', buf) then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
    end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = 'LSP: ' .. desc })
    end

    -- GoTo (mismos atajos que CoC)
    map('n', 'gd', vim.lsp.buf.definition, 'ir a definición')
    map('n', 'gy', vim.lsp.buf.type_definition, 'ir a definición de tipo')
    map('n', 'gi', vim.lsp.buf.implementation, 'ir a implementación')
    map('n', 'gr', vim.lsp.buf.references, 'referencias')

    -- Documentación (K)
    map('n', 'K', vim.lsp.buf.hover, 'documentación')

    -- Diagnósticos (antes [g / ]g)
    map('n', '[g', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'diagnóstico anterior')
    map('n', ']g', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'diagnóstico siguiente')

    -- Renombrar / formatear / code actions
    map('n', '<leader>rn', vim.lsp.buf.rename, 'renombrar símbolo')
    map({ 'n', 'x' }, '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'formatear')
    map({ 'n', 'x' }, '<leader>a', vim.lsp.buf.code_action, 'code action')

    -- Listas (antes <space>a/o/s de CocList)
    map('n', '<space>a', vim.diagnostic.setloclist, 'lista de diagnósticos')
    map('n', '<space>o', vim.lsp.buf.document_symbol, 'outline del documento')
    map('n', '<space>s', vim.lsp.buf.workspace_symbol, 'símbolos del workspace')

    -- Trigger manual de completado (antes <c-space> coc#refresh)
    map('i', '<C-Space>', vim.lsp.completion.get, 'forzar completado')

    -- Resaltar el símbolo bajo el cursor (antes CursorHold + CocAction highlight)
    if client:supports_method('textDocument/documentHighlight', buf) then
      local hl_group = vim.api.nvim_create_augroup('lsp-doc-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = hl_group,
        buffer = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = hl_group,
        buffer = buf,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = hl_group,
        buffer = buf,
        callback = function() vim.lsp.buf.clear_references() end,
      })
    end
  end,
})

-- Diagnósticos con el mismo estilo que CoC
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ---------------------------------------------------------------------------
-- Comandos que tenías con CoC
-- ---------------------------------------------------------------------------
-- :Format — formatear el buffer (antes CocActionAsync('format'))
vim.api.nvim_create_user_command('Format', function()
  vim.lsp.buf.format({ async = true })
end, { desc = 'Formatear buffer' })

-- :OR — organizar imports (antes editor.action.organizeImport)
vim.api.nvim_create_user_command('OR', function()
  vim.lsp.buf.code_action({
    context = { only = { 'source.organizeImports' } },
    apply = true,
  })
end, { desc = 'Organizar imports' })

-- :Fold de CoC ya no hace falta: foldmethod=expr usa vim.lsp.foldexpr()

-- ---------------------------------------------------------------------------
-- Terminal nativa (antes coc-terminal: <space>t / <space>tt / <space>pp)
-- La terminal abre en un split INFERIOR que ejecuta powershell.exe
-- (ver vim.opt.shell arriba).
-- ---------------------------------------------------------------------------
local function terminal_toggle()
  if vim.bo.buftype == 'terminal' then
    vim.cmd('quit')                    -- oculta la terminal (toggle)
  else
    local h = math.max(8, math.floor(vim.o.lines * 0.3))
    vim.cmd('botright ' .. h .. 'split | terminal')  -- franja inferior, ancho completo
  end
end

local function terminal_destroy()
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if vim.bo[b.bufnr].buftype == 'terminal' then
      vim.api.nvim_buf_delete(b.bufnr, { force = true })
    end
  end
end

local function python_run_file()
  vim.cmd('write')
  vim.cmd(('belowright split | terminal powershell -NoLogo -NoProfile -Command "python \'%s\'"'):format(vim.fn.expand('%:p')))
end

vim.keymap.set('n', '<space>t', terminal_toggle, { desc = 'Terminal toggle (split abajo)' })
vim.keymap.set('n', '<space>tt', terminal_destroy, { desc = 'Destruir terminales' })
vim.keymap.set('n', '<space>pp', python_run_file, { desc = 'Ejecutar archivo Python' })

-- ---------------------------------------------------------------------------
-- Explorador de archivos (antes coc-explorer <space>w → netrw nativo)
-- Abre/cierra un split DERECHO con netrw (toggle). NERDTree sigue disponible
-- con :NERDTreeToggle.
-- ---------------------------------------------------------------------------
local function explorer_toggle()
  -- Si ya hay un netrw abierto en algún split de esta pestaña, ciérralo
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(win)
    if vim.bo[b].filetype == 'netrw' then
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  -- Split vertical a la derecha, altura completa, con el explorador
  vim.cmd('botright vsplit')
  vim.api.nvim_win_set_width(0, 38)
  vim.cmd('Explore')
end

vim.keymap.set('n', '<space>w', explorer_toggle, { desc = 'Explorador toggle (split derecho)' })

-- ---------------------------------------------------------------------------
-- Snippets nativos con friendly-snippets (sustituye a UltiSnips)
-- Uso: <Tab> acepta items del pum; :Snip lista/expande snippets del filetype.
-- Los snippets que llegan dentro de las sugerencias del LSP se expanden
-- automáticamente al aceptarlas (nativo, sin UltiSnips ni Python externo).
-- ---------------------------------------------------------------------------
local snippet_cache = {}

local function snippets_for(ft)
  if snippet_cache[ft] ~= nil then return snippet_cache[ft] end
  local result = {}
  local file = vim.fn.stdpath('data') .. '/plugged/friendly-snippets/snippets/' .. ft .. '.json'
  if vim.fn.filereadable(file) == 1 then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), '\n'))
    if ok then
      for _, entry in pairs(data) do
        local list = entry
        -- friendly-snippets a veces agrupa snippets en sub-tablas
        if type(entry) == 'table' and entry.body == nil and entry.prefix == nil then
          list = {}
          for _, item in pairs(entry) do
            if type(item) == 'table' then list[#list + 1] = item end
          end
        end
        if type(list) == 'table' then
          for _, s in ipairs(list) do
            if type(s) == 'table' and s.prefix ~= nil then result[s.prefix] = s.body end
          end
        end
      end
    end
  end
  snippet_cache[ft] = result
  return result
end

vim.api.nvim_create_user_command('Snip', function(o)
  local ft = vim.bo.filetype
  if ft == '' then return vim.notify('Sin filetype: no hay snippets', vim.log.levels.WARN) end
  local snips = snippets_for(ft)
  local name = o.args
  if name == '' then
    local names = vim.tbl_keys(snips)
    if #names == 0 then return vim.notify('Sin snippets para "' .. ft .. '"', vim.log.levels.WARN) end
    table.sort(names)
    local idx = vim.fn.inputlist(vim.tbl_map(function(n) return n end, names))
    if idx < 1 or idx > #names then return end
    name = names[idx]
  end
  local body = snips[name]
  if not body then return vim.notify('Snippet "' .. name .. '" no encontrado', vim.log.levels.WARN) end
  if type(body) == 'table' then body = table.concat(body, '\n') end
  vim.snippet.expand(body)
end, {
  nargs = '?',
  desc = 'Expandir snippet de friendly-snippets',
  complete = function() return vim.tbl_keys(snippets_for(vim.bo.filetype)) end,
})

-- Navegación en la pum nativa: Tab/S-Tab, y CR acepta.
-- NOTA: se usan expresiones en string (no funciones Lua) para que auto-pairs
-- pueda inspeccionar el mapeo de <CR> con maparg().
vim.keymap.set('i', '<Tab>', 'pumvisible() ? "<C-n>" : "<Tab>"', { expr = true })
vim.keymap.set('i', '<S-Tab>', 'pumvisible() ? "<C-p>" : "<C-h>"', { expr = true })
-- CR: si la pum está visible, acepta el item seleccionado (equivale a coc#_select_confirm)
vim.keymap.set('i', '<CR>', 'pumvisible() ? "<C-y>" : "<C-g>u<CR>"', { expr = true })
