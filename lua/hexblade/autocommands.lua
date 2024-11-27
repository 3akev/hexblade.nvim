local M = {}

local format = require("hexblade.format")
local hex = require("hexblade.hex")
local extmarks = require("hexblade.extmarks")

function M.setup()
	M.augroup = vim.api.nvim_create_augroup("hexblade.nvim_autocmds", { clear = true })
end

---@param state HexbladeState
---@param bufnr integer
---@return fun():nil
function M.aucmd_update_extmarks(state, bufnr)
	return function()
		local line = vim.api.nvim_buf_get_mark(bufnr, ".")[1]
		if line == nil then
			return
		end
		extmarks.update_side_buffer(state, bufnr)
		extmarks.redraw_sideview(bufnr, state)
		extmarks.redraw_addresses(bufnr, state.side_buffer, state.address_marks, state.ascii_mode)
	end
end

--- Save the current buffer as binary when in hex mode
---@param state HexbladeState
---@param bufnr integer
---@return fun():nil
function M.aucmd_hexblade_save(state, bufnr)
	return function()
		local lines
		if state.ascii_mode == true then
			lines = state.side_buffer
		else
			lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		end

		lines = format.ensure_hex_lines(lines)

		local bin = hex.hex2binstr(lines)

		local filename = vim.api.nvim_buf_get_name(bufnr)
		local file = assert(io.open(filename, "wb"))
		file:write(bin)
		assert(file:close())
		vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

		vim.notify("Binary file saved", vim.log.levels.INFO)
		-- prevent default save
		return false
	end
end

---@param state HexbladeState
---@param bufnr integer
function M.aucmd_cursor_moved(state, bufnr)
	return function()
		local old = state.cursor
		state.cursor = vim.api.nvim_win_get_cursor(0)

		if old ~= nil then
			extmarks.redraw_sideview(bufnr, state, old[1], old[1])
		end
		extmarks.redraw_sideview(bufnr, state, state.cursor[1], state.cursor[1])
	end
end

function M.create_autocommands(state, bufnr)
	assert(state)
	return {
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
			group = M.augroup,
			buffer = bufnr,
			callback = M.aucmd_update_extmarks(state, bufnr),
		}),
		vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
			group = M.augroup,
			buffer = bufnr,
			callback = M.aucmd_hexblade_save(state, bufnr),
		}),
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = M.augroup,
			buffer = bufnr,
			callback = M.aucmd_cursor_moved(state, bufnr),
		}),
	}
end

function M.clear_autocommands(autocommands)
	for _, id in ipairs(autocommands) do
		vim.api.nvim_del_autocmd(id)
	end
end

return M
