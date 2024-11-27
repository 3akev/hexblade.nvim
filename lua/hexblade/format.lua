local M = {}

--- gsub all non-hex chars with nothing
---@param txt string
function M.ensure_hex(txt)
	return txt:gsub("[^%x]", "")
end

--- Ensures that each line in the given list of lines is in hex format
---@param lines string[] List of lines to be cleaned
---@return string[] lines List of lines in hex format
function M.ensure_hex_lines(lines)
	return vim.fn.map(lines, function(_, x)
		return M.ensure_hex(x)
	end)
end

--- convert printable characters to hex
---@param printable string
---@param orig_hex string hex values to use for non-printable characters
---@return string
function M.printables_to_hex(printable, orig_hex)
	orig_hex = M.ensure_hex(orig_hex)

	local hex = ""
	for c in printable:gmatch(".") do
		if c == "." then
			if orig_hex == "" then
				hex = hex .. string.format("%02x", vim.fn.char2nr(c))
			else
				hex = hex .. orig_hex:sub(1, 2)
			end
		else
			hex = hex .. string.format("%02x", vim.fn.char2nr(c))
		end
		orig_hex = orig_hex:sub(3)
	end

	return hex
end

--- convert hex to printable characters
---@param hex string
---@return string
function M.hex_to_printables(hex)
	local printable = ""
	local i = 1
	hex = M.ensure_hex(hex)

	for c in string.gmatch(hex, "..") do
		local b = tonumber(c, 16)
		if b >= 32 and b <= 126 then
			printable = printable .. string.char(b)
		else
			printable = printable .. "."
		end
		i = i + 1
	end
	return printable
end

--- format hex into chunks of chunk_size, seperated by spaces
---@param txt string
---@param chunk_size integer
function M.reformat_chunks(txt, chunk_size)
	local pattern = ("%x"):rep(chunk_size)
	return M.ensure_hex(txt):gsub(pattern, "%1 "):gsub("%s$", ""):gsub("^%s", "")
end

--- convert multiline hex into lines of ncol characters, each line in chunks seperated by spaces
---@param txt string
---@param ncols integer
---@param chunk_size integer
---@return string
function M.reformat_lines(txt, ncols, chunk_size)
	local line_pattern = ("%x"):rep(ncols)
	local lines = {}
	for line in txt:gmatch(line_pattern) do
		local chunks = M.reformat_chunks(line, chunk_size)
		table.insert(lines, chunks)
	end

	-- add last line
	local last_line = string.sub(txt, #lines * ncols + 1)
	if last_line ~= "" then
		local chunks = M.reformat_chunks(last_line, chunk_size)
		table.insert(lines, chunks)
	end

	return table.concat(lines, "\n")
end

--- convert table of lines into a single string
---@param lines table<number, string>
---@return string
function M.join_lines(lines)
	return table.concat(
		vim.fn.map(lines, function(_, x)
			return M.ensure_hex(x)
		end),
		""
	)
end

--- format lines into ncol characters, each line in chunks seperated by spaces
---@param lines table<number, string>
---@param ncols integer
---@param chunk_size integer
---@return table<number, string>
function M.format_lines(lines, ncols, chunk_size)
	return vim.split(M.reformat_lines(M.join_lines(lines), ncols, chunk_size), "\n")
end

return M
