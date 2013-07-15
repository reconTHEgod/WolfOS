--[[
Copyright (C) 2012 Thomas Farr a.k.a tomass1996 [farr.thomas@gmail.com]

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

local Hash = os.getApi("Hash")

local function basen(n,b)
	if n < 0 then
		n = -n
	end
       local t = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz{|}~"
   if n < b then
	local ret = ""
	ret = ret..string.sub(t, (n%b)+1,(n%b)+1)
	return ret
   else
	local tob = tostring(basen(math.floor(n/b), b))
	local ret = tob..t:sub((n%b)+1,(n%b)+1)
	return ret
   end
end

local Base64 = {}
Base64["lsh"] = function(value,shift)
    return (value*(2^shift)) % 256
end
Base64["rsh"] = function(value,shift)
    return math.floor(value/2^shift) % 256
end
Base64["bit"] = function(x,b)
    return (x % 2^b - x % 2^(b-1) > 0)
end
Base64["lor"] = function(x,y)
    local result = 0
    for p=1,8 do result = result + (((Base64.bit(x,p) or Base64.bit(y,p)) == true) and 2^(p-1) or 0) end
    return result
end
Base64["base64chars"] = {
    [0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',
    [11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',
    [21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',
    [31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',
    [41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',
    [51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',
    [61]='9',[62]='-',[63]='_'}
Base64["base64bytes"] = {
    ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,
    ['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,
    ['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,
    ['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,
    ['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,
    ['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,
    ['9']=61,['-']=62,['_']=63,['=']=nil}

function find(str, match, startIndex)  --Finds @match in @str optionally after @startIndex
	if not match then return nil end
	str = tostring(str)
	local _ = startIndex or 1
	local _s = nil
	local _e = nil
	local _len = match:len()
	while true do
		local _t = str:sub( _ , _len + _ - 1)
		if _t == match then
			_s = _
			_e = _ + _len - 1
			break
		end
		_ = _ + 1
		if _ > str:len() then break end
	end
	if _s == nil then return nil else return _s, _e end
end

function jumble(str)  --Jumbles @str
	if not str then return nil end
	str = tostring(str)
	local chars = {}
	for i = 1, #str do
		chars[i] = str:sub(i, i)
	end
	local usedNums = ":"
	local res = ""
	local rand = 0
	for i=1, #chars do
		while true do
			rand = math.random(#chars)
			if find(usedNums, ":"..rand..":") == nil then break end
		end
		res = res..chars[rand]
		usedNums = usedNums..rand..":"
	end
	return res
end

function toBase64(str)  --Encodes @str in Base64
	if not str then return nil end
	str = tostring(str)
	local bytes = {}
	local result = ""
	for spos=0,str:len()-1,3 do
		for byte=1,3 do bytes[byte] = str:byte(spos+byte) or 0 end
		result = string.format('%s%s%s%s%s',result,Base64.base64chars[Base64.rsh(bytes[1],2)],Base64.base64chars[Base64.lor(Base64.lsh((bytes[1] % 4),4), Base64.rsh(bytes[2],4))] or "=",((str:len()-spos) > 1) and Base64.base64chars[Base64.lor(Base64.lsh(bytes[2] % 16,2), Base64.rsh(bytes[3],6))] or "=",((str:len()-spos) > 2) and Base64.base64chars[(bytes[3] % 64)] or "=")
	end
	return result
end

function fromBase64(str)  --Decodes @str from Base64
	if not str then return nil end
	str = tostring(str)
	local chars = {}
	local result=""
	for dpos=0,str:len()-1,4 do
		for char=1,4 do chars[char] = Base64.base64bytes[(str:sub((dpos+char),(dpos+char)) or "=")] end
		result = string.format('%s%s%s%s',result,string.char(Base64.lor(Base64.lsh(chars[1],2), Base64.rsh(chars[2],4))),(chars[3] ~= nil) and string.char(Base64.lor(Base64.lsh(chars[2],4), Base64.rsh(chars[3],2))) or "",(chars[4] ~= nil) and string.char(Base64.lor(Base64.lsh(chars[3],6) % 192, (chars[4]))) or "")
	end
	return result
end

function encrypt(str, key)  --Encrypts @str with @key
	if not key then return nil end
	str = tostring(str)
	local alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz{|}~"
	local _rand = math.random(#alphabet-10)
	local iv = string.sub(jumble(alphabet), _rand, _rand  + 9)
	iv = jumble(iv)
	str = iv..str
	local key = Hash.sha256(key)
	local strLen = str:len()
	local keyLen = key:len()
	local j=1
	local result = ""
	for i=1, strLen do
		local ordStr = string.byte(str:sub(i,i))
		if j == keyLen then j=1 end
		local ordKey = string.byte(key:sub(j,j))
		result = result..string.reverse(basen(ordStr+ordKey, 36))
		j = j+1
	end
	return result
end

function decrypt(str, key)  --Decrypts @str with @key
	if not key then return nil end
	str = tostring(str)
	local key = Hash.sha256(key)
	local strLen = str:len()
	local keyLen = key:len()
	local j=1
	local result = ""
	for i=1, strLen, 2 do
		local ordStr = basen(tonumber(string.reverse(str:sub(i, i+1)),36),10)
		if j==keyLen then j=1 end
		local ordKey = string.byte(key:sub(j,j))
		result = result..string.char(ordStr-ordKey)
		j = j+1
	end
	return result:sub(11)
end

function setRandSeed(seed)  --Sets random seed to @seed
	math.randomseed(seed)
end

setRandSeed(os.time())
