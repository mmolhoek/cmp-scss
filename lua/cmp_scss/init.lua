local source = {}
local options
local items = require("cmp_scss.items")

source.new = function()
	local self = setmetatable({}, { __index = source })
	self.commit_items = nil
	self.insert_items = nil
	return self
end

source.get_trigger_characters = function(self, params)
	return self:option(params).triggers
end

source.get_keyword_pattern = function(self, params)
	return self:option(params).pattern
end

source.complete = function(self, params, callback)
	if self:option(params).insert then
		if not self.insert_items then
			self.insert_items = vim.tbl_map(function(item)
				item.word = nil
				return item
			end, items(self, params))
		end
		callback(self.insert_items)
	else
		if not self.commit_items then
			self.commit_items = items(self, params)
		end
		callback(self.commit_items)
	end
end
source.option = function(_, params)
	options = vim.tbl_extend("force", {
		insert = false,
		triggers = { "$" },
		pattern = [=[\%(\s\|^\)\zs\$[[:alnum:]_\-0-9]*:\?]=],
		extension = ".scss",
		folders = {},
	}, params.option)
	return options
end

return source
