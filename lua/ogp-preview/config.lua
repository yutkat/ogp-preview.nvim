local M = {}

M.defaults = {
	width = 40,
	height = 20,
	cache_dir = vim.fn.stdpath("cache") .. "/ogp-preview",
	cache_ttl = 86400,
	converter = "chafa",
	-- Terminal cell size in pixels: { width, height }
	cell_size = { 10, 20 },
}

M.options = {}

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

	vim.fn.mkdir(M.options.cache_dir, "p")
end

M.get = function()
	if vim.tbl_isempty(M.options) then
		M.setup({})
	end
	return M.options
end

return M
