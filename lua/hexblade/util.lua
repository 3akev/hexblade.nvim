local M = {}

local format = require("hexblade.format")

---@param bufnr integer
---@param ncols integer
---@param chunk_size integer
function M.format_buffer(bufnr, ncols, chunk_size)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local reformatted = format.format_lines(lines, 2 * ncols, chunk_size)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, reformatted)
end

---@param txt string
---@param ch string
---@return integer
function M.count(txt, ch)
	local spaces = 0
	for i = 1, txt:len() do
		if txt:sub(i, i) == ch then
			spaces = spaces + 1
		end
	end
	return spaces
end

---@param bufnr integer
---@param n integer
---@param chunk_size? integer chunk size when in hex mode used to skip spaces, nil when in ascii mode
---@return integer[]
function M.get_byte_position(bufnr, n, chunk_size)
	local line_count = vim.api.nvim_buf_line_count(bufnr)

	for line = 1, line_count do
		local txt = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
		local num_spaces = M.count(txt, " ")

		if chunk_size ~= nil then
			txt = format.ensure_hex(txt)
		end

		local line_length = txt:len()
		if line_length == n then
			return { line + 1, 0 }
		elseif line_length > n then
			local col = n

			if chunk_size ~= nil then
				col = col + num_spaces
			end
			return { line, col }
		end
		n = n - line_length
	end

	return {}
end

return M
