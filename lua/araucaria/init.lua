local utils = require("araucaria.lib.utils")
local pickers = require("araucaria.lib.telescope")

local M = {}

--- Open a telescope picker that shows the RSpec tree.
-- @param file_path [string|nil] The optional file path to open. If not provided, the current buffer will be used.
-- @return [nil] This function does not return any value.
function M.araucaria_tree(file_path)
  local bufnr = vim.api.nvim_get_current_buf()
  if file_path then
    bufnr = utils.open_file(file_path)
  end

  local items = utils.get_buffer_items(bufnr)

  if not items then
    return
  end

  pickers.open_telescope_spec(bufnr, items, {})
end

--- Open a telescope picker that list all RSpec files.
-- @return [nil] This function does not return any value.
function M.araucaria_list_files()
  local git_files = utils.get_git_files()
  local rspec_files = utils.get_rspec_files(git_files)

  if not rspec_files then
    return
  end

  pickers.open_telescope_specs_list(rspec_files, {})
end

function M.register_commands()
  vim.cmd("command! -nargs=? Araucaria lua require('araucaria').araucaria_tree(<q-args>)")
  vim.cmd("command! AraucariaAll lua require('araucaria').araucaria_list_files()")
end

function M.setup(opts)
  opts = opts or {}
  M.register_commands()
end

return M
