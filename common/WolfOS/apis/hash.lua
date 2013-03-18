--[[
Copyright © 2012 Esteban Hermida a.k.a MysticT

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

-The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-Visible credit is given to the original author.
-The software is distributed in a non-profit way.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local bit32 = require(os.getSystemDir("apis").."bit32..lua")

local bnot, band, bor, bxor = bit32.bnot, bit32.band, bit32.bor, bit32.bxor
local lshift, rshift = bit32.lshift, bit32.rshift
local lrotate, rrotate = bit32.lrotate, bit32.rrotate

local function beInt(s)
	local v = 0
	for i = 1, #s do
		v = v * 256 + string.byte(s, i)
	end
	return v
end

local function leInt(s)
	local v = 0
	for i = #s, 1, -1 do
		v = v * 256 + string.byte(s, i)
	end
	return v
end

local function beIntStr(l, n)
	local s = ""
	for i = 1, n do
		local r = l % 256
		s = string.char(r)..s
		l = (l - r) / 256
	end
	return s
end

local function leIntStr(l, n)
	local s = ""
	for i = 1, n do
		local r = l % 256
		s = s..string.char(r)
		l = (l - r) / 256
	end
	return s
end

local function beStrSplit(s, n, len)
	local t = {}
	local p = 1
	for i = 1, n do
		table.insert(t, beInt(string.sub(s, p, p + len - 1)))
		p = p + len
	end
	return t
end

local function leStrSplit(s, n, len)
	local t = {}
	local p = 1
	for i = 1, n do
		table.insert(t, leInt(string.sub(s, p, p + len - 1)))
		p = p + len
	end
	return t
end

-- SHA256

local sha_consts = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local function sha_digest(h0, h1, h2, h3, h4, h5, h6, h7, w)
	local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
	for i = 1, 64 do
		local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = bxor(band(a, b), band(a, c), band(b, c))
		local t2 = S0 + maj
		local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = bxor(band(e, f), band(bnot(e), g))
		local t1 = h + S1 + ch + sha_consts[i] + w[i]
		h = g
		g = f
		f = e
		e = d + t1
		d = c
		c = b
		b = a
		a = t1 + t2
	end
	h0 = band(h0 + a)
	h1 = band(h1 + b)
	h2 = band(h2 + c)
	h3 = band(h3 + d)
	h4 = band(h4 + e)
	h5 = band(h5 + f)
	h6 = band(h6 + g)
	h7 = band(h7 + h)
	return h0, h1, h2, h3, h4, h5, h6, h7
end

function sha256(s)
	local len = #s
	local pad = 56 - (len % 64)
	if (len % 64) > 56 then
		pad = pad + 64
	end
	if pad == 0 then
		pad = 64
	end
	s = s.."\128"..string.rep("\0", pad - 1)..beIntStr(len * 8, 8)
	local h0, h1, h2, h3, h4, h5, h6, h7 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
	for i = 1, #s, 64 do
		local w = beStrSplit(string.sub(s, i, i + 63), 16, 4)
		for j = 17, 64 do
			local v = w[j - 15]
			local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
			v = w[j - 2]
			local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
			w[j] = w[j - 16] + s0 + w[j - 7] + s1
		end
		h0, h1, h2, h3, h4, h5, h6, h7 = sha_digest(h0, h1, h2, h3, h4, h5, h6, h7, w)
	end
	return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end