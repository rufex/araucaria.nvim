local utils = require("araucaria.lib.utils")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local M = {}

function M.open_telescope_spec(bufnr, items, opts)
  opts = opts or {}
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- @param entry table: { keyword, indentation, text, keyword_node, description_node}
  local function make_entry(entry)
    local keyword_node = entry[4]
    local keyword_range = { keyword_node:range() }
    local keyword_start_row = keyword_range[1]

    local displayer = entry_display.create({
      separator = " ",
      items = {
        { width = #entry[2] },
        { width = #entry[1] },
        { width = #entry[3] },
      },
    })

    local function make_display()
      return displayer({
        { entry[2], "Comment" }, -- Indentation
        { entry[1], "@function.call.ruby" }, -- Keyword
        { entry[3], "@string.ruby" }, -- Description
      })
    end

    return {
      value = entry,
      display = make_display,
      ordinal = entry[3],
      lnum = keyword_start_row + 1,
      filename = filename,
    }
  end

  local finder = finders.new_table({
    results = items,
    entry_maker = make_entry,
  })

  local function attach_mapper(prompt_bufnr, _)
    actions.select_default:replace(function()
      local selection = action_state.get_selected_entry()
      actions.close(prompt_bufnr)
      vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
      vim.api.nvim_command("normal! zz")
    end)
    return true
  end

  pickers
    .new(opts, {
      prompt_title = "Find Spec",
      results_title = "Araucaria - RSpec Tree",
      sorting_strategy = "ascending",
      initial_mode = "normal",
      finder = finder,
      sorter = conf.generic_sorter(opts),
      previewer = previewers.vim_buffer_vimgrep.new(opts),
      attach_mappings = attach_mapper,
    })
    :find()
end

function M.open_telescope_specs_list(file_paths, opts)
  opts = opts or {}

  -- @param entry string: 'file path'
  local function make_entry(entry)
    local path_items = utils.get_path_items(entry)
    local display_path = table.concat(path_items, " > ")

    local entry_details = {
      value = entry,
      display = display_path,
      ordinal = display_path,
      lnum = 0,
      filename = entry,
    }
    return entry_details
  end

  local finder = finders.new_table({
    results = file_paths,
    entry_maker = make_entry,
  })

  pickers
    .new(opts, {
      prompt_title = "Find Spec File",
      results_title = "Araucaria - RSpec Files",
      sorting_strategy = "ascending",
      initial_mode = "insert",
      finder = finder,
      sorter = conf.generic_sorter(opts),
      previewer = previewers.vim_buffer_vimgrep.new(opts),
    })
    :find()
end

return M
