-- vim-tmux-send-to-ai-cli: Send Vim text directly to AI CLIs in tmux
-- Repository: https://github.com/i9wa4/vim-tmux-send-to-ai-cli

return {
  "i9wa4/vim-tmux-send-to-ai-cli",
  config = function()
    -- Add custom process names for auto-detection (optional)
    -- vim.g.tmux_ai_cli_additional_processes = { "mycli", "aichat" }

    -- Key mappings
    local opts = { noremap = true, silent = true }

    -- Single pane commands
    vim.keymap.set("n", "<leader>al", "<Plug>(tmux-send-to-ai-cli-current-line)", opts)
    vim.keymap.set("n", "<leader>ap", "<Plug>(tmux-send-to-ai-cli-paragraph)", opts)
    vim.keymap.set("v", "<leader>as", "<Plug>(tmux-send-to-ai-cli-visual)", opts)
    vim.keymap.set("n", "<leader>ab", "<Plug>(tmux-send-to-ai-cli-buffer)", opts)

    -- All panes commands
    vim.keymap.set("n", "<leader>aL", "<Plug>(tmux-send-to-ai-cli-current-line-all)", opts)
    vim.keymap.set("n", "<leader>aP", "<Plug>(tmux-send-to-ai-cli-paragraph-all)", opts)
    vim.keymap.set("v", "<leader>aS", "<Plug>(tmux-send-to-ai-cli-visual-all)", opts)
    vim.keymap.set("n", "<leader>aB", "<Plug>(tmux-send-to-ai-cli-buffer-all)", opts)
  end,
}
