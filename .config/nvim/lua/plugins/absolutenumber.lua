-- 常に絶対行数を表示する
-- なぜか relativenumber = false が効かないので...

local augroup = vim.api.nvim_create_augroup("absolutenumber", {})

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
	pattern = "*",
	group = augroup,
	callback = function()
		if vim.o.nu then
			vim.opt.relativenumber = false
			vim.cmd("redraw")
		end
	end,
})
