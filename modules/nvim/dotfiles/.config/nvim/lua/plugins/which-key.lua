return {
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = {
        marks = false,
        registers = false,
        spelling = { enabled = true, suggestions = 20 },
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = false,
          g = false,
        },
      },
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },
      win = {
        border = "single",
      },
      show_help = true,
    },
    config = function(_, opts)
      local wk = require("which-key")
      local prefs = require("user.preferences")
      wk.setup(opts)

      wk.add(prefs.find_mappings)

      wk.add({
        { "<leader>;", "<cmd>Alpha<CR>", desc = "Dashboard" },
        { "<leader>w", "<cmd>w!<CR>", desc = "Save" },
        { "<leader>q", "<cmd>confirm q<CR>", desc = "Quit" },
        { "<leader>/", "<Plug>(comment_toggle_linewise_current)", desc = "Comment toggle current line" },
        { "<leader>c", "<cmd>BufferKill<CR>", desc = "Close Buffer" },
        { "<leader>h", "<cmd>nohlsearch<CR>", desc = "No Highlight" },
        { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer" },

        { "<leader>b", group = "Buffers" },
        { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Jump" },
        { "<leader>bf", "<cmd>Telescope buffers previewer=false<cr>", desc = "Find" },
        { "<leader>bb", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous" },
        { "<leader>bn", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
        { "<leader>bW", "<cmd>noautocmd w<cr>", desc = "Save without formatting" },
        { "<leader>be", "<cmd>BufferLinePickClose<cr>", desc = "Pick which buffer to close" },
        { "<leader>bh", "<cmd>BufferLineCloseLeft<cr>", desc = "Close all to the left" },
        { "<leader>bl", "<cmd>BufferLineCloseRight<cr>", desc = "Close all to the right" },
        { "<leader>bD", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
        { "<leader>bL", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by language" },

        { "<leader>d", group = "Debug" },
        { "<leader>dt", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
        { "<leader>db", function() require("dap").step_back() end, desc = "Step Back" },
        { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
        { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run To Cursor" },
        { "<leader>dd", function() require("dap").disconnect() end, desc = "Disconnect" },
        { "<leader>dg", function() require("dap").session() end, desc = "Get Session" },
        { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
        { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
        { "<leader>du", function() require("dap").step_out() end, desc = "Step Out" },
        { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
        { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle Repl" },
        { "<leader>ds", function() require("dap").continue() end, desc = "Start" },
        { "<leader>dq", function() require("dap").close() end, desc = "Quit" },
        { "<leader>dU", function() require("dapui").toggle({ reset = true }) end, desc = "Toggle UI" },

        { "<leader>p", group = "Plugins" },
        { "<leader>pi", "<cmd>Lazy install<cr>", desc = "Install" },
        { "<leader>ps", "<cmd>Lazy sync<cr>", desc = "Sync" },
        { "<leader>pS", "<cmd>Lazy clear<cr>", desc = "Status" },
        { "<leader>pc", "<cmd>Lazy clean<cr>", desc = "Clean" },
        { "<leader>pu", "<cmd>Lazy update<cr>", desc = "Update" },
        { "<leader>pp", "<cmd>Lazy profile<cr>", desc = "Profile" },
        { "<leader>pl", "<cmd>Lazy log<cr>", desc = "Log" },
        { "<leader>pd", "<cmd>Lazy debug<cr>", desc = "Debug" },

        { "<leader>g", group = "Git" },
        {
          "<leader>gg",
          function()
            local Terminal = require("toggleterm.terminal").Terminal
            local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
            lazygit:toggle()
          end,
          desc = "Lazygit",
        },
        { "<leader>gj", function() require("gitsigns").nav_hunk("next", { navigation_message = false }) end, desc = "Next Hunk" },
        { "<leader>gk", function() require("gitsigns").nav_hunk("prev", { navigation_message = false }) end, desc = "Prev Hunk" },
        { "<leader>gl", function() require("gitsigns").blame_line() end, desc = "Blame" },
        { "<leader>gL", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame Line (full)" },
        { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk" },
        { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },
        { "<leader>gR", function() require("gitsigns").reset_buffer() end, desc = "Reset Buffer" },
        { "<leader>gs", function() require("gitsigns").stage_hunk() end, desc = "Stage Hunk" },
        { "<leader>gu", function() require("gitsigns").undo_stage_hunk() end, desc = "Undo Stage Hunk" },
        { "<leader>go", "<cmd>Telescope git_status<cr>", desc = "Open changed file" },
        { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
        { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit" },
        { "<leader>gC", "<cmd>Telescope git_bcommits<cr>", desc = "Checkout commit (current file)" },
        { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>", desc = "Git Diff" },

        { "<leader>l", group = "LSP" },
        { "<leader>la", function() vim.lsp.buf.code_action() end, desc = "Code Action" },
        { "<leader>ld", "<cmd>Telescope diagnostics bufnr=0 theme=get_ivy<cr>", desc = "Buffer Diagnostics" },
        { "<leader>lw", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
        { "<leader>lf", function() vim.lsp.buf.format({ async = false, timeout_ms = 1000 }) end, desc = "Format" },
        { "<leader>li", "<cmd>LspInfo<cr>", desc = "Info" },
        { "<leader>lI", "<cmd>Mason<cr>", desc = "Mason Info" },
        { "<leader>lj", function() vim.diagnostic.goto_next() end, desc = "Next Diagnostic" },
        { "<leader>lk", function() vim.diagnostic.goto_prev() end, desc = "Prev Diagnostic" },
        { "<leader>ll", function() vim.lsp.codelens.run() end, desc = "CodeLens Action" },
        { "<leader>lq", function() vim.diagnostic.setloclist() end, desc = "Quickfix" },
        { "<leader>lr", function() vim.lsp.buf.rename() end, desc = "Rename" },
        { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
        { "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
        { "<leader>le", "<cmd>Telescope quickfix<cr>", desc = "Telescope Quickfix" },

        { "<leader>s", group = "Search" },
        { "<leader>sb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
        { "<leader>sc", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
        { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Find File" },
        { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
        { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Find highlight groups" },
        { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
        { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
        { "<leader>sR", "<cmd>Telescope registers<cr>", desc = "Registers" },
        { "<leader>st", "<cmd>Telescope live_grep<cr>", desc = "Text" },
        { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
        { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
        { "<leader>sl", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
        {
          "<leader>sp",
          function()
            require("telescope.builtin").colorscheme({ enable_preview = true })
          end,
          desc = "Colorscheme with Preview",
        },

        { "<leader>T", group = "Treesitter" },
        { "<leader>Ti", ":TSConfigInfo<cr>", desc = "Info" },

        -- Visual mode
        { "<leader>/", "<Plug>(comment_toggle_linewise_visual)", desc = "Comment toggle linewise (visual)", mode = "v" },
        { "<leader>l", group = "LSP", mode = "v" },
        { "<leader>la", function() vim.lsp.buf.code_action() end, desc = "Code Action", mode = "v" },
        { "<leader>g", group = "Git", mode = "v" },
        { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset Hunk", mode = "v" },
        { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage Hunk", mode = "v" },
      })
    end,
  },
}
