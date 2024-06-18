local M = {}

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

function M.get_git_files()
  local git_files_output = vim.fn.systemlist("git ls-files")
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to retrieve git files or not a git repository", vim.log.levels.ERROR)
    return
  end

  return git_files_output
end

function M.get_rspec_files(files)
  local rspec_files = {}
  for _, file in ipairs(files) do
    if string.match(file, "_spec.rb") then
      table.insert(rspec_files, file)
    end
  end
  return rspec_files
end

function M.get_path_items(path)
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

--- Open file in tab
-- @param file_path [string] The file path to open
-- @return [number] The buffer number
function M.open_file(file_path)
  if file_path == "" then
    return
  end

  vim.cmd("tabfind " .. file_path)
  local bufnr = vim.fn.bufnr(file_path)
  return bufnr
end

--- Retrieves all 'RSpec' items from the buffer
-- @param bufnr [number] (optional) The buffer number to extract items from. Defaults to the current buffer.
-- @return [table] A table containing items found in the buffer. Each item is a table with keyword text, indentation,
-- description text, keyword node, and description node.
function M.get_buffer_items(bufnr)
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

return M
