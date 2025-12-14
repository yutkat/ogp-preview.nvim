local M = {}

local github_patterns = {
	"https?://github%.com/[%w%-_%.]+/[%w%-_%.]+",
	"https?://www%.github%.com/[%w%-_%.]+/[%w%-_%.]+",
	"github%.com/[%w%-_%.]+/[%w%-_%.]+",
	"([%w%-_%.]+)/([%w%-_%.]+)",
}

local function clean_url(url_str)
	url_str = url_str:gsub("[%[%]%(%)%{%}\"'<>,%s]+$", "")
	url_str = url_str:gsub("^[%[%]%(%)%{%}\"'<>,%s]+", "")
	return url_str
end

local function is_valid_github_path(owner, repo)
	if not owner or not repo then
		return false
	end

	local reserved = {
		"about",
		"explore",
		"topics",
		"trending",
		"collections",
		"events",
		"sponsors",
		"login",
		"signup",
		"settings",
		"notifications",
		"new",
		"organizations",
		"orgs",
		"users",
		"apps",
		"marketplace",
		"pulls",
		"issues",
		"codespaces",
		"features",
		"enterprise",
		"team",
		"pricing",
		"security",
		"customer-stories",
	}

	for _, r in ipairs(reserved) do
		if owner:lower() == r then
			return false
		end
	end

	return true
end

local function normalize_url(url_str)
	url_str = url_str:gsub("/pull/.*$", "")
	url_str = url_str:gsub("/issues/.*$", "")
	url_str = url_str:gsub("/blob/.*$", "")
	url_str = url_str:gsub("/tree/.*$", "")
	url_str = url_str:gsub("/commit/.*$", "")
	url_str = url_str:gsub("/releases.*$", "")
	url_str = url_str:gsub("/actions.*$", "")
	url_str = url_str:gsub("/wiki.*$", "")
	url_str = url_str:gsub("#.*$", "")
	url_str = url_str:gsub("%?.*$", "")
	url_str = url_str:gsub("/$", "")
	return url_str
end

M.extract_github_url = function(text)
	if not text or text == "" then
		return nil
	end

	text = clean_url(text)

	if text:match("^https?://") then
		for i = 1, 2 do
			local match = text:match(github_patterns[i])
			if match then
				return normalize_url(match)
			end
		end
		return nil
	end

	if text:match("^github%.com/") then
		local match = text:match(github_patterns[3])
		if match then
			return "https://" .. normalize_url(match)
		end
		return nil
	end

	local owner, repo = text:match("^([%w%-_%.]+)/([%w%-_%.]+)$")
	if owner and repo and is_valid_github_path(owner, repo) then
		return "https://github.com/" .. owner .. "/" .. repo
	end

	return nil
end

M.is_github_url = function(text)
	return M.extract_github_url(text) ~= nil
end

return M
