---@class HexbladeState
---@field saved HexbladeSavedOptions
---@field ncols number
---@field chunk_size number
---@field side_marks table<number, number>
---@field address_marks table<number, number>
---@field side_buffer table<number, string>
---@field ascii_mode boolean
---@field autocommands table<number, number>
---@field cursor integer[]
---@field cursor_marks number[]

---@class HexbladeSavedOptions
---@field filetype string
---@field lsps integer[]

---@class Hexblade
---@field state table<number, HexbladeState>
local M = {
	state = {},
}

local ncols = 16
local chunk_size = 4

local hex = require("hexblade.hex")
local format = require("hexblade.format")
local extmarks = require("hexblade.extmarks")
local autocommands = require("hexblade.autocommands")
local util = require("hexblade.util")

function M.setup(opts)
	opts = opts or {}
	if opts.ncols then
		ncols = opts.ncols
	end
	if opts.chunk_size then
		chunk_size = opts.chunk_size
	end
end

---@return HexbladeState
local function init_state()
	return {
		saved = {
			filetype = vim.bo.filetype or "",
			lsps = {},
		},
		ncols = ncols,
		chunk_size = chunk_size,
		side_marks = {},
		address_marks = {},
		side_buffer = {},
		ascii_mode = false,
		autocommands = {},
		cursor = nil,
		cursor_marks = {},
	}
end

---@param bufnr integer
function M.hexblade_read(bufnr)
	extmarks.clear_extmarks(bufnr)
	vim.treesitter.stop(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	local lsps = {}

	for i, client in pairs(clients) do
		vim.lsp.buf_detach_client(bufnr, client.id)
		lsps[i] = client.id
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local hexlines = hex.bin2hex(lines, ncols)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, hexlines)

	util.format_buffer(bufnr, ncols, chunk_size)

	vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

	local state = init_state()
	state.saved.lsps = lsps
	vim.bo.filetype = ""
	extmarks.update_side_buffer(state, bufnr)

	state.address_marks = extmarks.redraw_addresses(bufnr, state.side_buffer)
	state.side_marks = extmarks.redraw_sideview(bufnr, state)

	state.autocommands = autocommands.create_autocommands(state, bufnr)

	M.state[bufnr] = state
end

---@param bufnr integer
function M.hexblade_dump(bufnr)
	autocommands.clear_autocommands(M.state[bufnr].autocommands)
	extmarks.clear_extmarks(bufnr)

	local lines = format.ensure_hex_lines(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	local hexlines = hex.hex2bin(lines)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, hexlines)

	for _, client in pairs(M.state[bufnr].saved.lsps) do
		vim.lsp.buf_attach_client(bufnr, client)
	end

	vim.bo.filetype = M.state[bufnr].saved.filetype
	M.state[bufnr] = nil
	vim.treesitter.start(bufnr, vim.bo.filetype)
end

---@param bufnr integer
function M.hexblade_toggle(bufnr)
	local state = M.state[bufnr]
	vim.bo.binary = true
	if state ~= nil then
		if state.ascii_mode == true then
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, state.side_buffer)
		end
		M.hexblade_dump(bufnr)
	else
		M.hexblade_read(bufnr)
	end
end

---@param bufnr integer
function M.hexblade_format_buffer(bufnr)
	local state = assert(M.state[bufnr])
	if state.ascii_mode == true then
		return
	end
	util.format_buffer(vim.fn.bufnr(), state.ncols, state.chunk_size)
	extmarks.update_side_buffer(state, bufnr)
	extmarks.redraw_addresses(bufnr, state.side_buffer, state.address_marks)
	extmarks.redraw_sideview(bufnr, state)
end

---@param bufnr integer
---@param addr string
function M.hexblade_goto_address(bufnr, addr)
	local state = assert(M.state[bufnr])

	if addr == "" then
		vim.ui.input({ prompt = "Address: ", default = "0x" }, function(input)
			addr = input
		end)
		if addr == nil then
			return
		end
	end

	local a = tonumber(addr, 16)
	if a == nil then
		vim.notify("Invalid address", vim.log.levels.ERROR)
		return
	end

	local newpos
	if state.ascii_mode == true then
		newpos = util.get_byte_position(bufnr, a)
	else
		newpos = util.get_byte_position(bufnr, a * 2, state.chunk_size)
	end
	vim.api.nvim_win_set_cursor(0, newpos)
end

---@param bufnr integer
function M.hexblade_swap(bufnr)
	local state = assert(M.state[bufnr])
	local old_modified = vim.bo.modified

	if state.ascii_mode == false then
		-- swap to hex in side view
		state.ascii_mode = true
		state.side_buffer = vim.fn.map(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), function(_, x)
			return format.ensure_hex(x)
		end)
		local ascii = vim.fn.map(state.side_buffer, function(_, x)
			return format.hex_to_printables(x)
		end)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, ascii)
	else
		-- swap to ascii in side view
		local hexlines = state.side_buffer
		state.ascii_mode = false
		extmarks.update_side_buffer(state, bufnr)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, hexlines)
	end

	vim.api.nvim_set_option_value("modified", old_modified, { buf = bufnr })

	extmarks.redraw_addresses(bufnr, state.side_buffer, state.address_marks)
	extmarks.redraw_sideview(bufnr, state)
end

return M
