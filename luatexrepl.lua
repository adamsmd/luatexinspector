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
--
-- https://www.ctan.org/pkg/ant
-- https://github.com/patoline/patoline
-- https://sile-typesetter.org/
-- https://www.speedata.de/en/

-- tatic int getlist(lua_State * L)
-- {
--   lua_pushinteger(L, vlink(page_ins_head));
--   lua_pushinteger(L, vlink(contrib_head));
--   lua_pushinteger(L, page_disc);
--   lua_pushinteger(L, split_disc);
--   lua_pushinteger(L, vlink(page_head));
--   lua_pushinteger(L, vlink(temp_head));
--   lua_pushinteger(L, vlink(hold_head));
--   lua_pushinteger(L, vlink(adjust_head));
--   lua_pushinteger(L, best_page_break);
--   lua_pushinteger(L, least_page_cost);
--   lua_pushinteger(L, best_size);
--   lua_pushinteger(L, vlink(pre_adjust_head));
--   lua_pushinteger(L, vlink(align_head));
-- }
-- texnode.h
-- buildpage.h

-- #  define box_code      0 /* |chr_code| for `\.{\\box}' */
-- #  define copy_code     1 /* |chr_code| for `\.{\\copy}' */
-- #  define last_box_code 2 /* |chr_code| for `\.{\\lastbox}' */
-- #  define vsplit_code   3 /* |chr_code| for `\.{\\vsplit}' */
-- #  define tpack_code    4
-- #  define vpack_code    5
-- #  define hpack_code    6
-- #  define vtop_code     7 /* |chr_code| for `\.{\\vtop}' */

-- #  define tail_page_disc disc_ptr[copy_code] /* last item removed by page builder */
-- #  define page_disc disc_ptr[last_box_code]  /* first item removed by page builder */
-- #  define split_disc disc_ptr[vsplit_code]   /* first item removed by \.{\\vsplit} */

-- extern halfword disc_ptr[(vsplit_code + 1)]; /* list pointers */

-- extern halfword page_tail;      /* the final node on the current page */
-- extern int page_contents;       /* what is on the current page so far? */
-- extern scaled page_max_depth;   /* maximum box depth on page being built */
-- extern halfword best_page_break;        /* break here to get the best page known so far */
-- extern int least_page_cost;     /* the score for this currently best page */
-- extern scaled best_size;        /* its |page_goal| */


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

print('-------- LuaTeXRepl luaprompt --------')

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
input_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

file = io.open('luatexrepl-nest_row.glade', "rb") -- r read mode and b binary mode
assert(file)
nest_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

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
  InputRowClass:set_template(GLib.Bytes(input_row_xml))
  InputRowClass:bind_template_child_full('expander', false, 0)
  InputRowClass:bind_template_child_full('short_label', false, 0)
  InputRowClass:bind_template_child_full('long_label', false, 0)
  IR = nil
end

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
  return object
end
function escape_markup(text)
  return GLib.markup_escape_text(text, -1)
end

control_escapes = {}
for i=0x0,0x1F do
  control_escapes[utf8.char(i)] = utf8.char(0x2400 + i)
end
function escape_control(text)
  return text
    :gsub('\r', '↩')
    :gsub(' ', '␣')
    :gsub('%c', control_escapes)
    --:gsub('\r', '↵')
end
function escape_all(text)
  return escape_markup(escape_control(text))
end
-- TODO: font size control
function string_of_tokens(tokens, param_start, params)
  print("STRING_OF_TOK:", prompt.describe(tokens))
  if tokens == nil then return "**NIL**" end
  local start = tokens.loc or 1
  local result = ''
  for i=start,#tokens do
    local tok = tokens[i]
    if tok.cmdname == 'letter' then
      result = result .. escape_all(string.char(tok.mode))
      -- Letter
      -- return string.format(
      --   '<token %x: %s (%d) %s (%d)>',
      --   tok.tok, tok.cmdname, tok.command, string.char(tok.mode), tok.mode)
    elseif tok.cmdname == 'car_ret' then -- `car_ret`, which seems to be used for arguments
      print("CALL REC", param_start, prompt.describe(tok))
      print("PARAMS", prompt.describe(params))
      result = result .. '#' .. tok.mode
      local param = params[param_start + tok.mode]
      if param ~= nil then
        result = result .. '(' .. string_of_tokens(param, nil, nil) .. ')'
      end
    elseif tok.cmdname == 'call' then
      result = result .. '\\' .. escape_all(tok.csname) .. ' '
    else
      --assert(tok.csname == nil)
      result = result .. '\\' .. escape_all(tok.cmdname) .. ' '
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
  return '<tt>' .. result .. '</tt>'
end
function InputRow:refresh()
  print('INPUT REFRESH: ', self.index, self.markup)
  local size = token.inputstacksize()
  if self.index > size then
    self.short_label:set_text("<out-of-scope>")
  else
    local input_state = token.getinputstack(self.index)
    self.long_label:set_markup(escape_markup(prompt.describe(input_state)))
    local markup
    if input_state.tokens ~= nil then
      local short_string = string_of_tokens(input_state.tokens, input_state.limit, input_state.params)
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d]</span> %s</tt>',
        self.index, short_string)
    else
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d] %s:%d:</span> %s</tt>',
        self.index, escape_all(input_state.file), input_state.line_number, escape_all(input_state.line))
    end
    if self.markup == nil then
      self.short_label:set_markup(string.format('<span bgcolor="#FFFFAA">%s</span>', markup))
    elseif markup ~= self.markup then
      self.short_label:set_markup(string.format('<span bgcolor="#FFBBBB">%s</span>', markup))
    else
      self.short_label:set_markup(markup)
    end
    self.markup = markup
  end
  --self.short_label
  --token.inputstacksize
  --token.getinputstack
end

-- TODO: "step +10" button
-- TODO: "step k" button
-- TODO: show step counter
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

function refresh_input()
  local stack_size = token.inputstacksize()
  for i=stack_size+1,#input_rows do
    local y = input_rows[i]
    ui.input_list_box:remove(y.widget)
    input_rows[i] = nil
  end
  for i=#input_rows+1,stack_size do
    local y = InputRow:new(i)
    input_rows[i] = y
    ui.input_list_box:insert(y.widget, -1)
  end
  for i=0,stack_size do
    input_rows[i]:refresh()
  end
end

-- TODO: attach InputRow to InputRowWidget as userdata?

  --local x = InputRow:new(0)
  --ui.input_list_box:insert(x.widget, -1)

--y = InputRow:new(2)
--ui.input_list_box:insert(y.widget, -1)

--Gtk.main()

--\\directlua{require 'luatexrepl.lua'}\\xxx\\yyy a\\zzz b\\www c


NestRowWidget = LuaTeXRepl:class('NestRow', Gtk.ListBoxRow)
do
  local IR = NestRowWidget()
  NestRowClass = IR._class
  --NestRowClass = NestRow._class()
  NestRowClass:set_template(GLib.Bytes(nest_row_xml))
  NestRowClass:bind_template_child_full('expander', false, 0)
  NestRowClass:bind_template_child_full('short_label', false, 0)
  NestRowClass:bind_template_child_full('long_label', false, 0)
  IR = nil
end

NestRow = {}
function NestRow:new(index)
  local widget = NestRowWidget()
  widget:init_template()
  local object = {
    index = index,
    widget = widget,
    expander = widget:get_template_child(NestRowWidget, 'expander'),
    short_label = widget:get_template_child(NestRowWidget, 'short_label'),
    long_label = widget:get_template_child(NestRowWidget, 'long_label')
  }
  setmetatable(object, self)
  self.__index = self
  return object
end

function NestRow:refresh()
  local name
  local list
  if type(self.index) == 'string' then
    name = 'nest ' .. self.index
    list = tex.getlist(self.index)
    -- TODO: are these list nils a bug?
  else
    name = string.format("%d", self.index)
    local size = tex.getnestptr()
    if self.index > size then
      name = name .. ' <out-of-scope>'
      list = nil
    else
      list = tex.getnest(self.index).head
    end
  end
  self.short_label:set_text(name)
  local markup
  if list == nil then
    markup = '<EMPTY>'
  else
    markup = nodetree.analyze(list, {channel = 'str', color = 'no'})
  end
  markup = markup:gsub('^\n', ''):gsub('\n$', '')
  markup = escape_markup(markup)
  if self.markup == nil then
    self.long_label:set_markup(string.format('<span bgcolor="#FFFFAA">%s</span>', markup))
  elseif markup ~= self.markup then
    self.long_label:set_markup(string.format('<span bgcolor="#FFBBBB">%s</span>', markup))
  else
    self.long_label:set_markup(markup)
  end
  self.markup = markup
--self.short_label
  --token.neststacksize
  --token.getneststack
end

-- TODO: "step +10" button
-- TODO: "step until next expand" button
-- TODO: "step until smaller stack" button

nest_rows = {}

for k,v in pairs({
  'page_ins_head',
  'contrib_head',
  'page_dis',
  'split_dis',
  'page_head',
  'temp_head',
  'hold_head',
  'adjust_head',
  'best_page_brea',
  'least_page_cos',
  'best_siz',
  'pre_adjust_head',
  'align_head',}) do
  local row = NestRow:new(v)
  nest_rows[v] = row
  ui.nest_list_box:insert(row.widget, -1)
end

-- >  t = nodetree.analyze(tex.nest[1].head, {channel = 'str'})

function refresh_nest()
  local stack_size = tex.getnestptr()
  for i=stack_size+1,#nest_rows do
    local y = nest_rows[i]
    ui.nest_list_box:remove(y.widget)
    nest_rows[i] = nil
  end
  for i=#nest_rows+1,stack_size do
    local y = NestRow:new(i)
    nest_rows[i] = y
    print(i)
    print(y)
    print(y.widget)
    ui.nest_list_box:insert(y.widget, -1)
  end
  --for i=1,stack_size do
  for i,row in pairs(nest_rows) do
    nest_rows[i]:refresh()
  end
end

function refresh()
  refresh_nest()
  refresh_input()
end
refresh()

-- tex.getlist()
-- page_ins_head
-- contrib_head
-- page_head
-- hold_head
-- adjust_head
-- pre_adjust_head
-- page_discards_head
-- split_discards_head


print('-------- LuaTeXRepl GUI --------')

prompt.enter()

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
