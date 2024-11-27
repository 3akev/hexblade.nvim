local util = require("hexblade.util")

local bufnr

before_each(function()
	bufnr = vim.api.nvim_create_buf(false, true)
	local lines = { "abcde1", "abcde2", "abcde3" }
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end)

after_each(function()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

describe("format_buffer", function()
	it("formats the buffer correctly", function()
		local ncols = 4 -- 4 bytes => 8 hex digits
		local chunk_size = 2

		util.format_buffer(bufnr, ncols, chunk_size)
		local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		assert.are.same({ "ab cd e1 ab", "cd e2 ab cd", "e3" }, result)
	end)
end)

describe("count", function()
	it("counts the number of characters in a string", function()
		assert.are.equal(3, util.count("a b c d", " "))
		assert.are.equal(2, util.count("a b a d", "a"))
		assert.are.equal(1, util.count("a b a d", "d"))
		assert.are.equal(0, util.count("a b a d", "c"))
	end)
end)

describe("get_byte_position", function()
	for i = 0, 3 * 6 do
		it("moves the cursor to the correct position in ASCII mode i=" .. i, function()
			assert.are.same({ math.floor(i / 6) + 1, i % 6 }, util.get_byte_position(bufnr, i, nil))
		end)
	end

	for i = 0, 3 * 3 do
		it("moves the cursor to the correct position in hex mode i=" .. i, function()
			assert.are.same({ math.floor(2 * i / 6) + 1, (2 * i % 6) }, util.get_byte_position(bufnr, 2 * i, 2))
		end)
	end
end)
