-- luarocks install luaprompt
--
-- sudo apt install libgirepository1.0-dev
-- luarocks install lgi
--
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape --lua=luatexrepl-startup.lua luatexrepl.tex
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape luatexrepl.tex
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" lualatex --shell-escape luatexrepl.tex
--
-- make && yes | cp luatex luahbtex ../../../../../Master/bin/x86_64-linux/
--
-- LuaTeX 1.10.0 == Lua 5.3
-- LuaTeX 1.12.0 == Lua 5.3

print('\n++++++++ LuaTeXRepl ++++++++')

print('++++++++ LuaTeXRepl Searchers ++++++++')
function myloader(name)
  local filename = package.searchpath(name, package.path)

  if not filename then
    return string.format('\n\t[myloader] file not found: \'%s\'', name)
  end

  local module = loadfile(filename)
  return module
end
function mycloader(name)
  local filename = package.searchpath(name, package.cpath)

  if not filename then
    return string.format('\n\t[mycloader] file not found: \'%s\'', name)
  end

  local modname = string.gsub(name, '%.', '_');

  -- TODO:
  -- local mark = strchr(modname, *LUA_IGMARK);
  --  mark = package.config line 4
  -- if (mark) {
  --   int stat;
  --   openfunc = lua_pushlstring(L, modname, mark - modname);
  --   openfunc = lua_pushfstring(L, LUA_POF"%s", openfunc);
  --   stat = lookforfunc(L, filename, openfunc);
  --   if (stat != ERRFUNC) return stat;
  --   modname = mark + 1;  /* else go ahead and try old-style name */
  -- }

  local openfunc = string.format('luaopen_%s', modname);

  local module = package.loadlib(filename, openfunc)
  return module
end

print('Searchers before:', #package.searchers)
package.searchers[#package.searchers+1] = myloader;
package.searchers[#package.searchers+1] = mycloader;
print('Searchers after:', #package.searchers)

print('-------- LuaTeXRepl Searchers --------')

print('++++++++ LuaTeXRepl Functions ++++++++')
local luatex_version = status.list().luatex_version

--------------------------------
-- Tokens
--------------------------------
function peek_next(count)
  if count == nil then
    return peek_next(1)[1]
  end

  local toks = {}

  for i=1,count,1 do
    toks[i] = token.get_next()
  end

  for i=count,1,-1 do
    token.put_next(toks[i])
  end

  return toks
end

function token_table(tok) -- TODO: support ...
  return {
    command = tok.command,
    cmdname = tok.cmdname,
    csname = tok.csname,
    id = tok.id,
    tok = tok.tok,
    active = tok.active,
    expandable = tok.expandable,
    protected = tok.protected,
    mode = tok.mode,
    -- in some versions this causes a segfault, so we omit it
    index = luatex_version >= 112 and tok.index or nil,
  }
end
function token_tostring(tok)
  if tok.command == 11 then
    -- Letter
    return string.format(
      '<token %x: %s (%d) %s (%d)>',
      tok.tok, tok.cmdname, tok.command, string.char(tok.mode), tok.mode)
  else
    -- Non-letter
    return string.format(
      '<token %x: %s (%d) %s [%d] %s%s%s>',
      tok.tok, tok.cmdname, tok.command, tok.csname, tok.mode,
      tok.active     and 'A' or '-',
      tok.expandable and 'E' or '-',
      tok.protected  and 'P' or '-')
  end
end
local token_metatable = getmetatable(token.create("relax"))
token_metatable.__tostring = token_tostring

--------------------------------
-- Modes
--------------------------------
modenames = {}
modenums = {}
for k,v in pairs(tex.getmodevalues()) do
  modenames[k] = v
  modenums[v] = k
end

-- See the top of source/texk/web2c/luatexdir/tex/nesting.c for these explanations
-- 'unset': processing \write texts in the ship_out() routine
-- 'vertical': the page builder
-- 'horizontal': the paragraph builder
-- 'math': display math
modenames[-modenums['vertical']] = 'internal vertical' -- e.g., in a \vbox
modenames[-modenums['horizontal']] = 'restricted horizontal' -- e.g., in an \hbox
modenames[-modenums['math']] = 'non-display math' -- non-display math

--------------------------------
-- Nests
--------------------------------
function nest_table(nest)
  local table = {
    mode = nest.mode, -- negative indicate inner and inline variants
    modeline = nest.modeline, -- source input line where this mode was entered in, negative inside the output routine
    head = nest.head,
    tail = nest.tail,
  }

  local modename = modenames[math.abs(table.mode)]
  if modename == "vertical" then
    table.prevgraf = nest.preav --  number of lines in the previous paragraph
    table.prevdepth = nest.prevdepth -- depth of the previous paragraph
  elseif modename == "horizontal" then
    table.spacefactor = nest.spacefactor -- (num)
    table.dirs = nest.dirs -- (node) temp storage by line break algorithm
  elseif modename == "math" then
    table.noad = nest.noad -- used for temporary storage of a pending fraction numerator, for \over etc
    table.delimptr = nest.delimptr -- used for temporary storage of the previous math delimiter, for \middle
    table.mathdir = nest.mathdir -- true when during math processing the \mathdir is not the same as the surrounding \textdir
    table.mathstyle = nest.mathstyle -- num
  else
    error() -- TODO: raise error
  end
  return table
end
function nest_tostring(nest)
  local prefix = string.format('<%s (%d) L%d', modenames[nest.mode], nest.mode, nest.modeline)
  local suffix = string.format('tail: %s head: %s>', nest.tail, nest.head)
  local modename = tex.getmodevalues()[math.abs(nest.mode)]
  if modename == "vertical" then
    return string.format(
      "%s prevgraf: %d prevdepth: %d %s",
      prefix, nest.prevgraf, nest.prevdepth, suffix)
  elseif modename == 'horizontal' then
    return string.format(
      "%s spacefactor: %d dirs: %s %s",
      prefix, nest.spacefactor, nest.dirs, suffix)
  elseif modename == 'math' then
    return string.format(
      "%s noad: %s delimptr: %s mathdir: %s mathstyle: %d %s",
      prefix, nest.noad, nest.delimptr, nest.mathdir, nest.mathstyle, suffix)
  else
    error() -- TODO: raise error
  end
end
local nest_metatable = getmetatable(tex.nest[1])
--TODO: nest_metatable.__tostring = nest_tostring

--------------------------------
-- Nodes
--------------------------------
function node_table(node) -- TODO: support ...
end

-- page_ins_head -- circular list of pending insertions
-- contrib_head -- the recent contributions
-- page_head -- the current page content
-- hold_head -- used for held-over items for next page
-- adjust_head -- head of the current \vadjust list
-- pre_adjust_head -- head of the current \vadjust pre list
-- page_discards_head -- head of the discarded items of a page break
-- split_discards_head -- head of the discarded items in a vsplit

-- temp_head
-- best_page_break
-- least_page_cost
-- best_size
-- align_head

--[[Since we can't figure out how to use token.expand().  The following uses
'\expandafter\relax' to accomplish the same.]]
local expandafter_token = token.create("expandafter")
local relax_token = token.create("relax")
function expand()
  token.put_next(expandafter_token, relax_token)
  token.scan_token() -- Triggers the expansion and reads back the \relax token
  -- TODO: fix undefined_cs?
end
print('-------- LuaTeXRepl Functions --------')

-- https://github.com/Josef-Friedrich/nodetree/blob/master/nodetree.lua
nodetree = require 'nodetree'
-- nodetree.analyze(list)
-- https://gist.github.com/pgundlach/556247
viznodelist = require 'viznodelist'
-- viznodelist.nodelist_visualize(box, filename, { showdisc = true })

print('++++++++ LuaTeXRepl luaprompt ++++++++')
prompt = require 'prompt'

prompt.name = 'luatexrepl'

local dirsep = string.match (package.config, "[^\n]+")
local dirname = os.getenv('HOME') -- TODO: os.env?
for _k,v in pairs({'local', 'share', 'luatexrepl'}) do
  dirname = dirname .. dirsep .. v
  lfs.mkdir(dirname)
end
prompt.history = dirname .. '/history'

prompt.enter()
print('-------- LuaTeXRepl luaprompt --------')

print('-------- LuaTeXRepl --------')

-- need to set console file mode?
-- need to set stdin mode?
-- need to set stdout and stderr flush mode?

-- require 'vinspect' (tex)
-- tex.nest[tex.nest.ptr].mode
-- token.commands
-- tex.primitives
-- coroutines

-- \stop
-- \endlocalcontrol

-- Manually do 'run_ignore_spaces' due to it skipping the token stack

-- Feature requests:
--   Leave access to old Lua load commands
--   Non-saving version of get_next so we can then call expand
--   (!) Access to invoke jump_table

-- How to build luatex
--   Master (bin/x86_64-linux,tlpkg,texmf-dist)
--   Build/source/Build
--   Copy Build/source/inst/bin/x86_64-pc-linux-gnu/luatex to Master/bin/x86_64-pc-linux-gnu/
--   (!!) Set the PATH to texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux/
-- svn co --depth=immediates ...
-- svn update --set-depth=immediates ...
-- svn update --set-depth=infinity ...
-- svn update --set-depth=empty ...
-- svn update --set-depth=exclude ...

-- dot -Txlib (automatically updates when the file is updated)

-- insert_vj_template
-- u_j template
-- inputstack.c
--    show_context()
--    input_stack
