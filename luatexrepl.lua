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
-- function peek_next(count)
--   if count == nil then
--     return peek_next(1)[1]
--   end

--   local toks = {}

--   for i=1,count,1 do
--     toks[i] = token.get_next()
--   end

--   for i=count,1,-1 do
--     token.put_next(toks[i])
--   end

--   return toks
-- end

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
-- local expandafter_token = token.create("expandafter")
-- local relax_token = token.create("relax")
-- function expand()
--   token.put_next(expandafter_token, relax_token)
--   token.scan_token() -- Triggers the expansion and reads back the \relax token
--   -- TODO: fix undefined_cs?
-- end
print('-------- LuaTeXRepl Functions --------')

-- https://github.com/Josef-Friedrich/nodetree/blob/master/nodetree.lua
nodetree = require 'nodetree'
-- nodetree.analyze(list)
-- https://gist.github.com/pgundlach/556247
viznodelist = require 'viznodelist'
-- viznodelist.nodelist_visualize(box, filename, { showdisc = true })

ui = require 'luatexrepl-ui'

file = io.open('luatexrepl-input_row.ui', "rb") -- r read mode and b binary mode
assert(file)
input_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

file = io.open('luatexrepl-nest_row.ui', "rb") -- r read mode and b binary mode
assert(file)
nest_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

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

LuaTeXRepl = lgi.package('LuaTeXRepl')

-- Ctrl-C = Gtk.main_quit()
print('++++++++ Input Stack ++++++++')
function prime()
  if expandable == nil then
    token.put_next(token.get_next())
    refresh()
  end
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
-- TODO: Gtk has no way to select text in a tree view (put it in a separate label?)
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
    if tok.expandable then
      tok_string = '<u><span fgcolor="#008800">' .. tok_string .. '</span></u>'
    end
    result = result .. tok_string
  end
  return result
end

-- START TREE

-- TODO: larger view of pixbuf of selected node in a separate panel
Tree = {}
Tree.__index = Tree

function Tree.new(id, tree_store, iter, get_data) -- TODO: __call
  local o = {
    id = id,
    tree_store = tree_store,
    iter = iter,
    get_data = get_data,
    children = {},
    text = nil,
    pixbuf = nil,
  }
  setmetatable(o, Tree)
  return o
end
--iter = ui.input_tree_store:get_iter_from_string(0)
--tree = Tree.new('uninit', ui.input_tree_store, nil, input_state_root_get_data)
--tree:refresh('root', nil)

function highlight_change(old, new, child_changed)
  if old == nil then
    return string.format('<span bgcolor="#BBFFBB">%s</span>', new)
  elseif old ~= new then
    return string.format('<span bgcolor="#FFBBBB">%s</span>', new)
  elseif child_changed then
    return string.format('<span bgcolor="#FFFFAA">%s</span>', new)
  else
    return new
  end
end

function Tree:refresh(k, o)
  local old_text = self.text
print('refresh', k, v, self)
  local text, pixbuf, children_o, keys, child_get_data = self:get_data(k, o)
  self.text = text
  self.pixbuf = pixbuf

  local child_changed = false
  for k,v in pairs(self.children) do
    if children_o[k] == nil then
      self.tree_store:remove(self.children[k].iter)
      self.children[k] = nil
      child_changed = true
    end
  end
  for _,k in ipairs(keys) do
    local v_o = children_o[k]
    if self.children[k] == nil then
      self.children[k] = Tree.new(
        self.id .. ':' .. k,
        self.tree_store,
        self.tree_store:append(self.iter, { nil, nil, nil }),
        child_get_data(k, v_o))
      child_changed = true
    end
    child_changed = self.children[k]:refresh(k, v_o) or child_changed
  end

  if self.iter ~= nil then
    self.tree_store:set(self.iter, { self.id, highlight_change(old_text, text, child_changed), pixbuf })
  end

  return child_changed or old_text ~= text
end

function input_state_root_get_data(self, k, o)
  local size = token.inputstacksize()
  local children = {}
  for i = 0,size do
    children[i] = i
  end
  return nil, nil, children, sorted_keys(children), function (_, _) return input_state_get_data end
end

function comp_keys(key1, key2)
  local type1, type2 = type(key1), type(key2)
  if type1 ~= type2 then
    if type1 == 'number' and type2 == 'string' then
      return false
    elseif type1 == 'string' and type2 == 'number' then
      return true
    else
      assert(false, ('type1: %s type2: %s'):format(type1, type2))
    end
  else
    return key1 < key2
  end
end

function sorted_keys(t)
  local keys = {}
  for k,_ in pairs(t) do
    keys[#keys+1] = k
  end
  table.sort(keys, comp_keys)
  return keys
end

function input_state_get_data(self, k, o)
  local size = token.inputstacksize()
  if o > size then
    return 'ERROR: OUT OF SCOPE', nil, {}
  else
    local input_state = token.getinputstack(o)
    local markup
    if input_state.tokens ~= nil then
      local short_string = string_of_tokens(input_state.tokens, input_state.limit, input_state.params)
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d]</span> %s</tt>',
        o, short_string)
    else
      markup = string.format(
        '<tt><span fgcolor="#808080">[%d] %s:%d:</span> %s</tt>',
        o, escape_all(input_state.file), input_state.line_number, escape_all(input_state.line))
    end
    return markup, nil, input_state, sorted_keys(input_state), function (_, _) return default_get_data end
  end
end

function default_get_data(self, k, o)
  local function scalar(s)
    return k .. ' = ' .. type(s) .. ': ' .. escape_markup(tostring(s)), nil, {}, {}, nil
  end
  local t = type(o)
  if t == 'string' then
    return scalar('"' .. o .. '"')
  elseif t == 'table' then
    return k, nil, o, sorted_keys(o), function (_, _) return default_get_data end
  else
    return scalar(o)
  end
end

-- END TREE
function nest_stack_get_data(self, k, o)
  local children = {}
  local nest = tex.getnest(self.index)
  --local list = nest.head
  return '#' .. k, nil, nest, sorted_keys(children), function (_, _) return default_get_data end
end

function next_stack_root_get_data(self, k, o)
  local size = tex.getnestptr()
  local children = {}
  for i = 1,size do
    children[i] = i
  end
  return 'Nest Stack', nil, children, sorted_keys(children), function (_, _) return nest_stack_get_data end
end

-- TODO: sort function instead of list of child orders
function node_list_root_get_data(self, k, o)
  local children = { nest_stack = next_stack_root_get_data }
  return nil, nil, children, { 'nest_stack' }, function (_, v) return v end
end

  -- ui.input_tree_store:set(i, {...})
  -- ui.input_tree_store:get_value(self, 0).value
  -- ui.input_tree_store:set_value(self, 0, GObject.Value(GObject.Type.STRING, "abc"))

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
-- TODO: STEP-Expand* 
-- TODO: rename to luatexinspector

print('-------- Input Stack --------')

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

input_tree = Tree.new('input_stack', ui.input_tree_store, nil, input_state_root_get_data)
node_tree = Tree.new('node_list', ui.node_tree_store, nil, node_list_root_get_data)

function refresh()
  refresh_nest()
  node_tree:refresh('root', nil)
  input_tree:refresh('root', nil)

  -- TODO: proper expand test
  local stack_size = token.inputstacksize()
  expandable = nil
  for i=stack_size,0,-1 do
    local input_state = token.getinputstack(i)
    local tokens = input_state.tokens
    if tokens ~= nil then
      local start = tokens.loc or 1
      for j=start,#tokens do
        local tok = tokens[j]
        if tok.cmdname ~= 'car_ret' then
          expandable = expandable or (tok.expandable and 1 or 0)
        end
      end
    end
  end
  ui.prime_button.sensitive = expandable == nil
  ui.expand_button.sensitive = expandable ~= 0 -- TODO: == 1
  ui.expand_many_button.sensitive = expandable ~= 0
end
refresh()

if false then
  prompt.enter()
else
  run()
end

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
