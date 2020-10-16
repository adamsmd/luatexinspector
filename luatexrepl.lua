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

print('++++++++ LuaTeXRepl GUI ++++++++')

-- https://github.com/nymphium/lua-graphviz
-- https://github.com/hleuwer/luagraph
-- http://siffiejoe.github.io/lua-microscope/

-- https://github.com/hishamhm/tabular
-- https://github.com/kikito/inspect.lua

-- https://github.com/pavouk/lgi/blob/master/samples/gtk-demo/demo-treeview-editable.lua

lgi = require 'lgi'
Gtk = lgi.require 'Gtk'
GLib = lgi.require 'GLib'
--assert = lgi.assert

builder = Gtk.Builder()
-- TODO: error checking
print(builder:add_from_file('luatexrepl.glade'))
-- TODO: assert
print('++++++++ LuaTeXRepl GUI2 ++++++++')

ui = builder.objects


LuaTeXRepl = lgi.package('LuaTeXRepl')

--input_row_builder = Gtk.Builder()
--print(builder:add_from_file('luatexrepl-input_row.glade'))
file = io.open('luatexrepl-input_row.glade', "rb") -- r read mode and b binary mode
assert(file)
content = file:read "*all" -- *a or *all reads the whole file
file:close()
print(content)

-- Create top level window with some properties and connect its 'destroy'
-- signal to the event loop termination.
window = ui.window

-- local step_button = ui.step_button
-- function step_button:on_clicked()
--   -- TODO
-- end

-- local expand_button = ui.expand_button
-- function expand_button:on_clicked()
--   -- TODO
-- end

-- Icons:
--   document-page-setup
--   text-x-generic-templpate
--   text-x-script

-- Create some more widgets for the window.
statusbar = ui.statusbar
statusbar_ctx = statusbar:get_context_id('default')
statusbar:push(statusbar_ctx, 'This is statusbar message.')

-- on_clicked = function() window:destroy() end

function window:on_destroy()
  Gtk.main_quit()
end

function ui.file_quit_menu_item:on_activate()
  window:destroy()
end

function ui.step_button:on_clicked()
  print("EXECUTE")
  tex.execute()
  refresh()
end

function ui.expand_button:on_clicked()
  print("EXPAND")
  tex.expand()
  refresh()
end

function ui.refresh_button:on_clicked()
  print("REFRESH")
  refresh()
end

-- function about_button:on_clicked()
--   dlg:run()
--   dlg:hide()
-- end

-- Connect 'Quit' actions.
--function ui.Quit:on_activate()
--  window:destroy()
--end

-- function ui.About:on_activate()
--   ui.about_dialog:run()
--   ui.about_dialog:hide()
-- end

-- Show window and start the loop.
window:show_all()

-- Ctrl-C = Gtk.main_quit()

InputRowWidget = LuaTeXRepl:class('InputRow', Gtk.ListBoxRow)
do
  local IR = InputRowWidget()
  InputRowClass = IR._class
  --InputRowClass = InputRow._class()
  InputRowClass:set_template(GLib.Bytes(content))
  InputRowClass:bind_template_child_full('expander', false, 0)
  InputRowClass:bind_template_child_full('short_label', false, 0)
  InputRowClass:bind_template_child_full('long_label', false, 0)
  IR = nil
end
--InputRow:set_template(GLib.Bytes(content))

InputRow = {}
function InputRow:new(index)
  local widget = InputRowWidget()
  widget:init_template()
  local object = {
    index = index,
    widget = widget,
    expander = widget:get_template_child(InputRowWidget, 'expander'),
    short_label = widget:get_template_child(InputRowWidget, 'short_label'),
    long_label = widget:get_template_child(InputRowWidget, 'long_label')
  }
  setmetatable(object, self)
  self.__index = self
  object:refresh()
  return object
end
function InputRow:refresh()
  print("\n\n")
  local size = token.inputstacksize()
  if self.index > size then
    self.short_label:set_text("<out-of-scope>")
  else
    local input_state = token.getinputstack(self.index)
    print("INDEX:", self.index, "TOKENS:", input_state.tokens)
    if input_state.tokens ~= nil then
      local short_string = string.format("Y %d: ", self.index)
      print("SIZE:", #input_state.tokens)
      print("LOC:", input_state.tokens.loc)
      for i=input_state.tokens.loc,#input_state.tokens do
        tok = input_state.tokens[i]
        print("I:", i, "TOK:", tok)
        if tok.command == 11 then
          short_string = short_string .. string.char(tok.mode)
          -- Letter
          -- return string.format(
          --   '<token %x: %s (%d) %s (%d)>',
          --   tok.tok, tok.cmdname, tok.command, string.char(tok.mode), tok.mode)
        elseif tok.command == 5 then -- `car_ret`, which seems to be used for arguments
          short_string = short_string .. '#' .. tok.mode
        else
          short_string = short_string .. '\\' .. tok.cmdname .. ' '
          -- -- Non-letter
          -- return string.format(
          --   '<token %x: %s (%d) %s [%d] %s%s%s>',
          --   tok.tok, tok.cmdname, tok.command, tok.csname, tok.mode,
          --   tok.active     and 'A' or '-',
          --   tok.expandable and 'E' or '-',
          --   tok.protected  and 'P' or '-')
        --end
        end
      end
      print("INPUT:", self.index)
      print("SHORT:", short_string)
      self.short_label:set_text(short_string)
    else
      print("INPUT:", self.index)
      print("SHORT:", input_state.line)
      self.short_label:set_text(string.format("X %d: %s", self.index, input_state.line))
    end
  end
  --self.short_label
  --token.inputstacksize
  --token.getinputstack
end

-- TODO: "step +10" button
-- TODO: "step until next expand" button
-- TODO: "step until smaller stack" button

input_rows = {}

do
  local y = InputRow:new(0)
  input_rows[0] = y
  print(i)
  print(y)
  print(y.widget)
  ui.input_list_box:insert(y.widget, -1)
end

-- >  t = nodetree.analyze(tex.nest[1].head, {channel = 'str'})

function refresh()
  local stack_size = token.inputstacksize()
  print("STACK SIZE:", stack_size)
  print("INPUT_ROWS:", #input_rows)
  for i=stack_size+1,#input_rows do
    print("DELETE:", i)
    local y = input_rows[i]
    print("Y:", y)
    print("Y:", y.widget)
    ui.input_list_box:remove(y.widget)
    input_rows[i] = nil
  end
  for i=#input_rows+1,stack_size do
    print("ADD:", i)
    local y = InputRow:new(i)
    input_rows[i] = y
    print(i)
    print(y)
    print(y.widget)
    ui.input_list_box:insert(y.widget, -1)
  end
  print("OK:", #input_rows == stack_size)
  for i=0,stack_size do
    input_rows[i]:refresh()
  end
end
refresh()

-- TODO: attach InputRow to InputRowWidget as userdata?

  --local x = InputRow:new(0)
  --ui.input_list_box:insert(x.widget, -1)

--y = InputRow:new(2)
--ui.input_list_box:insert(y.widget, -1)

--Gtk.main()

--\\directlua{require 'luatexrepl.lua'}\\xxx\\yyy a\\zzz b\\www c

print('-------- LuaTeXRepl GUI --------')


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
