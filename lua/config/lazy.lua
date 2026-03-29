-- 1. 自定义 tree-sitter 兼容性补丁逻辑
local function fix_treesitter_glibc()
  -- 定义 Mason 的二进制文件存放路径
  local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"
  local ts_path = mason_bin_dir .. "/tree-sitter"

  -- 如果该路径下没有可执行文件，则说明需要我们手动“塞”一个进去
  if vim.fn.executable(ts_path) == 0 then
    -- 确保目录存在
    vim.fn.mkdir(mason_bin_dir, "p")

    -- 【关键修改点】：请把下面的 URL 换成你上传到 GitHub 的直链
    local my_custom_url = "https://github.com/你的用户名/你的仓库/releases/download/v0.1/tree-sitter-linux-x64"

    print("正在初始化环境：从私有源同步 tree-sitter 兼容组件...")

    -- 使用 curl 下载并赋予执行权限 (chmod +x)
    local cmd = string.format("curl -L -o %s %s && chmod +x %s", ts_path, my_custom_url, ts_path)

    -- 执行同步命令
    local exit_code = os.execute(cmd)

    if exit_code == 0 then
      print("同步成功！")
    else
      print("错误：无法从 GitHub 下载兼容组件，请检查网络连接。")
    end
  end
end

-- 在加载插件前运行补丁:
fix_treesitter_glibc()
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
