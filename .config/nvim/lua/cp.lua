-- competitive programming: compile/run/debug keymaps (F4-F10) and file templates
--
-- F4 = fast compile + run    F5 = quick compile + run   F6 = debug compile + run
-- F7 = debugger              F8 = input from clipboard  F9 = type input
-- F10 = run
--
-- all compile/run flows read stdin from a file named `input` in the cwd

local M = {}

-- c++ flag sets, single source of truth for the keymaps below and for
-- ~/laboratory/make_pch.bash (which builds one precompiled header per set,
-- cached in ~/.cache/cp-pch so any directory gets fast compiles)
local pch_dir = os.getenv('HOME') .. '/.cache/cp-pch'
-- -DLOCAL activates the debug() macro from ~/laboratory/debug.hpp; judges
-- don't define it, so submissions compile the no-op branch
M.cpp_flags = {
  fast = '-I. -I' .. pch_dir .. ' -DLOCAL -std=c++26 -Wall -O2',
  quick = '-I. -I' .. pch_dir .. ' -DLOCAL -std=c++26 -Wall',
  debug = table.concat({
    -- language & includes
    '-std=c++26',
    '-I.',
    '-I' .. pch_dir,
    '-DLOCAL',
    -- debug info
    '-g',
    '-gdwarf-4', -- lldb cannot read the DWARF 5 debug info GCC emits by default
    '-fno-omit-frame-pointer', -- reliable backtraces
    -- warnings
    '-Wall',
    '-Wextra',
    '-Wshadow',
    '-Wpedantic',
    '-Wformat=2',
    '-Wlogical-op',
    '-Wfloat-equal',
    '-Wcast-qual',
    '-Wcast-align',
    '-Wshift-overflow=2',
    '-Wduplicated-cond',
    '-Wnull-dereference',
    -- runtime checks
    '-fsanitize=address,undefined', -- plays nice with lldb
    '-fno-sanitize-recover=all', -- stop at the first UB instead of continuing
    '-fstack-protector',
    -- libstdc++ hardening (checked iterators, bounds asserts)
    '-D_GLIBCXX_DEBUG',
    '-D_GLIBCXX_DEBUG_PEDANTIC',
    '-D_GLIBCXX_SANITIZE_VECTOR',
    '-D_GLIBCXX_ASSERTIONS',
  }, ' '),
}

-- buffer-local normal-mode keymap
local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc })
end

local run_input = 'cat input && echo "----" && '

local function setup_cpp()
  local exec = run_input .. './%:r.out < input'
  local function compile_run(flags)
    return '<CMD>w!<CR><CMD>!g++ ' .. flags .. ' %:r.cpp -o %:r.out && ' .. exec .. '<CR>'
  end
  map('<F4>', compile_run(M.cpp_flags.fast), 'CP: compile (-O2) + run')
  map('<F5>', compile_run(M.cpp_flags.quick), 'CP: compile + run')
  map('<F6>', compile_run(M.cpp_flags.debug), 'CP: debug compile + run')
  -- gdb has no arm64 macOS support, so debug with lldb
  map('<F7>', '<CMD>terminal ' .. run_input .. 'lldb -o \'settings set target.input-path input\' %:r.out<CR>', 'CP: lldb')
  map('<F10>', '<CMD>!' .. exec .. '<CR>', 'CP: run')
end

local function setup_rust()
  local cargo_toml = vim.fs.find('Cargo.toml', { upward = true, path = vim.fn.expand('%:p:h') })[1]
  if cargo_toml then
    -- binary name from Cargo.toml
    local bin = 'main'
    for line in io.lines(cargo_toml) do
      local name = line:match('^name%s*=%s*"(.-)"')
      if name then
        bin = name
        break
      end
    end
    map('<F4>', '<CMD>w!<CR><CMD>!' .. run_input .. 'cargo run --release < input<CR>', 'CP: cargo run --release')
    map('<F5>', '<CMD>w!<CR><CMD>!' .. run_input .. 'cargo run < input<CR>', 'CP: cargo run')
    -- debug builds already have overflow & bounds checks
    map('<F6>', '<CMD>w!<CR><CMD>!' .. run_input .. 'RUST_BACKTRACE=1 cargo run < input<CR>', 'CP: cargo run + backtrace')
    -- --source-quietly hides the echo of the rust pretty-printer setup script
    map('<F7>', '<CMD>terminal cargo build && ' .. run_input .. 'rust-lldb --source-quietly -o \'settings set target.input-path input\' target/debug/' .. bin .. '<CR>', 'CP: rust-lldb')
    map('<F10>', '<CMD>!' .. run_input .. './target/debug/' .. bin .. ' < input<CR>', 'CP: run')
  else
    -- single file: mirrors the c++ workflow
    -- bare rustc defaults to edition 2015 and has no config file to change
    -- that, so pass the edition explicitly (kept in sync with lsp.lua's check)
    local exec = run_input .. './%:r.out < input'
    local function compile_run(flags)
      return '<CMD>w!<CR><CMD>!rustc --edition 2024 ' .. flags .. ' %:r.rs -o %:r.out && ' .. exec .. '<CR>'
    end
    map('<F4>', compile_run('-O'), 'CP: compile (-O) + run')
    map('<F5>', compile_run(''), 'CP: compile + run')
    map('<F6>', compile_run('-g -C debug-assertions=on -C overflow-checks=on'), 'CP: debug compile + run')
    map('<F7>', '<CMD>terminal ' .. run_input .. 'rust-lldb --source-quietly -o \'settings set target.input-path input\' %:r.out<CR>', 'CP: rust-lldb')
    map('<F10>', '<CMD>!' .. exec .. '<CR>', 'CP: run')
  end
end

local function setup_python()
  map('<F5>', '<CMD>w!<CR><CMD>!' .. run_input .. 'pypy3 %:r.py < input<CR>', 'CP: run with pypy3')
end

-- note: the filename must start with a capital letter as this doubles as the "class" name
local function setup_kotlin()
  local exec = run_input .. 'kotlin %:rKt.class < input'
  -- kotlinc has no optimization levels, F4 == F5
  map('<F4>', '<CMD>w!<CR><CMD>!kotlinc %:r.kt && ' .. exec .. '<CR>', 'CP: compile + run')
  map('<F5>', '<CMD>w!<CR><CMD>!kotlinc %:r.kt && ' .. exec .. '<CR>', 'CP: compile + run')
  map('<F6>', '<CMD>w!<CR><CMD>!kotlinc %:r.kt && ' .. run_input .. 'kotlin -J-ea %:rKt.class < input<CR>', 'CP: compile + run with assertions')
  -- debug with jdb (the JVM debugger; lldb cannot debug the JVM)
  -- once attached: stop in %:rKt.main   then: run, next, locals, cont
  map('<F7>', '<CMD>terminal ' .. run_input .. 'kotlin -J-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8005 %:rKt.class < input & sleep 1 && /opt/homebrew/opt/openjdk/bin/jdb -attach 8005<CR>', 'CP: jdb')
  map('<F10>', '<CMD>!' .. exec .. '<CR>', 'CP: run')
end

function M.setup()
  -- input helpers (global; useful regardless of language)
  vim.keymap.set('n', '<F8>', '<CMD>!pbpaste > input && cat input<CR>', { desc = 'Rip input from clipboard' })
  vim.keymap.set('n', '<F9>', '<CMD>terminal cat > input<CR>', { desc = 'Type a custom input' })

  local setups = { cpp = setup_cpp, rust = setup_rust, python = setup_python, kotlin = setup_kotlin }
  vim.api.nvim_create_autocmd('Filetype', {
    pattern = vim.tbl_keys(setups),
    callback = function(ev) setups[ev.match]() end,
  })

  -- new files default to the template from the cwd (present in ~/laboratory)
  for _, ext in ipairs({ 'cpp', 'kt', 'rs' }) do
    vim.api.nvim_create_autocmd('BufNewFile', { pattern = '*.' .. ext, command = '-r template.' .. ext })
  end
end

return M
