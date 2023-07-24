local lfs = require("lfs")
local M = {}

M._getFilesWithExtension = function(dir, extension, files)
	local files_out = files or {}

	for file in lfs.dir(dir) do
		if file ~= "." and file ~= ".." then
			local path = dir .. "/" .. file
			local mode = lfs.attributes(path, "mode")
			if mode == "file" then
				if file:sub(-#extension) == extension then
					table.insert(files_out, path)
				end
			elseif mode == "directory" then
				M._getFilesWithExtension(path, extension, files_out)
			end
		end
	end
	return files_out
end

M._read = function(path)
	local items = {}

	for line in io.lines(path) do
		local name, value = line:match("(%S+):%s+(%S+);")
		if name and value then
			table.insert(items, { name = name, value = value })
		end
	end
	return items
end

M._write = function(path, data)
	local h = io.open(path, "w")
	if data then
		h:write(data)
	end
	io.close(h)
end

M.to_item = function(name, value)
	return ("{ word = '%s'; label = '%s'; insertText = '%s'; filterText = '%s' };\n"):format(
		name,
		name .. " " .. value .. ";",
		name,
		name .. " " .. value .. ";"
	)
end

M.update = function(...)
	local items = ""
	local nritems = 0
	local dirs = false

	for _, arg in ipairs({ ... }) do
		local success, _ = pcall(lfs.dir, arg)
		if success then
			print("Processing dir " .. arg)
			local files = M._getFilesWithExtension(arg, "scss")
			for _, file in ipairs(files) do
				for _, item in ipairs(M._read(file)) do
					dirs = true
					nritems = nritems + 1
					items = items .. M.to_item(item.name, item.value)
				end
			end
		end
	end
	if dirs then
		print("Updating items.lua with " .. nritems .. " items")
		M._write("./items.lua", ("return function() return {\n%s} end"):format(items))
	end
	if nritems == 0 then
		print("No items found, did you provide a @dnr-ui/tokens/scss directory?")
	end
end

-- { word = ":keycap_star:", label = "*️⃣ :keycap_star:", insertText = "*️⃣", filterText = ":keycap_star:", },
M.update(...)
return M
