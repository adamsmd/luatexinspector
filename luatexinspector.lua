-- luarocks install luaprompt
--
-- sudo apt install libgirepository1.0-dev
-- luarocks install lgi
--
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape --lua=luatexinspector-startup.lua luatexinspector.tex
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" luatex --shell-escape luatexinspector.tex
--
-- GTK_DEBUG=interactive PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" lualatex --shell-escape luatexinspector.tex
-- PATH=~/l/tex/luatex/texlive.svn/tags/texlive-2020.0/Master/bin/x86_64-linux:"$PATH" lualatex --shell-escape luatexinspector.tex
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


print('\n++++++++ LuaTeXInspector ++++++++')

print('++++++++ LuaTeXInspector Searchers ++++++++')
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

print('-------- LuaTeXInspector Searchers --------')

print('++++++++ LuaTeXInspector luaprompt ++++++++')
prompt = require 'prompt'

prompt.name = 'luatexinspector'

local dirsep = string.match (package.config, "[^\n]+")
local dirname = os.getenv('HOME') -- TODO: os.env?
for _k,v in pairs({'local', 'share', 'luatexinspector'}) do
  dirname = dirname .. dirsep .. v
  lfs.mkdir(dirname)
end
prompt.history = dirname .. '/history'
print('-------- LuaTeXInspector luaprompt --------')

print('++++++++ LuaTeXInspector Functions ++++++++')
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
print('-------- LuaTeXInspector Functions --------')

-- https://github.com/Josef-Friedrich/nodetree/blob/master/nodetree.lua
nodetree = require 'nodetree'
-- nodetree.analyze(list)
-- https://gist.github.com/pgundlach/556247
viznodelist = require 'viznodelist'
-- viznodelist.nodelist_visualize(box, filename, { showdisc = true })

ui = require 'luatexinspector-ui'

file = io.open('luatexinspector-input_row.ui', "rb") -- r read mode and b binary mode
assert(file)
input_row_xml = file:read "*all" -- *a or *all reads the whole file
file:close()

file = io.open('luatexinspector-nest_row.ui', "rb") -- r read mode and b binary mode
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

LuaTeXInspector = lgi.package('LuaTeXInspector')

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

function Tree.new(id, tree_view, tree_store, iter, order, auto_expand, get_data) -- TODO: __call
  local o = {
    id = id,
    tree_view = tree_view,
    tree_store = tree_store,
    iter = iter,
    order = order,
    auto_expand = auto_expand,
    get_data = get_data,
    children = {},
    text = nil,
    pixbuf = nil,
  }
  setmetatable(o, Tree)
  return o
end

function highlight_change(old, new, children_changed)
  if old == nil then
    return string.format('<span bgcolor="#BBFFBB">%s</span>', new)
  elseif old ~= new then
    return string.format('<span bgcolor="#FFBBBB">%s</span>', new)
  elseif children_changed then
    return string.format('<span bgcolor="#FFFFAA">%s</span>', new)
  else
    return new
  end
end

function Tree:refresh(k, o)
  local had_children = #self.children ~= 0
  local children_changed = false
  local old_text = self.text

  local text, pixbuf, children = self:get_data(k, o)
  self.text = text
  self.pixbuf = pixbuf

  -- Determine which children should still exists
  local child_keys = {}
  for _,child in ipairs(children) do
    child_keys[child.key] = true
  end

  -- Remove those children that shouldn't exist
  for k,v in pairs(self.children) do
    if child_keys[k] == nil then
      self.tree_store:remove(self.children[k].iter)
      self.children[k] = nil
      children_changed = true
    end
  end

  -- Check all children that should exist
  for i = 1,#children do
    local child = children[i]
    local k = child.key
    local v = child.value
    -- Add missing children
    if self.children[k] == nil then
      self.children[k] = Tree.new(
        self.id .. ':' .. k,
        self.tree_view,
        self.tree_store,
        self.tree_store:append(self.iter, { nil, nil, nil, nil }),
        i,
        child.auto_expand,
        child.get_data)
      -- Expand row if children are new and auto_expand is true
      if not had_children and self.auto_expand and self.iter ~= nil then
        self.tree_view:expand_row(self.tree_store:get_path(self.iter), false)
      end
      children_changed = true
    end
    -- Refresh children
    children_changed = self.children[k]:refresh(k, v) or children_changed
    --child[new] = old
    indices = self.tree_store:get_path(self.children[k].iter):get_indices()
    index = indices[#indices]
  end
  --Gtk.TreeStore.reoder(self.tree_store:reorder(self.iter, order)

  -- Update own tree node
  if self.iter ~= nil then
    self.tree_store:set(
      self.iter, { self.id, self.order, highlight_change(old_text, self.order .. ':' .. text, children_changed), pixbuf })
  end

  return children_changed or old_text ~= text
end

function input_state_root_get_data(self, k, o)
  return nil, nil, ranged_children(0, token.inputstacksize(), false, input_state_get_data)
end

function comp_keys(o1, o2)
  local key1, key2 = o1.key, o2.key
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

function ranged_children(start, stop, auto_expand, get_data)
  local children = {}
  for i = start,stop do
    children[#children + 1] = { key = i, value = i, auto_expand = auto_expand, get_data = get_data }
  end
  return children
end

function sorted_children(t, auto_expand, get_data)
  local children = {}
  for k,v in pairs(t) do
    children[#children + 1] = { key = k, value = v, auto_expand = auto_expand, get_data = get_data }
  end
  table.sort(children, comp_keys)
  return children
end

function input_state_get_data(self, k, o)
  local size = token.inputstacksize()
  if o > size then
    return 'ERROR: OUT OF SCOPE', nil, nil, {}
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
    return markup, nil, sorted_children(input_state, true, default_get_data)
  end
end

function default_get_data(self, k, o)
  local function scalar(s)
    return k .. '[' .. type(s) .. ']: ' .. escape_markup(tostring(s)), nil, {}
  end
  local t = type(o)
  if t == 'string' then
    return scalar('"' .. o .. '"')
  elseif t == 'table' then
    return k, nil, sorted_children(o, true, default_get_data)
  else
    return scalar(o)
  end
end

-- END TREE

-- #define prev_depth_par                     cur_list.prev_depth_field
-- #define prev_graf_par                      cur_list.pg_field
-- #define tail_par                           cur_list.tail_field
-- #define head_par                           cur_list.head_field
-- #define mode_par                           cur_list.mode_field
-- #define dirs_par                           cur_list.dirs_field
-- #define space_factor_par                   cur_list.space_factor_field
-- #define incompleat_noad_par                cur_list.incompleat_noad_field
-- #define mode_line_par                      cur_list.ml_field

-- #define aux_par                            cur_list.eTeX_aux_field
-- #define delim_par                          aux_par


-- mode
-- head
-- tail
-- prevgraf pg_field
-- modeline ml_field

-- 3 prevdepth

-- delimptr eTeX_aux_field
-- spacefactor
-- noad
-- dirs
-- mathdir
-- mathstyle

-- TODO: 'nil' values are appearing as always new

node_types = node.types()
whatsit_types = node.whatsits()
function node_get_data(self, k, n)
  local node_type = node_types[n.id]
  local subtype = nil
  if node_type == 'whatsit' then
    subtype = whatsit_types[n.subtype]
  elseif node.subtypes(n.id) ~= nil then
    subtype = node.subtypes(n.id)[n.subtype]
  end

  return
    string.format(
      '<tt><span fgcolor="#808080">[%d]</span> %s %s %s</tt>',
      k, node_type, subtype, escape_markup(tostring(n))),
    nil, {}
end

function node_list_get_data(self, k, node)
  -- node.type(1) == 'vlist'
  -- node.type(node) = 'vlist'
  -- node.types() node.whatsits()
  -- node.fields(1)
  -- node.values('dir')
  -- node.subtypes(1)
  -- get_field_whatsit
  -- node_data[]
  -- print(prompt.describe(node.fields('whatsit', 'pdf_literal')))
  local children = {}
  local iter = node
  while iter ~= nil do
    children[#children + 1] = { key = #children + 1, value = iter, auto_expand = true, get_data = node_get_data }
    iter = iter.next
  end
  return tostring(k), nil, children
end

function nest_stack_get_data(self, k, nest_index)
  local nest = tex.getnest(nest_index)

  local children = {
    { key = 'mode', value = modenames[nest.mode], auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'delimptr', value = nest.delimptr, auto_expand = true, get_data = default_get_data }, -- node
    { key = 'prevgraf', value = nest.prevgraf, auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'modeline', value = nest.modeline, auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'prevdepth', value = nest.prevdepth, auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'spacefactor', value = nest.spacefactor, auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'noad', value = nest.noad, auto_expand = true, get_data = default_get_data }, -- node
    { key = 'dirs', value = nest.dirs, auto_expand = true, get_data = default_get_data }, -- node
    { key = 'mathdir', value = nest.mathdir, auto_expand = true, get_data = default_get_data }, -- boolean
    { key = 'mathstyle', value = nest.mathstyle, auto_expand = true, get_data = default_get_data }, -- integer
    { key = 'head', value = nest.head, auto_expand = true, get_data = node_list_get_data }, -- node
    --{ key = 'tail', value = nest.head, auto_expand = true, get_data = default_get_data }, -- node
  }


  -- local children = {
  --   mode = nest.mode, -- negative indicate inner and inline variants
  --   modeline = nest.modeline, -- source input line where this mode was entered in, negative inside the output routine
  --   prevgraf = nest.prevgraf, --  number of lines in the previous paragraph
  -- }
  -- local modename = tex.getmodevalues()[math.abs(nest.mode)]
  -- if modename == "vertical" then
  --   children.prevdepth = nest.prevdepth -- depth of the previous paragraph
  --   -- <=-1000 (if exempt from baseline calc)
  -- elseif modename == 'horizontal' then
  --   children.spacefactor = nest.prevdepth -- (num)
  --   children.dirs = nest.dirs -- (node) temp storage by line break algorithm
  -- elseif modename == 'math' then
  --   children.noad = nest.prevdepth -- used for temporary storage of a pending fraction numerator, for \over etc
  --   children.delimptr = nest.delimptr -- used for temporary storage of the previous math delimiter, for \middle
  --   children.mathdir = nest.mathdir -- true when during math processing the \mathdir is not the same as the surrounding \textdir
  --   children.mathstyle = nest.mathstyle -- num
  -- else
  --   error() -- TODO: raise error
  -- end
  --local info = sorted_children(children, true, default_get_data)

  --local list = nest.head
  return 'nest[' .. k .. ']', nil, children
end

function next_stack_root_get_data(self, k, o)
  return 'Nest Stack', nil, ranged_children(0, tex.getnestptr(), true, nest_stack_get_data)
end

-- Special list heads

function special_lists_get_data(self, k, o)
  local children = {}
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
    children[#children + 1] = { key = v, value = tex.getlist(v), auto_expand = true, get_data = node_list_get_data }
  end

  return 'Special Lists', nil, children
end

function node_tree_root_get_data(self, k, o)
  local page_head = tex.getlist('page_head')
  local children = {
    { key = 'special_lists', value = page_head, auto_expand = true, get_data = special_lists_get_data },
    { key = 'nest_stack', value = nil, auto_expand = true, get_data = next_stack_root_get_data },
  }
  return nil, nil, children
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

print('-------- Input Stack --------')

print('++++++++ Nest Stack ++++++++')
NestRowWidget = LuaTeXInspector:class('NestRow', Gtk.ListBoxRow)
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

ORDER_COLUMN = 1

function order_sort_func(model, iter1, iter2)
  local value1 = model:get_value(iter1, ORDER_COLUMN).value
  local value2 = model:get_value(iter2, ORDER_COLUMN).value
  if value1 < value2 then return -1
  elseif value1 > value2 then return 1
  else return 0 end
end

ui.input_tree_store:set_default_sort_func(order_sort_func)
--ui.input_tree_store:set_sort_column_id(ORDER_COLUMN, Gtk.TreeSortable.DEFAULT_SORT_COLUMN_ID)
--ui.input_tree_store:set_sort_column_id(ORDER_COLUMN, 4294967295)
ui.input_tree_store:set_sort_column_id(Gtk.TreeSortable.DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING)

input_tree = Tree.new('input_stack', ui.input_tree_view, ui.input_tree_store, nil, nil, true, input_state_root_get_data)
node_tree = Tree.new('node_tree', ui.node_tree_view, ui.node_tree_store, nil, nil, true, node_tree_root_get_data)

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

if true then
  prompt.enter()
else
  run()
end

print('-------- LuaTeXInspector --------')

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
