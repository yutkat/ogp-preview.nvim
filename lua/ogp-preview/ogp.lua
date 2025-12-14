local M = {}

local config = require("ogp-preview.config")

local function get_cache_path(url_str)
	local opts = config.get()
	local hash = vim.fn.sha256(url_str)
	return opts.cache_dir .. "/" .. hash .. ".png"
end

local function is_cache_valid(cache_path)
	local opts = config.get()
	local stat = vim.uv.fs_stat(cache_path)
	if not stat then
		return false
	end

	local age = os.time() - stat.mtime.sec
	return age < opts.cache_ttl
end

local function extract_ogp_image_url(html)
	local patterns = {
		'property="og:image"[^>]*content="([^"]+)"',
		"property='og:image'[^>]*content='([^']+)'",
		'content="([^"]+)"[^>]*property="og:image"',
		"content='([^']+)'[^>]*property='og:image'",
		'<meta[^>]+og:image[^>]+content="([^"]+)"',
		'<meta[^>]+content="([^"]+)"[^>]+og:image',
	}

	for _, pattern in ipairs(patterns) do
		local match = html:match(pattern)
		if match then
			return match
		end
	end

	return nil
end

local user_agent =
	"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

local function curl_get(url, output_file, cb)
	local args = {
		"curl",
		"-sL",
		"-A",
		user_agent,
		"-H",
		"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		"-H",
		"Accept-Language: en-US,en;q=0.5",
		"--compressed",
	}

	if output_file then
		table.insert(args, "-o")
		table.insert(args, output_file)
	end

	table.insert(args, url)

	vim.system(args, { text = output_file == nil }, function(result)
		vim.schedule(function()
			cb(result)
		end)
	end)
end

M.fetch_ogp_image = function(url_str, callback)
	local cache_path = get_cache_path(url_str)

	if is_cache_valid(cache_path) then
		vim.schedule(function()
			callback(cache_path)
		end)
		return
	end

	curl_get(url_str, nil, function(result)
		if result.code ~= 0 or not result.stdout then
			callback(nil)
			return
		end

		local ogp_image_url = extract_ogp_image_url(result.stdout)
		if not ogp_image_url then
			callback(nil)
			return
		end

		curl_get(ogp_image_url, cache_path, function(dl_result)
			if dl_result.code == 0 then
				local stat = vim.uv.fs_stat(cache_path)
				if stat and stat.size > 1000 then
					callback(cache_path)
				else
					vim.fn.delete(cache_path)
					callback(nil)
				end
			else
				callback(nil)
			end
		end)
	end)
end

-- For testing
M._extract_ogp_image_url = extract_ogp_image_url

return M
