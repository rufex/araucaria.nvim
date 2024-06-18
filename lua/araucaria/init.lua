local utils = require("araucaria.lib.utils")
local pickers = require("araucaria.lib.telescope")

local M = {}

--- Open a telescope picker that shows the RSpec tree.
-- @param file_path [string|nil] The optional file path to open. If not provided, the current buffer will be used.
-- @return [nil] This function does not return any value.
function M.list_specs(file_path)
  local bufnr = vim.api.nvim_get_current_buf()
  if file_path then
    bufnr = utils.open_file(file_path)
  end

  local items = utils.get_buffer_items(bufnr)

  if not items then
    return
  end

  pickers.open_telescope_specs(bufnr, items, {})
end

--- Open a telescope picker that list all RSpec files.
-- @return [nil] This function does not return any value.
function M.list_files()
  local git_files = utils.get_git_files()
  local rspec_files = utils.get_rspec_files(git_files)

  if not rspec_files then
    return
  end

  pickers.open_telescope_files(rspec_files, {})
end

--- Open a telescope picker that list all RSpec files and specs.
-- It a combination of `AraucariaAll` and `AraucariaBuff` commands.
-- If the current buffer is a spec file, it will show the RSpecs tree.
-- Otherwise, it will show all RSpec files, and once you select one, it will show the RSpecs tree.
-- @return [nil] This function does not return any value.
function M.list_files_and_specs()
  local bufnr = vim.api.nvim_get_current_buf()
  local rspec_file = utils.check_rspec_file(bufnr, true)
  if rspec_file then
    M.list_specs()
  else
    local git_files = utils.get_git_files()
    local rspec_files = utils.get_rspec_files(git_files)

    if not rspec_files then
      return
    end
    pickers.open_telescope_files_and_specs(rspec_files, {})
    -- TODO: Open spec with selected file
  end
end

function M.register_commands()
  vim.cmd("command! -nargs=? AraucariaBuff lua require('araucaria').list_specs(<q-args>)") -- Specs of current or provided buffer
  vim.cmd("command! AraucariaAll lua require('araucaria').list_files()") -- List all files
  vim.cmd("command! Araucaria lua require('araucaria').list_files_and_specs()") -- List all files and open Specs tree with selected file
end

function M.setup(opts)
  opts = opts or {}
  M.register_commands()
end

return M
