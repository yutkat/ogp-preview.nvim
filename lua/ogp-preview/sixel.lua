local M = {}

local config = require("ogp-preview.config")

local state = {
	displayed = false,
	last_row = nil,
	last_col = nil,
	last_width = nil,
	last_height = nil,
}

local function echoraw(str)
	vim.fn.chansend(vim.v.stderr, str)
end

local function get_cursor_row()
	local win_row = vim.fn.win_screenpos(0)[1]
	local cursor_row = vim.fn.winline()
	return win_row + cursor_row - 1
end

local ffi = require("ffi")
local ffi_initialized = false

local function query_terminal_cell_size()
	if not ffi_initialized then
		ffi.cdef([[
			struct winsize {
				unsigned short ws_row;
				unsigned short ws_col;
				unsigned short ws_xpixel;
				unsigned short ws_ypixel;
			};
			int ioctl(int fd, unsigned long request, ...);
		]])
		ffi_initialized = true
	end

	local TIOCGWINSZ = 0x5413 -- Linux
	local ws = ffi.new("struct winsize")

	if ffi.C.ioctl(1, TIOCGWINSZ, ws) == 0 then
		if ws.ws_xpixel > 0 and ws.ws_ypixel > 0 and ws.ws_col > 0 and ws.ws_row > 0 then
			local cell_w = math.floor(ws.ws_xpixel / ws.ws_col)
			local cell_h = math.floor(ws.ws_ypixel / ws.ws_row)
			return cell_w, cell_h
		end
	end

	return nil, nil
end

local function get_sixel_pixel_size(sixel_data)
	local ph, pv = sixel_data:match('"1;1;(%d+);(%d+)')
	if ph and pv then
		return tonumber(ph), tonumber(pv)
	end
	return nil, nil
end

M.show = function(image_path, auto_close)
	M.close()

	if auto_close == nil then
		auto_close = true
	end

	local opts = config.get()
	local converter = opts.converter

	if vim.fn.executable(converter) ~= 1 then
		vim.notify(converter .. " not found. Please install chafa.", vim.log.levels.ERROR)
		return
	end

	local cell_w, cell_h = query_terminal_cell_size()
	if not cell_w or not cell_h then
		cell_w, cell_h = opts.cell_size[1], opts.cell_size[2]
	end

	local cmd = string.format(
		"%s --format=sixels --scale=max --size=%dx%d --view-size=%dx%d %s",
		converter,
		opts.width,
		opts.height,
		opts.width,
		opts.height,
		vim.fn.shellescape(image_path)
	)

	local sixel_output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("chafa failed: " .. sixel_output, vim.log.levels.ERROR)
		return
	end

	local sixel_pixel_w, sixel_pixel_h = get_sixel_pixel_size(sixel_output)
	local width_cells, height_cells
	if sixel_pixel_w and sixel_pixel_h then
		width_cells = math.ceil(sixel_pixel_w / cell_w)
		height_cells = math.ceil(sixel_pixel_h / cell_h)
	else
		width_cells = opts.width
		height_cells = opts.height
	end

	local row = get_cursor_row()
	local col = vim.o.columns - width_cells + 1

	if col < 1 then
		col = 1
	end

	echoraw("\27[s")
	echoraw(string.format("\27[%d;%dH", row, col))
	echoraw(sixel_output)
	echoraw("\27[u")

	state.displayed = true
	state.last_row = row
	state.last_col = col
	state.last_width = width_cells
	state.last_height = height_cells

	if auto_close then
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave", "WinLeave", "WinScrolled" }, {
			once = true,
			callback = function()
				M.close()
			end,
		})
	end
end

M.close = function()
	if state.displayed then
		vim.cmd("mode")
	end
	state.displayed = false
	state.last_row = nil
	state.last_col = nil
	state.last_width = nil
	state.last_height = nil
end

M.is_open = function()
	return state.displayed
end

return M
