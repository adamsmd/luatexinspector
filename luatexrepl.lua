-- luarocks install luaprompt
--
-- sudo apt install libgirepository1.0-dev
-- luarocks install lgi
--
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape --lua=luatexrepl-startup.lua luatexrepl.tex
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape luatexrepl.tex
--
-- GTK_DEBUG=interactive PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" lualatex --shell-escape luatexrepl.tex
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
GLib = lgi.GLib
GObject = lgi.GObject
Gdk = lgi.Gdk
Gtk = lgi.Gtk
GtkSource = lgi.GtkSource
--Gtk = lgi.require 'Gtk'
--GLib = lgi.require 'GLib'
--assert = lgi.assert
-- dump(Gtk.Widget:_resolve(true), 3)

-- Trigger a "type register" of GtkSource.View.
-- I don't know why this triggers it, but it does.
-- Must happen before loading the builder file.
GtkSource.View {}


builder = Gtk.Builder()
-- TODO: assert/error checking
builder:add_from_file('luatexrepl.ui')

ui = builder.objects

LuaTeXRepl = lgi.package('LuaTeXRepl')

file = io.open('luatexrepl-input_row.ui', "rb") -- r read mode and b binary mode
assert(file)
input_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

file = io.open('luatexrepl-nest_row.ui', "rb") -- r read mode and b binary mode
assert(file)
nest_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

-- Create top level window with some properties and connect its 'destroy'
-- signal to the event loop termination.
window = ui.window
print('WINDOW', window)
-- Icons:
--   document-page-setup
--   text-x-generic-templpate
--   text-x-script

-- Create some more widgets for the window.
statusbar = ui.statusbar
statusbar_ctx = statusbar:get_context_id('default')
statusbar:push(statusbar_ctx, 'This is statusbar message.')

input = ui.input_source_view
output = ui.output_source_view

input.buffer.language = GtkSource.LanguageManager.get_default():get_language('lua')
--output.buffer.language = GtkSource.LanguageManager.get_default():get_language('lua')

scheme = GtkSource.StyleSchemeManager.get_default():get_scheme('cobalt')
input.buffer:set_style_scheme(scheme)
output.buffer:set_style_scheme(scheme)

function append_output(text, tag)
  -- Append the text.
  local end_iter = output.buffer:get_end_iter()
  local offset = end_iter:get_offset()
  output.buffer:insert(end_iter, text, -1)
  end_iter = output.buffer:get_end_iter()

  -- Apply proper tag.
  tag = output.buffer.tag_table.tag[tag]
  if tag then
    output.buffer:apply_tag(tag, output.buffer:get_iter_at_offset(offset), end_iter)
  end

  -- Scroll so that the end of the buffer is visible, but only in
  -- case that cursor is at the very end of the view.  This avoids
  -- autoscroll when user tries to select something in the output
  -- view.
  -- local cursor = output.buffer:get_iter_at_mark(output.buffer:get_insert())
  -- if end_iter:get_offset() == cursor:get_offset() then
  --   output:scroll_mark_onscreen(output_end_mark)
  -- end
end

-- Execute Lua command from entry and log result into output.
function execute()
  -- Get contents of the entry.
  local text = input.buffer.text:gsub('^%s?(=)%s*', 'return ')
  if text == '' then return end

  -- Add command to the output view.
  append_output(text:gsub('\n*$', '\n', 1), 'command')

  -- Try to execute the command.
  local chunk, answer = (loadstring or load)(text, '=stdin')
  local tag = 'error'
  if not chunk then
      answer = answer:gsub('\n*$', '\n', 1)
  else
      (function(ok, ...)
          if not ok then
            answer = tostring(...):gsub('\n*$', '\n', 1)
          else
            -- Stringize the results.
            answer = {}
            for i = 1, select('#', ...) do
                answer[#answer + 1] = tostring(select(i, ...))
            end
            answer = #answer > 0 and table.concat(answer, '\t') .. '\n'
            tag = 'result'
          end
      end)(pcall(chunk))
  end

  -- Add answer to the output pane.
  if answer then append_output(answer, tag) end

  if tag == 'error' then
      -- Try to parse the error and find line to place the cursor
      local line = answer:match('^stdin:(%d+):')
      if line then
        input.buffer:place_cursor(input.buffer:get_iter_at_line_offset(line - 1, 0))
      end
  else
      -- -- Store current text as the last item in the history, but
      -- -- avoid duplicating items.
      -- history[#history] = (history[#history - 1] ~= text) and text or nil

      -- -- Add new empty item to the history, point position to it.
      -- history.position = #history + 1
      -- history[history.position] = ''

      -- -- Enable/disable history navigation actions.
      -- actions.up.sensitive = history.position > 1
      -- actions.down.sensitive = false

      -- Clear contents of the entry buffer.
      input.buffer.text = ''
  end
end


-- Intercept assorted keys in order to implement history
-- navigation.  Ideally, this should be implemented using
-- Gtk.BindingKey mechanism, but lgi still lacks possibility to
-- derive classes and install new signals, which is needed in order
-- to implement this.
local keytable = {
  [Gdk.KEY_Return] = execute,
  --[Gdk.KEY_Up] = actions.up,
  --[Gdk.KEY_Down] = actions.down,
}

function input:on_key_press_event(event)
  -- Lookup action to be activated for specified key combination.
  local action = keytable[event.keyval]
  local state = event.state
  local without_control = not state.CONTROL_MASK 
  if not action or state.SHIFT_MASK
      --or actions.multiline.active == without_control
      then
      return false
  end

  -- Ask textview whether it still wants to consume the key.
  if self:im_context_filter_keypress(event) then return true end

  -- Activate specified action.
  action()

  -- Do not continue distributing the signal to the view.
  return true
end

-- Override global 'print' and 'io.write' handlers, so that output
-- goes to our output window (with special text style).
function buffer_print(...)
  local outs = {}
  for i = 1, select('#', ...) do
    outs[#outs + 1] = tostring(select(i, ...))
  end
  append_output(table.concat(outs, '\t') .. '\n', 'log')
end

function buffer_write(...)
  for i = 1, select('#', ...) do
    append_output(select(i, ...), 'log')
  end
end

function run()
  local old_print = print
  local old_write = io.write
  _G.print = buffer_print
  _G.io.write = buffer_write
  Gtk.main()
  -- Revert to old printing routines.
  print = old_print
  io.write = old_write
end

function window:on_destroy()
  Gtk.main_quit()
end

function ui.file_quit_menu_item:on_activate()
  window:destroy()
end

function ui.prime_button:on_clicked()
  prime()
end
-- TODO: colors based on non-priming refresh

function ui.step_button:on_clicked()
  local result = tex.execute()
  ui.step_button.sensitive = result
  refresh()
end

function ui.expand_button:on_clicked()
  tex.expand()
  refresh()
end
-- TODO: wavey line when can't determine if expand is safe

function ui.expand_many_button:on_clicked()
  prime()
  while expandable ~= 0 do
    tex.expand()
    refresh()
    prime()
  end
end

function ui.refresh_button:on_clicked()
  refresh()
end

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
print('++++++++ Input Stack ++++++++')
function prime()
  if expandable == nil then
    print('PRIMED')
    token.put_next(token.get_next())
    refresh()
  end
end
InputRowWidget = LuaTeXRepl:class('InputRow', Gtk.ListBoxRow)
do
  local IR = InputRowWidget()
  InputRowClass = IR._class
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
  return
    '<span show="line-breaks|ignorables">'
    .. text
      :gsub('\r', '↩')
      :gsub('\n', '↵')
      :gsub(' ', '␣')
      :gsub('%c', control_escapes)
    .. '</span>'
end
function escape_all(text)
  return escape_control(escape_markup(text))
end

-- TODO: font size control
-- TODO: show box registers
-- TODO: show disc_ptr
-- TODO: step history
expandable = nil -- NOTE: "nil | 0 | 1" not "true | false"
--unvbox @outputbox

-- box type list_ptr SHIPPING_PAGE pagebox pre_box set_box sub_box
-- tex/equivalents.h:#define box(A)       equiv(box_base+(A))
-- tex.getbox
-- >  tex.box['@outputbox']
--@cclv
--to\@colht
--@texttop

-- BUG IN PANGO MARKUP:
-- The following renders the spaces between "a" and "b"
-- as well as "e" and "f", when it shouldn't.
--    a b<span show="spaces">c d</span>e f
-- For some reason some tags like <u> prevent this:
--    a b<u>x</u><span show="spaces">c d</span><u>y</u>e f

letter_cmds = {
  char_num = true,
  letter = true,
  other_char = true,
  --char_given = true,
  run_char_num_mmode = true,
  run_math_char_num_mmode = true,
} -- TODO: others?
function string_of_tokens(tokens, param_start, params)
  if tokens == nil then return "ERROR: NIL" end
  local start = tokens.loc or 1
  local result = ''
  for i=start,#tokens do
    local tok = tokens[i]
    local tok_string
    if letter_cmds[tok.cmdname] ~= nil then
      tok_string = escape_all(string.char(tok.mode))
      -- Letter
      -- return string.format(
      --   '<token %x: %s (%d) %s (%d)>',
      --   tok.tok, tok.cmdname, tok.command, string.char(tok.mode), tok.mode)
    elseif tok.cmdname == 'left_brace' then
      tok_string = '{'
    elseif tok.cmdname == 'right_brace' then
      tok_string = '}'
    elseif tok.cmdname == 'car_ret' then -- `car_ret` = out_param_cmd, which is used for arguments
      tok_string = '#' .. tok.mode
      local param = params[param_start + tok.mode]
      if param ~= nil then
        tok_string = tok_string .. '(' .. string_of_tokens(param, nil, nil) .. ')'
      end
    elseif tok.csname ~= nil then
      tok_string = '\\' .. escape_all(tok.csname) .. ' '
    else
      --assert(tok.csname == nil)
      tok_string = '\\' .. escape_all(tok.cmdname) .. ' '
      -- -- Non-letter
      -- return string.format(
      --   '<token %x: %s (%d) %s [%d] %s%s%s>',
      --   tok.tok, tok.cmdname, tok.command, tok.csname, tok.mode,
      --   tok.active     and 'A' or '-',
      --   tok.expandable and 'E' or '-',
      --   tok.protected  and 'P' or '-')
    --end
    end
    if tok.cmdname ~= 'car_ret' then
      expandable = expandable or (tok.expandable and 1 or 0)
    end
    if tok.expandable then
      tok_string = '<u><span fgcolor="#008800">' .. tok_string .. '</span></u>'
    end
    result = result .. tok_string
  end
  return result
end

function InputRow:refresh()
  local size = token.inputstacksize()
  if self.index > size then
    self.short_label:set_text("ERROR: OUT OF SCOPE")
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
end

-- TODO: larger view of pixbuf of selected node in a separate panel

-- Tree = {}
-- Tree.__index = Tree

-- function Tree.__call(tree_store, get_text, get_pixbuf, get_children)
-- end

-- function changed(old, new)
--   if old == nil then
--     return string.format('<span bgcolor="#FFFFAA">%s</span>', new)
--   elseif old ~= new then
--     return string.format('<span bgcolor="#FFBBBB">%s</span>', new)
--   else
--     return new
--   end
-- end

-- function Tree:add_child(k, o)
--   local iter = self.tree_store:append(self.iter, { nil, nil, nil })
--   local tree = Tree(self.id .. ':' .. k, self.tree_store, iter, get_text_key(k))
--   self.fields[k] = tree
--   tree:refresh(o)
--   return tree
-- end

-- function Tree:delete_child(k)
--   self.tree_store:remove(self.children[k].iter)
--   self.children[k] = nil
-- end

-- function Tree:refresh(o, k)
--   local old_text = self.text

--   local text, pixbuf, children_o = self:get_data(o, k)
--   self.text = text
--   self.pixbuf = pixbuf

--   self.tree_store:set(self.iter, { self.id, changed(old_text, text), pixbuf })

--   for k,v in pairs(self.children) do
--     if children_o[k] == nil then
--       self:delete_child(k)
--     end
--   end
--   for k,v_o in pairs(children) do
--     if self.children[k] == nil then
--       self:add_child(k, v_o)
--     else
--       self.children[k]:refresh(v_o)
--     end
--   end
-- end

-- function input_state_get_data(self, o, )
--   local size = token.inputstacksize()
--   if self.input_ptr > size then
--     return 'ERROR: OUT OF SCOPE', nil, {}
--   else
--     local input_state = token.getinputstack(self.input_ptr)
--     local markup
--     if input_state.tokens ~= nil then
--       local short_string = string_of_tokens(input_state.tokens, input_state.limit, input_state.params)
--       markup = string.format(
--         '<tt><span fgcolor="#808080">[%d]</span> %s</tt>',
--         self.input_ptr, short_string)
--     else
--       markup = string.format(
--         '<tt><span fgcolor="#808080">[%d] %s:%d:</span> %s</tt>',
--         self.input_ptr, escape_all(input_state.file), input_state.line_number, escape_all(input_state.line))
--     end
--     return markup, nil, input_state
--   end
-- end

-- function default_get_data(self, o, k)
--   if type(o) == 'string' then
--     return k .. ' = ' .. o, nil, {}
--   elseif .. then
--   else
--     return k .. ' = UNKNOWN(' .. type(o) .. ')', nil, {}
--   end
-- end

InputState = {}
InputState.__index = InputState

function InputState.__call(input_ptr, tree_iter)
   local o = {}
   setmetatable(o, InputState)
   o.tree_iter = tree_iter
   o.input_ptr = input_ptr
   o.markup = markup
   return o
end

function InputState:refresh()
  -- ui.input_tree_store:set(i, {...})
  -- ui.input_tree_store:get_value(self, 0).value
  -- ui.input_tree_store:set_value(self, 0, GObject.Value(GObject.Type.STRING, "abc"))
  local size = token.inputstacksize()
  if self.input_ptr > size then
    ui.input_tree_store:set(self, { 'id', 'ERROR: OUT OF SCOPE', nil })
  else
    local input_state = token.getinputstack(self.input_ptr)
    --self.long_label:set_markup(escape_markup(prompt.describe(input_state)))
    local markup
    if input_state.tokens ~= nil then
      local short_string = string_of_tokens(input_state.tokens, input_state.limit, input_state.params)
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d]</span> %s</tt>',
        self.input_ptr, short_string)
    else
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d] %s:%d:</span> %s</tt>',
        self.input_ptr, escape_all(input_state.file), input_state.line_number, escape_all(input_state.line))
    end
    local colored_markup
    if self.markup == nil then
      colored_markup = string.format('<span bgcolor="#FFFFAA">%s</span>', markup)
    elseif markup ~= self.markup then
      colored_markup = string.format('<span bgcolor="#FFBBBB">%s</span>', markup)
    else
      colored_markup = markup
    end
    ui.input_tree_store:set_value(self, 0, GObject.Value(GObject.Type.STRING, colored_markup))
    self.markup = markup
  end
end

-- TODO: "step +10" button
-- TODO: "step k" button
-- TODO: show step counter
-- TODO: "step until next expand" button
-- TODO: "step until smaller stack" button
-- TODO: "expand all" button
-- TODO: "expand and step" button
-- TODO: show "last command"
-- TODO: disable expand button
-- TODO: check box for whether to show parameters inline
-- TODO: STEP-Expand* button

input_rows = {}
input_tree = {}

do
  local y = InputRow:new(0)
  input_rows[0] = y
  ui.input_list_box:insert(y.widget, -1)

  local z = ui.input_tree_store:append(nil, { '0', 'UNINITIALIZED', nil })
  input_tree[0] = z
end
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
  expandable = nil
  for i=stack_size,0,-1 do
    input_rows[i]:refresh()
  end
  ui.prime_button.sensitive = expandable == nil
  ui.expand_button.sensitive = expandable ~= 0 -- TODO: == 1
  ui.expand_many_button.sensitive = expandable ~= 0
end

-- i1 = ui.treestore:append(nil, { "id", "<b>text</b>", nil})
-- i2 = ui.treestore:append(i1, { "id2", "test2", nil})

print('-------- Input Stack --------')

-- TODO: attach InputRow to InputRowWidget as userdata?

--Gtk.main()

print('++++++++ Nest Stack ++++++++')
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
    name = string.format('[%s]', self.index)
    list = tex.getlist(self.index)
    -- TODO: are these list nils a bug?
  elseif self.index <= 0 then
    name = string.format("[box #%d]", -self.index)
    list = tex.getbox(-self.index)
  else
    name = string.format("[node stack #%d]", self.index)
    local size = tex.getnestptr()
    if self.index > size then
      name = name .. ' ERROR: OUT OF SCOPE'
      list = nil
    else
      list = tex.getnest(self.index).head
    end
  end
  -- TODO: put length (first node?) in header
  self.short_label:set_text(name)
  local markup
  if list == nil then
    markup = '<empty>'
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
-- TODO: shipout callback

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
box_rows = {}

-- >  t = nodetree.analyze(tex.nest[1].head, {channel = 'str'})

function refresh_nest()
  local stack_size = tex.getnestptr()
  for k,v in pairs(box_rows) do
    local y = box_rows[k]
    ui.nest_list_box:remove(y.widget)
    box_rows[k] = nil
  end
  for i=stack_size+1,#nest_rows do
    local y = nest_rows[i]
    ui.nest_list_box:remove(y.widget)
    nest_rows[i] = nil
  end
  for i=#nest_rows+1,stack_size do
    local y = NestRow:new(i)
    nest_rows[i] = y
    ui.nest_list_box:insert(y.widget, -1)
  end
  for i=0,65535 do
    if tex.getbox(i) ~= nil then
      local y = NestRow:new(-i)
      box_rows[i] = y
      ui.nest_list_box:insert(y.widget, -1)
    end
  end
  for k,row in pairs(nest_rows) do
    row:refresh()
  end
  for k,row in pairs(box_rows) do
    row:refresh()
  end
end
print('-------- Nest Stack --------')

function refresh()
  refresh_nest()
  refresh_input()
end
refresh()

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
