local hex = require("hexblade.hex")

local vector = {
	{ { "68656c6c6f" }, { "hello" } },
	{ { "776f726c64" }, { "world" } },
	{
		{ "68656c6c6f", "776f726c64" },
		{ "helloworld" },
	},
	{
		{ "68656c6c6f", "776f726c64", "6f6e65" },
		{ "helloworldone" },
	},
	{
		{
			"7f454c4602",
			"0101000000",
			"0000000000",
			"0003003e00",
			"0100000040",
			"1000000000",
			"0a000a0000",
			"0000000000",
			"8d00000000",
			"000000",
		},
		{
			"\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x3e\x00\x01\x00\x00\x00\x40\x10\x00\x00\x00\x00",
			"\x00",
			"\x00\x00\x00\x00\x00\x00\x00\x8d\x00\x00\x00\x00\x00\x00\x00",
		},
	},
}

describe("hex2bin", function()
	for i, v in ipairs(vector) do
		it("converts hex strings to binary data i=" .. i, function()
			assert.are.same(v[2], hex.hex2bin(v[1]))
		end)
	end
end)

describe("bin2hex", function()
	for i, v in ipairs(vector) do
		it("converts binary data to hex strings i=" .. i, function()
			assert.are.same(v[1], hex.bin2hex(v[2], 5))
		end)
	end
end)

describe("hex2bin and bin2hex", function()
	for i, v in ipairs(vector) do
		it("converts hex strings to binary data and back to hex strings i=" .. i, function()
			assert.are.same(v[1], hex.bin2hex(hex.hex2bin(v[1]), 5))
			assert.are.same(v[2], hex.hex2bin(hex.bin2hex(v[2], 5)))
		end)
	end
end)
