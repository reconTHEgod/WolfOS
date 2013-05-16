-- WolfOS build script

--[[
Credit goes to 'immibis' for the compression/decompression code, and to 'oeed' for the original package maker code.
Modified and unified into one smooth working system by 'toxicwolf'.
]]--

local sSource, sDest, sName, sVer = "/rom", "/", "WolfOS.pkg", "2.0.0_a1"

local sPackage = "local pkg = %@1 local function decompress(inText) local inPos = 1 local huffmanCompression = true if huffmanCompression then local inBits = {} for k = 1, #inText do local byte = inText:sub(k, k):byte() - 32 for i = 0, 5 do local testBit = 2 ^ i inBits[#inBits + 1] = (byte % (2 * testBit)) >= testBit end end local padbit = inBits[#inBits] while inBits[#inBits] == padbit do inBits[#inBits] = nil end local pos = 1 local function readBit() if pos > #inBits then error(\"end of stream\", 2) end pos = pos + 1 return inBits[pos - 1] end local function readTree() if readBit() then local byte = 0 for i = 0, 7 do if readBit() then byte = byte + 2 ^ i end end return string.char(byte) else local subtree_0 = readTree() local subtree_1 = readTree() return {[false]=subtree_0, [true]=subtree_1} end end local tree = readTree() inText = \"\" local treePos = tree while pos <= #inBits do local bit = readBit() treePos = treePos[bit] if type(treePos) ~= \"table\" then inText = inText..treePos treePos = tree end end if treePos ~= tree then error(\"unexpected end of stream\") end end local function readTo(delim) local start = inPos local nextCaret = inText:find(delim, inPos, true) if not nextCaret then inPos = #inText + 1 return inText:sub(start) end inPos = nextCaret + 1 return inText:sub(start, nextCaret - 1) end local function splitString(str, delim) local pos = 1 return function() if pos > #str then return end local start = pos local nextDelim = str:find(delim, pos, true) if not nextDelim then pos = #str + 1 return str:sub(start) end pos = nextDelim + 1 return str:sub(start, nextDelim - 1) end end local nameTable = {} local idents = \"abcdefghijklmnopqrstvuwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_\" local nextCompressed do local validchars = idents:gsub(\"_\",\"\") local function encode(n) local s = \"\" while n > 0 do local digit = (n % #validchars) + 1 s = s..validchars:sub(digit, digit) n = math.floor(n / #validchars) end return s end local next = 0 function nextCompressed() next = next + 1 return encode(next) end end for k = 1, tonumber(readTo(\"^\")) do local key = nextCompressed() local value = readTo(\"^\") nameTable[key] = value end local out = \"\" local function onFinishSegment(isIdent, segment) if isIdent then if segment:sub(1, 1) == \"_\" then out = out..segment:sub(2) else out = out..tostring(nameTable[segment]) end else out = out..segment end end local parsed = {} local idents = \"abcdefghijklmnopqrstvuwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_\" local lastIdent = nil for k = inPos, #inText do local ch = inText:sub(k, k) local isIdent = idents:find(ch, 1, true) ~= nil if isIdent ~= lastIdent then if #parsed > 0 then onFinishSegment(lastIdent, parsed[#parsed]) end parsed[#parsed+1] = \"\" end lastIdent = isIdent parsed[#parsed] = parsed[#parsed]..ch end if #parsed > 0 then onFinishSegment(isIdent, parsed[#parsed]) end local out2 = \"\" local lastIndent = \"\" for line in splitString(out, \"\\n\") do while line:sub(1,2) == \"&+\" do lastIndent = lastIndent..\"\\t\" line = line:sub(3) end while line:sub(1,2) == \"&-\" do lastIndent = lastIndent:sub(1, #lastIndent - 1) line = line:sub(3) end if line:sub(1,2) == \"&&\" then line = line:sub(2) end out2 = out2..lastIndent..line..\"\\n\" end return out2 end local function makeFile(_path, _content) local file = fs.open(_path, \"w\") _content = decompress(_content) _content = _content:gsub(\"\!@\"..\"#&\", \"%\\n\")_content = textutils.unserialize(_content) file.write(_content) file.close() end local function makeFolder(_path, _content) fs.makeDir(_path) for k,v in pairs(_content) do if type(v) == \"table\" then makeFolder(_path..\"/\"..k, v) else makeFile(_path..\"/\"..k, v) end end end local tPackage = pkg makeFolder(\"%@2\", tPackage) fs.delete(\"%@3\") print(\"WolfOS %@4 successfully installed!\")"

local function compress(inText)
	local function countTabs(l)
		for k = 1, #l do
			if l:sub(k, k) ~= "\t" then
				return k - 1
			end
		end
		return #l
	end
	
	local compressNonIdentGroups = false
	local huffmanEncode = true
	
	-- read input
	local lines = {}
	local line = inText:sub(1, string.find(inText, "\n"))
	while line ~= "" do
		lines[#lines+1] = line
		inText = inText:sub(#line+1)
		line = inText:sub(1, string.find(inText, "\n"))
	end
	lines[#lines+1] = inText
	
	-- convert indentation
	local inText = ""
	local lastIndent = 0
	for lineNo, line in ipairs(lines) do
		local thisIndent = countTabs(line)
		local nextIndent = lines[lineNo+1] and countTabs(lines[lineNo+1]) or thisIndent
		local prevIndent = lines[lineNo-1] and countTabs(lines[lineNo-1]) or 0
		
		if thisIndent > nextIndent and thisIndent > prevIndent then
			thisIndent = math.min(nextIndent, prevIndent)
		end
		
		while lastIndent < thisIndent do
			inText = inText .. "&+"
			lastIndent = lastIndent + 1
		end
		while lastIndent > thisIndent do
			inText = inText .. "&-"
			lastIndent = lastIndent - 1
		end
		
		if line:sub(1,1) == "&" then
			line = "&" .. line
		end
		
		inText = inText .. line:sub(lastIndent+1) .. "\n"
	end
	
	
	-- parse into alternating strings of alphanumerics and non-alphanumerics
	local parsed = {}
	local idents = "abcdefghijklmnopqrstvuwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	local lastIdent = nil
	
	local function isIdentString(s)
		return idents:find(s:sub(1,1), 1, true) ~= nil
	end
	
	local groupCounts = {}
	
	local function onFinishSegment(isIdent, segment)
		if isIdent or compressNonIdentGroups then
			groupCounts[segment] = (groupCounts[segment] or 0) + 1
		end
	end
	
	for k = 1, #inText do
		local ch = inText:sub(k, k)
		local isIdent = idents:find(ch, 1, true) ~= nil
		if isIdent ~= lastIdent then
			if #parsed > 0 then
				onFinishSegment(lastIdent, parsed[#parsed])
			end
			parsed[#parsed+1] = ""
		end
		lastIdent = isIdent
		parsed[#parsed] = parsed[#parsed]..ch
	end
	if #parsed > 0 then
		onFinishSegment(isIdent, parsed[#parsed])
	end
	
	local id_literal_escape = "_"
	local pc_literal_escape = "$"
	
	local nextCompressed
	do
		local validchars_id = idents:gsub(id_literal_escape,"")
		local validchars_pc = ""
		
		for n=32,126 do
			local ch = string.char(n)
			if not idents:find(ch,1,true) and ch ~= pc_literal_escape then
				validchars_pc = validchars_pc .. ch
			end
		end
		
		local function encode(n, isIdent)
			local s = ""
			local validchars = isIdent and validchars_id or validchars_pc
			while n > 0 do
				local digit = (n % #validchars) + 1
				s = s .. validchars:sub(digit, digit)
				n = math.floor(n / #validchars)
			end
			return s
		end
		
		local next = {[true]=0,[false]=0}
		function nextCompressed(isIdent)
			next[isIdent] = next[isIdent] + 1
			return encode(next[isIdent], isIdent)
		end
	end
	
	local groupsSorted = {}
	local groups = {}
	for k, v in pairs(groupCounts) do
		if (#k > 1 and v > 1) or k:find(isIdentString(k) and id_literal_escape or pc_literal_escape) then
			local t = {k, v}
			groups[k] = t
			table.insert(groupsSorted, t)
		end
	end
	
	local avgCompressedLength = 2
	
	local function estSavings(a)
		local str = a[1]
		local count = a[2]
		local compressedLength = a[3] and #a[3] or avgCompressedLength
		
		-- estimates the number of chars saved by compressing this group
		
		-- it costs #str+1 chars to encode the group literally, or about compressedLength chars to compress it
		-- so by compressing it, each time the group occurs we save (#str + 1 - compressedLength) chars
		local saved = (#str + 1 - compressedLength) * count
		
		-- but we also use about #str + 1 chars in the name table if we compress it.
		saved = saved - (#str + 1)
		
		return saved
	end
	
	table.sort(groupsSorted, function(a, b)
		return estSavings(a) > estSavings(b)
	end)
	
	for _, v in ipairs(groupsSorted) do
		v[3] = nextCompressed(isIdentString(v[1]))
	end
	
	local out = #groupsSorted .. "^"
	for _, v in ipairs(groupsSorted) do
		local encoded = v[1]:gsub("&", "&a"):gsub("%^","&b")
		out = out .. encoded .. "^"
	end
	for _, v in pairs(parsed) do
		if groups[v] then
			out = out .. groups[v][3]
		elseif isIdentString(v) then
			out = out .. id_literal_escape .. v
		elseif compressNonIdentGroups then
			out = out .. pc_literal_escape .. v
		else
			out = out .. v
		end
	end
	
	if huffmanEncode then
		-- generate a huffman tree - first we need to count the number of times each symbol occurs
		local symbolCounts = {}
		local numSymbols = 0
		for k = 1, #out do
			local sym = out:sub(k,k)
			if not symbolCounts[sym] then
				numSymbols = numSymbols + 1
				symbolCounts[sym] = 1
			else
				symbolCounts[sym] = symbolCounts[sym] + 1
			end
		end
		
		-- convert them to tree nodes and sort them by count, ascending order
		-- a tree node is either {symbol, count} or {{subtree_0, subtree_1}, count}
		local treeFragments = {}
		for sym, count in pairs(symbolCounts) do
			treeFragments[#treeFragments + 1] = {sym, count}
		end
		table.sort(treeFragments, function(a, b)
			return a[2] < b[2]
		end)
		
		while #treeFragments > 1 do
			-- take the two lowest-count fragments and combine them
			local a = table.remove(treeFragments, 1)
			local b = table.remove(treeFragments, 1)
			
			local newCount = a[2] + b[2]
			local new = {{a, b}, newCount}
			
			-- insert the new fragment in the right place
			if #treeFragments == 0 or newCount > treeFragments[#treeFragments][2] then
				table.insert(treeFragments, new)
			else
				local ok = false
				for k=1,#treeFragments do
					if treeFragments[k][2] >= newCount then
						table.insert(treeFragments, k, new)
						ok = true
						break
					end
				end
				assert(ok, "internal error: couldn't find place for tree fragment")
			end
		end
		
		local symbolCodes = {}
		
		local function shallowCopyTable(t)
			local rv = {}
			for k,v in pairs(t) do
				rv[k] = v
			end
			return rv
		end
		
		-- now we have a huffman tree (codes -> symbols) but we need a map of symbols -> codes, so do that
		local function iterate(root, path)
			if type(root[1]) == "table" then
				local t = shallowCopyTable(path)
				t[#t+1] = false
				iterate(root[1][1], t)
				path[#path+1] = true
				iterate(root[1][2], path)
			else
				symbolCodes[root[1]] = path
			end
		end
		iterate(treeFragments[1], {})
		
		local rv = {}
		
		local symbolBitWidth = 8
		
		local function writeTree(tree)
			if type(tree[1]) == "table" then
				rv[#rv+1] = false
				writeTree(tree[1][1])
				writeTree(tree[1][2])
			else
				rv[#rv+1] = true
				local symbol = tree[1]:byte()
				for k = 0, symbolBitWidth - 1 do
					
					local testBit = 2 ^ k
					
					local bit = (symbol % (2 * testBit)) >= testBit
					rv[#rv+1] = bit
				end
			end
		end
		
		writeTree(treeFragments[1])
		
		for k = 1, #out do
			local symbol = out:sub(k,k)
			for _, bit in ipairs(symbolCodes[symbol] or error("internal error: symbol "..symbol.." has no code")) do
				rv[#rv+1] = bit
			end
		end
		
		-- convert the array of bits (rv) back to characters
		
		local s = ""
		
		-- write 6 bits per byte because LuaJ (and/or CC)	
		local bitsPerByte = 6
		local firstCharacter = 32
		
		-- pad to an integral number of bytes
		local padbit = not rv[#rv]
		repeat
			rv[#rv+1] = padbit
		until (#rv % bitsPerByte) == 0
		
		for k = 1, #rv, bitsPerByte do
			local byte = firstCharacter
			for i = 0, bitsPerByte-1 do
				if rv[k+i] then 	
					byte = byte + 2 ^ i
				end
			end
			s = s .. string.char(byte)
		end
		
		out = s
	end
	
	return out
end

local function addFile(_package, _path)
	if string.find(_path, ".moon") or string.find(_path, "CraftOS") then
		return _package
	end
	
	local file, err = fs.open(_path, "r")
	
	local content = file.readAll()
	content = content:gsub("%%@VERSION", function() return sVer end)
	content = content:gsub("%\n", "\!@".."#&")
	content = compress(content)
	_package[fs.getName(_path)] = content
	file.close()
	
	return _package
end

local function addFolder(_package, _path)
	if not (string.find(_path, "WolfOS") or string.find(_path, "boot") or _path == "/rom") then
		return nil
	end
	
	_package = _package or {}
	for _,f in ipairs(fs.list(_path)) do
		local path = _path.."/"..f
		if fs.isDir(path) then
			_package[fs.getName(f)] = addFolder(_package[fs.getName(f)], path)
		elseif not fs.isDir(path) and (string.find(_path, "WolfOS") or string.find(_path, "boot")) then
			_package =  addFile(_package, path)
		end
	end
	return _package
end

if fs.exists( sSource ) and fs.isDir( sSource ) then
	local tPackage = {}
	tPackage = addFolder(tPackage, sSource)
	
	local fPackage = fs.open(sName,"w")
	
	sPackage = string.gsub(sPackage, "%%@4", sVer)
	sPackage = string.gsub(sPackage, "%%@3", sName)
	sPackage = string.gsub(sPackage, "%%@2", sDest)
	sPackage = string.gsub(sPackage, "%%@1", function() return textutils.serialize(tPackage) end)	
	fPackage.write(sPackage)
	fPackage.close()
	print("Package built! ('"..sName.."')")
else
	error("Source does not exist or is not a folder.", 0)
end
