local M = {}

local config = require("ogp-preview.config")
local ogp = require("ogp-preview.ogp")
local sixel = require("ogp-preview.sixel")
local url = require("ogp-preview.url")

local auto_preview_enabled = false
local auto_preview_augroup = nil
local last_url = nil

M.setup = function(opts)
	config.setup(opts)

	vim.api.nvim_create_user_command("OgpPreview", function()
		M.preview()
	end, { desc = "Show OGP preview for GitHub repository under cursor" })

	vim.api.nvim_create_user_command("OgpPreviewClose", function()
		M.close()
	end, { desc = "Close OGP preview window" })

	vim.api.nvim_create_user_command("OgpPreviewEnable", function()
		M.enable()
	end, { desc = "Enable automatic OGP preview on cursor move" })

	vim.api.nvim_create_user_command("OgpPreviewDisable", function()
		M.disable()
	end, { desc = "Disable automatic OGP preview" })
end

M.enable = function()
	if auto_preview_enabled then
		return
	end

	auto_preview_enabled = true
	auto_preview_augroup = vim.api.nvim_create_augroup("OgpPreviewAuto", { clear = true })

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = auto_preview_augroup,
		callback = function()
			local current_word = vim.fn.expand("<cWORD>")
			local repo_url = url.extract_github_url(current_word)

			if repo_url then
				if repo_url ~= last_url then
					last_url = repo_url
					M.close()
					ogp.fetch_ogp_image(repo_url, function(image_path)
						if image_path then
							sixel.show(image_path, false)
						end
					end)
				end
			else
				if last_url then
					M.close()
					last_url = nil
				end
			end
		end,
	})

	vim.notify("OGP Preview enabled", vim.log.levels.INFO)
end

M.disable = function()
	if not auto_preview_enabled then
		return
	end

	auto_preview_enabled = false
	last_url = nil

	if auto_preview_augroup then
		vim.api.nvim_del_augroup_by_id(auto_preview_augroup)
		auto_preview_augroup = nil
	end

	M.close()
	vim.notify("OGP Preview disabled", vim.log.levels.INFO)
end

M.preview = function()
	local current_word = vim.fn.expand("<cWORD>")
	local repo_url = url.extract_github_url(current_word)

	if not repo_url then
		vim.notify("No GitHub repository URL found under cursor", vim.log.levels.WARN)
		return
	end

	ogp.fetch_ogp_image(repo_url, function(image_path)
		if not image_path then
			vim.notify("Failed to fetch OGP image", vim.log.levels.ERROR)
			return
		end

		sixel.show(image_path)
	end)
end

M.close = function()
	sixel.close()
end

return M
