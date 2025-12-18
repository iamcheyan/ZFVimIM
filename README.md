# 升级 ZFVimIM 说明

## 关于本项目

本项目基于 [ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)，由于原项目已停止维护，无法在新版本的 Neovim 中使用，本版本已适配 Neovim 0.11（测试版本：v0.11.5）。

做了以下最小化改动，便于与本地词库配合：

- 通过 `vim.g.zfvimim_dict_path` 指定词库位置（默认读取 `~/.dotfiles/config/nvim/zfvimim_db/sbzr.userdb.txt`）。
- 词库作为本地文件使用 `local` 模式注册，不依赖 GitHub 同步。
- 其它 Vim 脚本保持与 upstream 一致，便于后续合并更新。

## Neovim 0.11 适配说明

- **接口更新**：适配 Neovim 0.11 的新 API 接口，确保兼容性
- **性能优化**：利用 Neovim 0.11 的性能改进，提升输入法响应速度
- **功能增强**：支持 Neovim 0.11 的新特性，改善用户体验

## 预览效果

### 基础输入法功能

![预览](preview.gif)

### 跨数据库查询功能

![跨数据库预览](preview_crossdb.gif)

## 快速使用

### 默认词库

为防止用户第一次使用时没有词库，本仓库已包含一个简单的默认拼音词库：
- 位置：`~/.local/share/nvim/lazy/ZFVimIM/dict/default_pinyin.txt`
- 包含常用汉字和词汇，可直接使用

**自动加载机制**：
- 如果未设置 `vim.g.zfvimim_dict_path`，插件会自动加载默认词库 `dict/default_pinyin.txt`
- 如果设置了 `vim.g.zfvimim_dict_path`，则使用指定的词库文件

### 配置步骤

1. **无需配置（推荐首次使用）**：
   插件会自动使用默认词库，无需任何配置即可开始使用。

2. **使用自定义词库**：
   在 `lua/config/options.lua` 设置：
   ```lua
   vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"
   ```

3. **显式指定默认词库**（可选）：
   如果需要显式指定默认词库路径：
   ```lua
   vim.g.zfvimim_dict_path = vim.fn.stdpath("data") .. "/lazy/ZFVimIM/dict/default_pinyin.txt"
   ```

3. **词库格式**：
   词库采用 `拼音 候选1 候选2 ...` 的 UTF-8 文本格式，多条同键可重复出现。
   示例：
   ```
   a 啊 阿 吖
   ai 爱 唉 埃
   ```

4. **使用方法**：
   Neovim 启动后 `;;` 进入输入状态，`0-9`/空格选词，`Esc` 退出。

## 升级策略

- 若需更新核心实现，请在 `iamcheyan/ZFVimIM` fork 中同步修改后再运行 `:Lazy sync`。
- 仅替换词库时，只需更新 `zfvimim_db` 目录内容，无需改动本仓库。
