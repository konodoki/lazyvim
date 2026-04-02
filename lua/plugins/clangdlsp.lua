return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- 这里写 clangd，LazyVim 会把你写的这些和默认的进行合并
        clangd = {
          keys = {
            { "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
          root_markers = {
            "compile_commands.json",
            "compile_flags.txt",
            "configure.ac", -- AutoTools
            "Makefile",
            "configure.ac",
            "configure.in",
            "config.h.in",
            "meson.build",
            "meson_options.txt",
            "build.ninja",
            ".git",
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=true",
            "--fallback-style=Google",
            "--query-driver=/usr/bin/gcc,/usr/bin/g++,/usr/bin/gcc-*,/usr/bin/g++-*,/usr/bin/cc,/usr/bin/c++",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
      },
    },
  },
}
