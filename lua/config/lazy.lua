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
    local my_custom_url = "https://github.com/konodoki/lazyvim/releases/download/tree-sitter/tree-sitter-linux-x64"

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
-- ==========================================================================
-- 1. 全自动环境依赖检查与修复 (针对旧 GLIBC 系统优化)
-- ==========================================================================
local function ensure_dependencies()
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  vim.fn.mkdir(mason_bin, "p")

  -- 待检查的组件列表: { 命令名, 下载地址, 描述 }
  -- 注意：这里使用的链接尽量指向兼容性好的二进制包
  local deps = {
    {
      "fzf",
      "https://github.com/junegunn/fzf/releases/download/v0.70.0/fzf-0.70.0-linux_amd64.tar.gz",
      "FZF (模糊搜索)"
    },
    {
      "rg",
      "https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz",
      "Ripgrep (实时文本搜索)"
    },
    {
      "fd",
      "https://github.com/sharkdp/fd/releases/download/v10.4.2/fd-v10.4.2-x86_64-unknown-linux-musl.tar.gz",
      "FD (快速文件查找)"
    },
    {
      "lazygit",
      "https://github.com/jesseduffield/lazygit/releases/download/v0.60.0/lazygit_0.60.0_linux_x86_64.tar.gz",
      "LazyGit (Git 终端界面)"
    }
  }
  local rocks_dir = vim.fn.stdpath("data") .. "/lazy-rocks/hererocks"
  local rocks_bin = rocks_dir .. "/bin/luarocks"

  -- 检查并安装 LuaRocks (Hererocks 方式)
  if vim.fn.executable(rocks_bin) == 0 then
    print("正在为 LazyVim 配置独立的 LuaRocks 环境...")
    -- 这里我们直接利用 pip 安装 hererocks 并初始化环境
    local install_rocks = string.format(
      "pip install --user hererocks && ~/.local/bin/hererocks %s --lua 5.1 --luarocks latest",
      rocks_dir
    )
    os.execute(install_rocks)
  end
  -- 检查并下载函数
  for _, dep in ipairs(deps) do
    local cmd, url, desc = dep[1], dep[2], dep[3]
    -- 检查 Mason 目录或系统路径是否存在该命令
    if vim.fn.executable(cmd) == 0 and vim.fn.executable(mason_bin .. "/" .. cmd) == 0 then
      print("正在自动安装缺失组件: " .. desc .. "...")
      
      local temp_file = "/tmp/lazy_dep.tar.gz"
      local download_cmd
      
      -- 处理不同的压缩包格式
      if url:match("%.tar%.gz$") then
        download_cmd = string.format("curl -L -o %s %s && tar -xzf %s -C /tmp", temp_file, url, temp_file)
        os.execute(download_cmd)
        -- 找出解压后的二进制文件并移动（处理部分包带层级目录的情况）
        os.execute(string.format("find /tmp -type f -name '%s' -exec mv {} %s/ \\;", cmd, mason_bin))
      else
        -- 直接下载二进制文件 (如 tree-sitter)
        download_cmd = string.format("curl -L -o %s/%s %s", mason_bin, cmd, url)
        os.execute(download_cmd)
      end
      
      os.execute("chmod +x " .. mason_bin .. "/" .. cmd)
    end
  end
  
  -- 强制将 Mason 目录加入当前 Neovim 会话的 PATH
  vim.env.PATH = rocks_dir .. "/bin:" .. mason_bin .. ":" .. vim.env.PATH
end

-- 执行体检
ensure_dependencies()

-- ==========================================================================
-- 2. 原有的 Lazy.nvim 引导与配置
-- ==========================================================================
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
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- 启用一些常用的 Extras
    { import = "lazyvim.plugins.extras.ui.edgy" },
    { import = "lazyvim.plugins.extras.editor.fzf" },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
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
