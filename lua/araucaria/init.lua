local ts = vim.treesitter

local query_string = [[
  ((identifier) @keyword
    (#match? @keyword "(context|describe|it|scenario|it_behaves_like|shared_examples|include_context|shared_context)")
    (argument_list
      [
        (string) @desc
        (constant) @desc
      ]
    )
  )
]]

local function get_tree_root(bufnr)
  local parser = ts.get_parser(bufnr, "ruby", {})
  local tree = parser:parse()[1]
  return tree:root()
end

local function check_filename(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if not string.match(filename, "_spec.rb") then
    vim.notify("Araucaria can only be used in Ruby Rspecs", vim.log.levels.ERROR)
    return false
  end
  return true
end

local function get_buffer_items(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not check_filename(bufnr) then
    return
  end

  local query_parsed = ts.query.parse("ruby", query_string)
  local root = get_tree_root(bufnr)
  local keyword_text = ""
  local indentation = ""
  local items = {}
  local keyword_node = {}

  for id, node in query_parsed:iter_captures(root, bufnr, 0, -1) do
    local name = query_parsed.captures[id]
    local text = ts.get_node_text(node, 0)

    if name == "keyword" then
      keyword_node = node
      keyword_text = text
      -- { start_row, start_col, end_row, end_col }
      local range = { node:range() }
      indentation = string.rep(" ", range[2])
    end

    if name ~= "keyword" then
      local description_text = text
      table.insert(items, { keyword_text, indentation, description_text, keyword_node, node })
      keyword_text = ""
    end
  end

  items[1][1] = "RSpec." .. items[1][1] -- add RSpec to first item
  items[1][2] = "" -- remove indentation from first item

  return items
end

local function open_telescope_spec(bufnr, items, opts)
  opts = opts or {}
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local previewers = require("telescope.previewers")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  -- @param entry table: { keyword, indentation, text, keyword_node, description_node}
  local function make_entry(entry)
    local keyword_node = entry[4]
    local keyword_range = { keyword_node:range() }
    local keyword_start_row = keyword_range[1]

    local entry_details = {
      value = entry,
      display = entry[2] .. entry[1] .. " " .. entry[3],
      ordinal = entry[3],
      lnum = keyword_start_row + 1,
      filename = filename,
    }
    return entry_details
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

local function get_git_files()
  local git_files_output = vim.fn.systemlist("git ls-files")
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to retrieve git files or not a git repository", vim.log.levels.ERROR)
    return
  end

  return git_files_output
end

local function get_rspec_files(files)
  local rspec_files = {}
  for _, file in ipairs(files) do
    if string.match(file, "_spec.rb") then
      table.insert(rspec_files, file)
    end
  end
  return rspec_files
end

local function get_path_items(path)
  local components = {}
  for part in path:gmatch("[^/]+") do
    table.insert(components, part)
  end

  local file_name = table.remove(components) -- Get the last component
  local base_name = file_name:match("(.+)%..+$") or file_name -- Remove the file extension
  local name_without_spec = base_name:gsub("_spec$", "") -- Remove '_spec'
  local pascal_case_name = name_without_spec:gsub("_(%l)", string.upper):gsub("^%l", string.upper) -- Convert to PascalCase

  for i, part in ipairs(components) do
    components[i] = part:gsub("_(%l)", string.upper):gsub("^%l", string.upper) -- Convert to PascalCase
  end

  table.insert(components, pascal_case_name)

  return components
end

local function open_telescope_specs_list(file_paths, opts)
  opts = opts or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values

  -- @param entry string: 'file path'
  local function make_entry(entry)
    local path_items = get_path_items(entry)
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

local M = {}

function M.araucaria_tree(bufnr)
  local items = get_buffer_items(bufnr)

  if not items then
    return
  end

  open_telescope_spec(bufnr, items, {})
end

function M.araucaria_list_files()
  local git_files = get_git_files()
  local rspec_files = get_rspec_files(git_files)

  if not rspec_files then
    return
  end

  open_telescope_specs_list(rspec_files, {})
end

function M.register_commands()
  vim.cmd("command! Araucaria lua require('araucaria').araucaria_tree()")
  vim.cmd("command! AraucariaAll lua require('araucaria').araucaria_list_files()")
end

function M.setup(opts)
  opts = opts or {}
  M.register_commands()
end

return M
