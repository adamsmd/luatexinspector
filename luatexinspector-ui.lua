print('++++++++ LuaTeXInspector UI ++++++++')

-- https://github.com/nymphium/lua-graphviz
-- https://github.com/hleuwer/luagraph
-- http://siffiejoe.github.io/lua-microscope/

-- https://github.com/hishamhm/tabular
-- https://github.com/kikito/inspect.lua

-- https://github.com/pavouk/lgi/blob/master/samples/gtk-demo/demo-treeview-editable.lua

lgi = require 'lgi'

GObject = lgi.GObject
GLib = lgi.GLib
Gdk = lgi.Gdk
Gtk = lgi.Gtk
GtkSource = lgi.GtkSource
--assert = lgi.assert
-- dump(Gtk.Widget:_resolve(true), 3)

-- Trigger a "type register" of GtkSource.View.
-- I don't know why this triggers it, but it does.
-- Must happen before loading the builder file.
GtkSource.View {}

local builder = Gtk.Builder()
-- TODO: assert/error checking
builder:add_from_file('luatexinspector.ui')

ui = builder.objects

-- Create top level window with some properties and connect its 'destroy'
-- signal to the event loop termination.
local window = ui.window
-- Icons:
--   document-page-setup
--   text-x-generic-templpate
--   text-x-script

-- Create some more widgets for the window.
local statusbar = ui.statusbar
statusbar_ctx = statusbar:get_context_id('default')
statusbar:push(statusbar_ctx, 'This is statusbar message.')

local input = ui.input_source_view
local output = ui.output_source_view

-- Define history buffer and operations with it.
local history = { '', position = 1 }
local function history_select(new_position)
  history[history.position] = input.buffer.text
  history.position = new_position
  input.buffer.text = history[history.position]
  input.buffer:place_cursor(input.buffer:get_end_iter())
  --actions.up.sensitive = history.position > 1
  --actions.down.sensitive = history.position < #history
end

-- History navigation actions.
local function up_arrow()
  history_select(history.position - 1)
end
local function down_arrow()
  history_select(history.position + 1)
end

input.buffer.language = GtkSource.LanguageManager.get_default():get_language('lua')
--output.buffer.language = GtkSource.LanguageManager.get_default():get_language('lua')

local scheme = GtkSource.StyleSchemeManager.get_default():get_scheme('cobalt')
input.buffer:set_style_scheme(scheme)
output.buffer:set_style_scheme(scheme)

local output_end_mark = output.buffer:create_mark(nil, output.buffer:get_end_iter(), false)
local function append_output(text, tag)
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
  local cursor = output.buffer:get_iter_at_mark(output.buffer:get_insert())
  if end_iter:get_offset() == cursor:get_offset() then
    output:scroll_mark_onscreen(output_end_mark)
  end
end

-- Execute Lua command from entry and log result into output.
local function execute()
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

local input_position_label = ui.input_position_label
-- Change indicator text when position in the entry changes.
input.buffer.on_notify['cursor-position'] = function(buffer)
  local iter = buffer:get_iter_at_mark(buffer:get_insert())
  input_position_label.label = string.format('%d:%d', iter:get_line() + 1, iter:get_line_offset() + 1)
end



-- Intercept assorted keys in order to implement history
-- navigation.  Ideally, this should be implemented using
-- Gtk.BindingKey mechanism, but lgi still lacks possibility to
-- derive classes and install new signals, which is needed in order
-- to implement this.
local keytable = {
  [Gdk.KEY_Return] = execute,
  [Gdk.KEY_Up] = up_arrow,
  [Gdk.KEY_Down] = down_arrow,
}

--   console.entry.has_focus = true

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
local function buffer_print(...)
  local outs = {}
  for i = 1, select('#', ...) do
    outs[#outs + 1] = tostring(select(i, ...))
  end
  append_output(table.concat(outs, '\t') .. '\n', 'log')
end

local function buffer_write(...)
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

print('-------- LuaTeXInspector GUI --------')

return ui
