local plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
	vim.opt.runtimepath:append(plenary_path)
end

vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append("./tests")

vim.cmd([[runtime plugin/plenary.vim]])
