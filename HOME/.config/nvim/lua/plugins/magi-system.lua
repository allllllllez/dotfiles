-- ==============================================================================
-- MAGI System Plugins
-- ==============================================================================

return {
  -- tmux連携用のプラグイン（vim-slimeを使用）
  {
    "jpalardy/vim-slime",
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_default_config = {
        socket_name = "default",
        target_pane = "{right-of}",
      }
      vim.g.slime_dont_ask_default = 1
      vim.g.slime_paste_file = vim.fn.tempname()

      -- MAGI System用のカスタムコマンド
      vim.api.nvim_create_user_command("SendToAllAI", function(opts)
        local content = opts.args
        if content == "" then
          -- 現在行を送信
          content = vim.api.nvim_get_current_line()
        end

        -- 複数のペインに送信（ペイン1, 2, 3, 4に送信）
        for pane = 1, 4 do
          vim.fn.system(
            string.format('tmux send-keys -t %d "%s" C-m', pane, content:gsub('"', '\\"'))
          )
        end
      end, { nargs = "?" })

      -- キーマッピング
      vim.keymap.set("n", "<leader>ts", ":SlimeSend<CR>", { desc = "Send to tmux pane" })
      vim.keymap.set("v", "<leader>ts", ":SlimeSend<CR>", { desc = "Send selection to tmux pane" })
      vim.keymap.set("n", "<leader>ta", ":SendToAllAI ", { desc = "Send to all AI panes" })
    end,
  },
}
