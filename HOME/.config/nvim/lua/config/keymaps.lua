local h = require("util.helper")

-- 折り返し時に表示行単位での移動できるようにする
h.nmap("j", "gj")
h.nmap("k", "gk")

-- ESC連打でハイライト解除
h.nmap("<ESC><ESC>", "<CMD>nohlsearch<CR>", { desc = "Unhighlight" })

