local M = {}

--- returns a list of lines containing binary data from a list of hex strings
---@param lines string[] must contain only hex digits
---@return string[]
function M.hex2bin(lines)
	return vim.split(M.hex2binstr(lines), "\x0a")
end

--- returns a single binary string from a list of hex strings
---@param lines string[] must contain only hex digits
---@return string
function M.hex2binstr(lines)
	local binstr = ""
	for _, line in ipairs(lines) do
		binstr = binstr .. M.hexstr2binstr(line)
	end
	return binstr
end

function M.hexstr2binstr(hexstr)
	local binstr = ""
	for i = 1, #hexstr, 2 do
		local byte = tonumber(hexstr:sub(i, i + 1), 16)
		binstr = binstr .. string.char(byte)
	end
	return binstr
end

function M.binstr2hex(binstr)
	return vim.split(M.binstr2hexstr(binstr), "\x0a")
end

function M.binstr2hexstr(binstr)
	local hexstr = ""
	for i = 1, #binstr do
		local byte = string.byte(binstr, i)
		hexstr = hexstr .. string.format("%02x", byte)
	end
	return hexstr
end

--- returns a list of hex strings from a list of binary data
---@param lines string[] containing binary data
---@param ncols integer number of columns per line
---@return string[]
function M.bin2hex(lines, ncols)
	local hex_lines = {}
	local hex_line = {}
	local bytestr = table.concat(lines, "\x0a")
	for i = 1, #bytestr do
		local byte = string.byte(bytestr, i)
		table.insert(hex_line, string.format("%02x", byte))
		if i % ncols == 0 then
			table.insert(hex_lines, table.concat(hex_line))
			hex_line = {}
		end
	end
	if #hex_line > 0 then
		table.insert(hex_lines, table.concat(hex_line))
	end
	return hex_lines
end

return M
