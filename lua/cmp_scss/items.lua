local M = {}
M._path_sep = package.config:sub(1, 1)
-- Function to find the top-level directory of the project
M._find_first_node_modules_dir = function()
	-- Get the file path of the current buffer
	local file_path = vim.api.nvim_buf_get_name(0)

	-- Loop until we reach the top level (root) directory or an empty path
	while file_path ~= "" and file_path ~= "/" do
		-- Check if the .git directory exists in the current file path
		local git_dir = file_path .. "/node_modules"
		if vim.fn.isdirectory(git_dir) == 1 then
			return file_path
		end

		-- Remove the last directory component from the file path
		-- /Users/molhoe000/Projects/selectives/selectives-teaser-editor/aws/bin/
		file_path = file_path:match("^(.*)/[^/]-$")
	end

	-- If we reach this point, it means we couldn't find the .git folder,
	-- so we'll return the current working directory as a fallback.
	return vim.fn.getcwd()
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

M._scan_dir = function(dir)
	local items = {}

	local handle = vim.loop.fs_scandir(dir)
	if handle then
		while true do
			local name, typ = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			table.insert(items, {
				name = name,
				type = typ,
			})
		end
	end

	return items
end

M._getFilesWithExtension = function(dir, extension, files)
	local files_out = files or {}

	for _, f in ipairs(M._scan_dir(dir)) do
		local file = tostring(f.name)
		local type = tostring(f.type)
		if file ~= "." and file ~= ".." then
			local path = dir .. "/" .. file
			if type == "file" then
				if file:sub(-#extension) == extension then
					table.insert(files_out, path)
				end
			elseif type == "directory" then
				M._getFilesWithExtension(path, extension, files_out)
			end
		end
	end
	return files_out
end

M._load_items_from_all_folders = function(self, params)
	local items = {}
	local root_dir = M._find_first_node_modules_dir()
	local folders = self:option(params).folders
	for _, folder in ipairs(folders) do
		local start_folder = root_dir .. M._path_sep .. folder
		if vim.fn.isdirectory(start_folder) == 1 then
			local files = M._getFilesWithExtension(start_folder, self:option(params).extension)
			for _, file in ipairs(files) do
				for _, item in ipairs(M._read(file)) do
					table.insert(items, {
						word = item.name,
						label = item.name .. " " .. item.value,
						insertText = item.name,
						filterText = item.name .. " " .. item.value,
					})
				end
			end
		end
	end
	return items
end

return function(self, params)
	return M._load_items_from_all_folders(self, params)
end
