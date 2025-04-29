-- ~/.config/nvim/init.lua

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"


-- Set leader key (optional, common practice)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  -- Essential for syntax highlighting and parsing
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "markdown", "markdown_inline" }, -- Ensure markdown parsers are installed
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Fuzzy finder for notes, files, etc.
  {
    "nvim-telescope/telescope.nvim",
    version = "*", -- Or latest tag
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Basic telescope configuration (can be expanded)
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "obsidian") -- Use pcall for safety, in case obsidian.nvim isn't loaded yet for some reason
      -- Basic keymaps for finding files
      vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
      vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })
    end,
  },

  -- Obsidian integration
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- Use latest release
    lazy = true,
    -- Trigger obsidian.nvim loading when entering Markdown files in your vault
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",        -- Optional, for completion
      "nvim-telescope/telescope.nvim", -- Required if using telescope for finding notes/tags
    },
    opts = {
      -- Define the path to your Obsidian vault directory
      dir = "/notes",

      -- Optional: Configure how links are completed, tags searched, etc.
      completion = {
        nvim_cmp = true, -- Integrate with nvim-cmp if installed
      },
    picker = {
    -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
    name = "telescope.nvim",
    -- Optional, configure key mappings for the picker. These are the defaults.
    -- Not all pickers support all mappings.
    note_mappings = {
      -- Create a new note from your query.
      new = "<C-x>",
      -- Insert a link to the selected note.
      insert_link = "<C-l>",
    },
    tag_mappings = {
      -- Add tag(s) to current note.
      tag_note = "<C-x>",
      -- Insert a tag at the current location.
      insert_tag = "<C-l>",
    },
  },

      -- Optional: Define keymappings for obsidian actions
      mappings = {
        -- Follow wiki links (similar to gf, but obsidian-aware)
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
      },

      -- How to handle non-existent notes when following links
      follow_url_func = function(url)
        -- Example: open http(s) links in browser
        if url:match("^https?://") then
          vim.fn.system({"open", url}) -- 'open' on macOS, use 'xdg-open' on Linux, 'start' on Windows
        else
          -- Default behavior for other URLs/paths (can be customized)
          require("obsidian.util").default_follow_url_func(url)
        end
      end,

      -- Other options can be configured here (daily notes, templates, etc.)
      -- See :help obsidian.nvim for full details
    },
    config = function(_, opts)
      -- Load telescope extension if telescope is installed
      require("obsidian").setup(opts)
    end,
  },

  -- Optional: nvim-cmp for autocompletion (recommended with obsidian.nvim)
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
      -- Basic nvim-cmp setup
      local cmp = require("cmp")
      cmp.setup({
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
          -- Add obsidian source if obsidian.nvim is configured for cmp
          { name = "obsidian" }
        }),
        mapping = cmp.mapping.preset.insert({
        -- *** Use Ctrl+p/Ctrl+n for navigation ***
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),

        -- Confirm selection with Enter
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Confirm selection with Enter

        -- Scroll documentation
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        -- Abort completion
        ['<C-e>'] = cmp.mapping.abort(),

        -- Optional: Use Tab for navigation/snippet expansion/completion
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete() -- Start completion if there are words before cursor
          else
            fallback() -- Fallback to default Tab behavior
          end
        end, { "i", "s" }), -- Apply in insert and select mode

        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback() -- Fallback to default Shift-Tab behavior
          end
        end, { "i", "s" }),
        })
      })
    end,
  },

})

vim.keymap.set('n', '<leader>ob', ':ObsidianBacklinks<CR>', { noremap = true, silent = true, desc = 'Show backlinks' }) 
vim.keymap.set('n', '<leader>on', ':ObsidianSearch<CR>', { noremap = true, silent = true, desc = 'Obsidian quick switch' })
vim.keymap.set('n', '<leader>oe', ':ObsidianExtractNote<CR>', { noremap = true, silent = true, desc = 'Obsidian extract and link' })
vim.keymap.set('n', '<leader>ol', ':ObsidianLinks<CR>', { noremap = true, silent = true, desc = 'Obsidian show links' })

-- Basic settings (optional but recommended)
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.wrap = true           -- Enable text wrapping
vim.opt.linebreak = true      -- Wrap lines at convenient places
vim.opt.conceallevel = 2      -- Hide markdown syntax characters like * or _ for emphasis

print("Neovim config loaded!")

