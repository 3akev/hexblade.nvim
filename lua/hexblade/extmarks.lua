local M = {
	namespace = 0,
}

local format = require("hexblade.format")
local util = require("hexblade.util")

function M.setup()
	M.namespace = vim.api.nvim_create_namespace("hexblade")
end

function M.clear_extmarks(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

--- returns a list of hex strings from a list of ascii strings
---@param lines string[] list of ascii strings
---@return string[] hex list of hex strings
function M.get_hex_sidebuf(lines)
	return vim.fn.map(lines, function(_, x)
		return format.hex_to_printables(x)
	end)
end

--- returns a list of ascii strings from a list of hex strings
---@param lines string[] list of ascii strings
---@param hex_lines string[] list of hex strings
---@param chunk_size integer
---@return string[] ascii list of ascii strings
function M.get_ascii_sidebuf(lines, hex_lines, chunk_size)
	return vim.fn.map(lines, function(idx, x)
		local y = format.printables_to_hex(x, hex_lines[idx + 1])
		return format.reformat_chunks(y, chunk_size)
	end)
end

---@param state HexbladeState
---@param bufnr integer
---@param start integer?
---@param end_ integer?
function M.update_side_buffer(state, bufnr, start, end_)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start or 0, end_ or -1, false)
	local li

	if state.ascii_mode == false then
		li = M.get_hex_sidebuf(lines)
	else
		li = M.get_ascii_sidebuf(lines, state.side_buffer, state.chunk_size)
	end

	if start == nil or end_ == nil or (start == 0 and end_ == -1) then
		state.side_buffer = li
	else
		table.move(li, 1, #li, start, state.side_buffer)
	end
end

---@param bufnr integer
---@param line integer
---@param opts vim.api.keyset.set_extmark
---@return integer?
function M.update_line_extmark(bufnr, line, opts)
	local op = {
		virt_text_pos = "eol",
		undo_restore = false,
	}

	for k, v in pairs(opts) do
		op[k] = v
	end

	return vim.api.nvim_buf_set_extmark(bufnr, M.namespace, line, 0, op)
end

---@param bufnr integer
---@param side_buffer table<number, string>
---@param address_marks? table<number, number>
---@param ascii_mode? boolean
---@return table<number, number>
function M.redraw_addresses(bufnr, side_buffer, address_marks, ascii_mode)
	address_marks = address_marks or {}
	local lines
	if ascii_mode == false then
		lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	else
		lines = side_buffer
	end

	local num_bytes = 0

	for line, txt in ipairs(lines) do
		local addr = string.format("%08X: ", num_bytes)
		address_marks[line] = M.update_line_extmark(
			bufnr,
			line - 1,
			{ id = address_marks[line], virt_text = { { addr, "comment" } }, virt_text_pos = "inline" }
		)

		num_bytes = num_bytes + format.hex_to_printables(txt):len()
	end

	for line = #lines + 1, #address_marks do
		vim.api.nvim_buf_del_extmark(bufnr, M.namespace, address_marks[line])
		address_marks[line] = nil
	end

	return address_marks
end

---@param buftxt string line of text in buffer
---@param sidetxt string line of text in side buffer
---@param col integer column in buffer
---@param chunk_size integer?
---@return any[]
function M.get_cursor_highlight(buftxt, sidetxt, col, chunk_size)
	local before
	local cursorchar
	local after

	if chunk_size == nil then
		col = (col - util.count(buftxt:sub(1, col), " ")) / 2
		before = sidetxt:sub(1, col)
		cursorchar = sidetxt:sub(col + 1, col + 1)
		after = sidetxt:sub(col + 2)
	else
		col = 2 * col
		col = col + util.count(sidetxt:sub(1, col + col / chunk_size), " ")
		before = sidetxt:sub(1, col)
		cursorchar = sidetxt:sub(col + 1, col + 2)
		after = sidetxt:sub(col + 3)
	end

	return {
		{ before, "Comment" },
		{ cursorchar, "Cursor" },
		{ after, "Comment" },
	}
end

---@param bufnr integer
---@param state HexbladeState
---@param start integer
---@param end_ integer
---@return table<number, number>
function M.redraw_sideview(bufnr, state, start, end_)
	state.side_marks = state.side_marks or {}
	start = start or 1
	end_ = end_ or table.maxn(state.side_buffer)

	for line = start, end_ do
		local txt = state.side_buffer[line]
		local virt_text

		if state.cursor ~= nil and line == state.cursor[1] then
			local buftxt = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
			local chunk_size
			if state.ascii_mode then
				chunk_size = state.chunk_size
			else
				chunk_size = nil
			end
			virt_text = M.get_cursor_highlight(buftxt, txt, state.cursor[2], chunk_size)
		else
			virt_text = { { txt, "comment" } }
		end

		state.side_marks[line] = M.update_line_extmark(
			bufnr,
			line - 1,
			{ id = state.side_marks[line], virt_text = virt_text, virt_text_pos = "eol" }
		)
	end

	return state.side_marks
end

return M
