local M = {}

local autocommands = require("hexblade.autocommands")
local extmarks = require("hexblade.extmarks")
local api = require("hexblade.api")

function M.hexblade_swap()
	api.hexblade_swap(vim.fn.bufnr())
end

function M.hexblade_goto_address(args)
	api.hexblade_goto_address(vim.fn.bufnr(), args.args)
end

function M.hexblade_format_buffer()
	api.hexblade_format_buffer(vim.fn.bufnr())
end

function M.hexblade_toggle()
	api.hexblade_toggle(vim.fn.bufnr())
end

---@class HexbladeOptions
---@field ncols integer number of bytes per line
---@field chunk_size integer number of digits per chunk

---@param opts HexbladeOptions
function M.setup(opts)
	vim.api.nvim_create_user_command("HexbladeToggle", M.hexblade_toggle, {})
	vim.api.nvim_create_user_command("HexbladeFormatBuffer", M.hexblade_format_buffer, {})
	vim.api.nvim_create_user_command("HexbladeSwap", M.hexblade_swap, {})
	vim.api.nvim_create_user_command("HexbladeGotoAddress", M.hexblade_goto_address, {
		nargs = "?",
	})

	api.setup(opts)
	extmarks.setup()
	autocommands.setup()
end

return M
