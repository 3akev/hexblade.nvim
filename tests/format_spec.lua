---@module "luassert"

local format = require("hexblade.format")

local tests_ensure_hex = {
	{ "123456", "123456" },
	{ "1234567890abcdef", "1234567890abcdef" },
	{ "1g23iii45lpoiolk67890abcdhef", "1234567890abcdef" },
}

describe("ensure_hex", function()
	for _, test in ipairs(tests_ensure_hex) do
		it("should eliminate non-hex chars " .. test[1], function()
			local result = format.ensure_hex(test[1])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_ensure_hex_lines = {
	{ { "123456", "123456" }, { "123456", "123456" } },
	{ { "1234567890abcdef", "1234567890abcdef" }, { "1234567890abcdef", "1234567890abcdef" } },
	{ { "1g23iii45lpoiolk67890abcdhef", "123456789nn0abcdef" }, { "1234567890abcdef", "1234567890abcdef" } },
}

describe("ensure_hex_lines", function()
	for _, test in ipairs(tests_ensure_hex_lines) do
		it("should eliminate non-hex chars from lines " .. test[1][1], function()
			local result = format.ensure_hex_lines(test[1])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_reformat_chunks = {
	{ { "123456564567", 4 }, "1234 5656 4567" },
	{ { "123456", 2 }, "12 34 56" },
	{ { "123456", 3 }, "123 456" },
	{ { "123456", 1 }, "1 2 3 4 5 6" },
	{ { "123", 4 }, "123" },
}

describe("reformat_chunks", function()
	for _, test in ipairs(tests_reformat_chunks) do
		it("should insert spaces between chunks " .. test[1][1], function()
			local result = format.reformat_chunks(test[1][1], test[1][2])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_reformat_lines = {
	{ { "12345678", 8, 4 }, "1234 5678" },
	{ { "1234567812345678", 8, 4 }, "1234 5678\n1234 5678" },
	{ { "1234567812345678", 8, 2 }, "12 34 56 78\n12 34 56 78" },
	{ { "1234567812345678", 8, 3 }, "123 456 781\n234 567 8" },
	{ { "1234567812345678", 8, 1 }, "1 2 3 4 5 6 7 8\n1 2 3 4 5 6 7 8" },
	{ { "1234567812345678123", 8, 4 }, "1234 5678\n1234 5678\n123" },
	{ { "12345678123456781234", 8, 4 }, "1234 5678\n1234 5678\n1234" },
	{ { "123456781234567812345", 8, 4 }, "1234 5678\n1234 5678\n1234 5" },
}

describe("reformat_lines", function()
	for _, test in ipairs(tests_reformat_lines) do
		it("should reformat lines and insert spaces between chunks " .. test[1][1], function()
			local result = format.reformat_lines(test[1][1], test[1][2], test[1][3])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_join_lines = {
	{ { "", "", "1234 5678", "12 ab c", "d e f", "" }, "1234567812abcdef" },
	{ { "1234 5678", "12 ab c", "d e f" }, "1234567812abcdef" },
	{ { "1234 5678", "12 ab c", "d e f", "" }, "1234567812abcdef" },
	{ { "1234 5678", "12 ab c", "d e f", "1234 5678", "12 ab c", "d e f" }, "1234567812abcdef1234567812abcdef" },
}

describe("join_lines", function()
	for _, test in ipairs(tests_join_lines) do
		it("should join lines " .. test[2], function()
			local result = format.join_lines(test[1])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_format_lines = {
	{ { { "", "", "1234 5678", "12 ab c", "d e f", "" }, 8, 4 }, { "1234 5678", "12ab cdef" } },
	{ { { "1234 5678", "12 ab c", "d e f" }, 8, 4 }, { "1234 5678", "12ab cdef" } },
	{ { { "1234 5678", "12 ab c", "d e f", "" }, 8, 4 }, { "1234 5678", "12ab cdef" } },
	{
		{ { "1234 5678", "12 ab c", "d e f", "1234 5678", "12 ab c", "d e f" }, 8, 4 },
		{ "1234 5678", "12ab cdef", "1234 5678", "12ab cdef" },
	},
}

describe("format_lines", function()
	for i, test in ipairs(tests_format_lines) do
		it("should format lines " .. i, function()
			local result = format.format_lines(test[1][1], test[1][2], test[1][3])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_hex_to_printables = {
	{ "12 34 56", ".4V" },
	{ "01010203051068656c6c6f", "......hello" },
}

describe("hex_to_printables", function()
	for _, test in ipairs(tests_hex_to_printables) do
		it("should convert hex to printables " .. test[1], function()
			local result = format.hex_to_printables(test[1])
			assert.are.same(test[2], result)
		end)
	end
end)

local tests_printables_to_hex = {
	{ { ".4V", "123456" }, "123456" },
	{ { ".4W", "123456" }, "123457" },
	{ { "WWW", "123456" }, "575757" },
	{ { "...", "123456" }, "123456" },
	{ { ".ABC..hello", "01010203051068656c6c6f" }, "01414243051068656c6c6f" },
	{ { ".ABC..hello", "010102030510" }, "01414243051068656c6c6f" },
	{ { ".ABC..hello", "" }, "2e4142432e2e68656c6c6f" },
}

describe("printables_to_hex", function()
	for _, test in ipairs(tests_printables_to_hex) do
		it("should convert printables to hex " .. test[1][1], function()
			local result = format.printables_to_hex(test[1][1], test[1][2])
			assert.are.same(test[2], result)
		end)
	end
end)
