local extmarks = require("hexblade.extmarks")

local bufnr

before_each(function()
	bufnr = vim.api.nvim_create_buf(false, true)
	extmarks.setup()
end)

after_each(function()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

describe("setup", function()
	it("creates namespace", function()
		assert.is_not.equals(extmarks.namespace, 0)
		local x = vim.api.nvim_get_namespaces()
		-- find the namespace in the list
		local found = false
		for _, v in pairs(x) do
			if v == extmarks.namespace then
				found = true
				break
			end
		end
		assert.is_true(found)
	end)
end)

describe("clear_extmarks", function()
	it("clears extmarks in buffer", function()
		vim.api.nvim_buf_set_extmark(bufnr, extmarks.namespace, 0, 0, {})
		extmarks.clear_extmarks(bufnr)
		local extmarks_list = vim.api.nvim_buf_get_extmarks(bufnr, extmarks.namespace, 0, -1, {})
		assert.are.same({}, extmarks_list)
	end)
end)

describe("get_hex_sidebuf", function()
	it("converts lines to hex printables", function()
		local lines = { "056c69096e6531", "6c696e653201" }
		local result = extmarks.get_hex_sidebuf(lines)
		assert.are.same({ ".li.ne1", "line2." }, result)
	end)
end)

describe("get_ascii_sidebuf", function()
	it("converts lines to ascii and reformats chunks", function()
		local lines = { "line1", "line2" }
		local hex_lines = { "6c696e6531", "6c696e6532" }
		local chunk_size = 2
		local result = extmarks.get_ascii_sidebuf(lines, hex_lines, chunk_size)
		assert.are.same({ "6c 69 6e 65 31", "6c 69 6e 65 32" }, result)
	end)
end)

describe("update_line_extmark", function()
	it("updates line extmark", function()
		local line = 0
		local id = extmarks.update_line_extmark(bufnr, line, { virt_text = { { "content", "comment" } } })
		local item = vim.api.nvim_buf_get_extmark_by_id(bufnr, extmarks.namespace, id, { details = true })
		assert.is.equal(item[1], line)
		assert.is.equal(item[3].virt_text[1][1], "content")

		line = 1
		extmarks.update_line_extmark(bufnr, line, { id = id, virt_text = { { "helloworld", "comment" } } })
		item = vim.api.nvim_buf_get_extmark_by_id(bufnr, extmarks.namespace, id, { details = true })
		assert.is.equal(item[1], line)
		assert.is.equal(item[3].virt_text[1][1], "helloworld")
	end)
end)

describe("redraw_addresses", function()
	it("redraws addresses", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "6c696e6531", "6c696e6532" })
		local address_marks = extmarks.redraw_addresses(bufnr, {}, {}, false)
		for k, v in pairs(address_marks) do
			local item = vim.api.nvim_buf_get_extmark_by_id(bufnr, extmarks.namespace, v, { details = true })
			assert.is.equal(k - 1, item[1])
			assert.is.equal(item[3].virt_text[1][1], string.format("%08x: ", 5 * (k - 1)))
		end
	end)
end)

describe("get_cursor_highlight", function()
	local ascii = ".ELF............"
	local hex = "7f45 4c46 0201 0100 0000 0000 0000 0000"

	local hexmode_tests = {
		{
			{ 0, 1 },
			{
				{ "", "Comment" },
				{ ".", "Cursor" },
				{ "ELF............", "Comment" },
			},
		},
		{
			{ 2, 3 },
			{
				{ ".", "Comment" },
				{ "E", "Cursor" },
				{ "LF............", "Comment" },
			},
		},
		{
			{ 4, 5, 6 },
			{
				{ ".E", "Comment" },
				{ "L", "Cursor" },
				{ "F............", "Comment" },
			},
		},
		{
			{ 7, 8 },
			{
				{ ".EL", "Comment" },
				{ "F", "Cursor" },
				{ "............", "Comment" },
			},
		},
		{
			{ 9, 10, 11 },
			{
				{ ".ELF", "Comment" },
				{ ".", "Cursor" },
				{ "...........", "Comment" },
			},
		},
		{
			{ 12, 13 },
			{
				{ ".ELF.", "Comment" },
				{ ".", "Cursor" },
				{ "..........", "Comment" },
			},
		},
		{
			{ 14, 15, 16 },
			{
				{ ".ELF..", "Comment" },
				{ ".", "Cursor" },
				{ ".........", "Comment" },
			},
		},
		{
			{ 17, 18 },
			{
				{ ".ELF...", "Comment" },
				{ ".", "Cursor" },
				{ "........", "Comment" },
			},
		},
		{
			{ 19, 20, 21 },
			{
				{ ".ELF....", "Comment" },
				{ ".", "Cursor" },
				{ ".......", "Comment" },
			},
		},
		{
			{ 22, 23 },
			{
				{ ".ELF.....", "Comment" },
				{ ".", "Cursor" },
				{ "......", "Comment" },
			},
		},
		{
			{ 24, 25, 26 },
			{
				{ ".ELF......", "Comment" },
				{ ".", "Cursor" },
				{ ".....", "Comment" },
			},
		},
		{
			{ 27, 28 },
			{
				{ ".ELF.......", "Comment" },
				{ ".", "Cursor" },
				{ "....", "Comment" },
			},
		},
		{
			{ 29, 30, 31 },
			{
				{ ".ELF........", "Comment" },
				{ ".", "Cursor" },
				{ "...", "Comment" },
			},
		},
		{
			{ 32, 33 },
			{
				{ ".ELF.........", "Comment" },
				{ ".", "Cursor" },
				{ "..", "Comment" },
			},
		},
		{
			{ 34, 35, 36 },
			{
				{ ".ELF..........", "Comment" },
				{ ".", "Cursor" },
				{ ".", "Comment" },
			},
		},
		{
			{ 37, 38 },
			{
				{ ".ELF...........", "Comment" },
				{ ".", "Cursor" },
				{ "", "Comment" },
			},
		},
	}

	for _, test in ipairs(hexmode_tests) do
		local cols = test[1]
		local expected = test[2]
		for _, i in ipairs(cols) do
			it("highlights correctly in hex mode i=" .. i, function()
				local res = extmarks.get_cursor_highlight(hex, ascii, i, nil)
				assert.are.same(expected, res)
			end)
		end
	end

	local asciimode_tests = {
		{
			0,
			{
				{ "", "Comment" },
				{ "7f", "Cursor" },
				{ "45 4c46 0201 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			1,
			{
				{ "7f", "Comment" },
				{ "45", "Cursor" },
				{ " 4c46 0201 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			2,
			{
				{ "7f45 ", "Comment" },
				{ "4c", "Cursor" },
				{ "46 0201 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			3,
			{
				{ "7f45 4c", "Comment" },
				{ "46", "Cursor" },
				{ " 0201 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			4,
			{
				{ "7f45 4c46 ", "Comment" },
				{ "02", "Cursor" },
				{ "01 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			5,
			{
				{ "7f45 4c46 02", "Comment" },
				{ "01", "Cursor" },
				{ " 0100 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			6,
			{
				{ "7f45 4c46 0201 ", "Comment" },
				{ "01", "Cursor" },
				{ "00 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			7,
			{
				{ "7f45 4c46 0201 01", "Comment" },
				{ "00", "Cursor" },
				{ " 0000 0000 0000 0000", "Comment" },
			},
		},
		{
			8,
			{
				{ "7f45 4c46 0201 0100 ", "Comment" },
				{ "00", "Cursor" },
				{ "00 0000 0000 0000", "Comment" },
			},
		},
		{
			9,
			{
				{ "7f45 4c46 0201 0100 00", "Comment" },
				{ "00", "Cursor" },
				{ " 0000 0000 0000", "Comment" },
			},
		},
		{
			10,
			{
				{ "7f45 4c46 0201 0100 0000 ", "Comment" },
				{ "00", "Cursor" },
				{ "00 0000 0000", "Comment" },
			},
		},
		{
			11,
			{
				{ "7f45 4c46 0201 0100 0000 00", "Comment" },
				{ "00", "Cursor" },
				{ " 0000 0000", "Comment" },
			},
		},
		{
			12,
			{
				{ "7f45 4c46 0201 0100 0000 0000 ", "Comment" },
				{ "00", "Cursor" },
				{ "00 0000", "Comment" },
			},
		},
		{
			13,
			{
				{ "7f45 4c46 0201 0100 0000 0000 00", "Comment" },
				{ "00", "Cursor" },
				{ " 0000", "Comment" },
			},
		},
		{
			14,
			{
				{ "7f45 4c46 0201 0100 0000 0000 0000 ", "Comment" },
				{ "00", "Cursor" },
				{ "00", "Comment" },
			},
		},
		{
			15,
			{
				{ "7f45 4c46 0201 0100 0000 0000 0000 00", "Comment" },
				{ "00", "Cursor" },
				{ "", "Comment" },
			},
		},
	}

	for _, test in ipairs(asciimode_tests) do
		local i = test[1]
		local expected = test[2]
		it("highlights correctly in ascii mode i=" .. i, function()
			-- TODO: test other chunk sizes
			local res = extmarks.get_cursor_highlight(ascii, hex, i, 4)
			assert.are.same(expected, res)
		end)
	end
end)
