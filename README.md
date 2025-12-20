# ZFVimIM - Neovim 中文输入法插件

## 关于本项目

本项目基于 [ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)，由于原项目已停止维护，无法在新版本的 Neovim 中使用，本版本已适配 Neovim 0.11（测试版本：v0.11.5）。

### 主要改进

- **Neovim 0.11 适配**：完全适配 Neovim 0.11 的新 API 接口
- **浮动窗口绘制**：使用 Neovim 原生浮动窗口（floating window）显示候选词，提供更好的视觉体验
- **缩写编码支持**：支持 4 字符缩写编码，快速输入长词（如 3 字词使用首、二、尾字符拼音）
- **智能排序优化**：基于使用频率、单字优先、完全匹配优先等多维度排序算法
- **自动造词功能**：连续选择多个词后自动组合成新词并添加到词库
- **翻页功能**：支持候选词列表翻页浏览
- **本地词库支持**：通过配置文件或全局变量指定词库位置，支持 YAML 和 TXT 格式

## 快速开始

### 1. 安装插件

如果你使用 LazyVim，插件应该已经通过 `lua/plugins/zfvimim.lua` 配置好了。

### 2. 配置词库路径

#### 方法 1：使用插件目录下的词库（推荐，最简单）

编辑 `~/.config/nvim/lua/plugins/zfvimim.lua` 文件：

```lua
-- ZFVimIM 词库配置
-- 使用插件 dict/ 目录下的词库（只需指定文件名，不含扩展名）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

插件会自动在 `~/.local/share/nvim/lazy/ZFVimIM/dict/` 目录下查找 `sbzr.userdb.yaml`。

#### 方法 2：使用自定义词库路径（绝对路径）

编辑 `~/.config/nvim/lua/plugins/zfvimim.lua` 文件：

```lua
-- ZFVimIM 词库配置
-- 使用绝对路径指定词库位置
vim.g.zfvimim_dict_path = "/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.yaml"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

**支持的路径格式**：

- **绝对路径**：
  ```lua
  vim.g.zfvimim_dict_path = "/Users/username/path/to/dict.yaml"
  ```

- **使用 Neovim 配置目录**：
  ```lua
  vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"
  ```

- **使用数据目录**：
  ```lua
  vim.g.zfvimim_dict_path = vim.fn.stdpath("data") .. "/ZFVimIM/my_dict.yaml"
  ```

#### 方法 3：在 options.lua 中设置（全局配置）

在 `~/.config/nvim/lua/config/options.lua` 或 `init.lua` 中设置：

```lua
-- 词库路径（最高优先级，会覆盖插件配置）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

-- 或者使用插件目录下的词库
-- vim.g.zfvimim_default_dict_name = "sbzr.userdb"
```

**优先级说明**：

1. `vim.g.zfvimim_dict_path`（最高优先级）- 指定完整路径的词库文件
2. `vim.g.zfvimim_default_dict_name` - 指定插件 `dict/` 目录下的词库文件名
3. `default_pinyin.yaml`（默认）- 如果以上都未设置，使用内置默认词库

### 3. 词库文件格式

#### YAML 格式（推荐）

```yaml
a: [啊, 阿, 吖]
ai: [爱, 唉, 埃]
nihao: [你好, 你号]
ceshi: [测试, 测时]
```

保存为 `.yaml` 或 `.yml` 文件。

#### TXT 格式（向后兼容）

```
a 啊 阿 吖
ai 爱 唉 埃
nihao 你好 你号
ceshi 测试 测时
```

保存为 `.txt` 文件。

### 4. 使用输入法

1. **启动输入法**：在 Normal/Insert/Visual 模式下按 `;;`（两个分号）
2. **输入拼音**：在 Insert 模式下输入拼音，如 `nihao`
3. **选择候选**：
   - 按 `0-9` 选择对应的候选词（0 是第 10 个）
   - 按 `<Space>` 选择第一个候选
   - 按 `<Tab>`/`<S-Tab>` 上下移动候选
   - 按 `-`/`=` 或 `,`/`.` 翻页
4. **退出输入法**：按 `;;` 再次切换，或按 `<Esc>` 取消当前输入

## 配置说明

### 词库路径配置

配置文件位置：`~/.config/nvim/lua/plugins/zfvimim.lua`

```lua
-- 修改这一行来更改词库路径
local ZFVIMIM_DICT_PATH = "/path/to/your/dict.yaml"
```

**注意事项**：

- 如果指定的词库文件不存在，插件会显示警告并使用默认词库
- 路径会被自动标准化（`vim.fs.normalize`）
- 支持绝对路径和相对路径（`~` 会被展开）

### 默认词库位置

插件内置的默认词库位于：

- `~/.local/share/nvim/lazy/ZFVimIM/dict/default_pinyin.yaml`

如果未配置自定义词库，插件会尝试使用默认词库。

### 常用词库文件

插件目录下可能包含以下词库文件：

- `default_pinyin.yaml` - 默认拼音词库
- `sbzr.userdb.yaml` - 用户词库（如果存在）

你可以直接使用这些文件，或复制后修改。

## 高级配置

### 全局配置变量

在 Neovim 配置文件中设置（优先级高于配置文件）：

```lua
-- 词库路径（最高优先级）
vim.g.zfvimim_dict_path = "/path/to/dict.yaml"

-- 默认词库名称（如果未设置 zfvimim_dict_path）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"
```

### 补全设置

```lua
-- 匹配结果的最大数量（默认: 2000）
vim.g.ZFVimIM_matchLimit = 2000

-- 预测输入的最大数量（默认: 1000）
vim.g.ZFVimIM_predictLimit = 1000

-- 启用句子补全（默认: 1）
vim.g.ZFVimIM_sentence = 1

-- 跨数据库搜索（默认: 2）
-- 0: 禁用, 1: 仅完全匹配, 2: 包含预测, 3: 包含部分匹配
vim.g.ZFVimIM_crossable = 2
```

### 按键映射设置

```lua
-- 启用按键映射（默认: 1）
vim.g.ZFVimIM_keymap = 1

-- 自定义翻页键
vim.g.ZFVimIM_key_pageUp = ['-', ',']      -- 上翻页
vim.g.ZFVimIM_key_pageDown = ['=', '.']   -- 下翻页
```

### 显示设置

```lua
-- 自由滚动模式（默认: 0）
-- 1 时，候选超过 10 个也可滚动
vim.g.ZFVimIM_freeScroll = 0

-- 状态栏显示设置
vim.g.ZFVimIME_IMEStatus_tagL = ' <'  -- 左标签
vim.g.ZFVimIME_IMEStatus_tagR = '> '  -- 右标签
```

## 核心功能

### 1. 浮动窗口显示

使用 Neovim 原生浮动窗口显示候选词，美观且不遮挡编辑内容。

### 2. 智能排序

- **使用频率排序**：根据使用频率自动调整顺序
- **单字优先**：单字词优先于多字词
- **完全匹配优先**：完全匹配的编码优先显示

### 3. 自动造词

连续选择多个词后，系统会自动组合成新词并添加到词库。

**示例**：
- 输入 `ceshi` 选择 `测试`
- 输入 `shuru` 选择 `输入`
- 系统自动创建 `测试输入`，编码为 `ceshishuru`

### 4. 缩写编码

支持 4 字符缩写编码，快速输入长词：

- **3 字词**：首字符 + 第二字符 + 尾字符
  - 例如：`测试输入` → `cssu`（`c` + `s` + `u`）
- **4 字及以上**：首 + 二 + 三 + 尾字符
  - 例如：`中华人民共和国` → `zhrg`

### 5. 翻页功能

- 按 `-`/`=` 或 `,`/`.` 进行上下翻页
- 支持自由滚动模式（`g:ZFVimIM_freeScroll = 1`）

## 命令

### 插件管理

- `:ZFVimIMReload` - 重新加载整个插件
- `:ZFVimIMCacheClear` - 删除所有缓存文件
- `:ZFVimIMCacheUpdate` - 删除缓存并重新加载字典（推荐）

### 字典编辑

- `:IMAdd [word] [key]` - 添加词到字典
  - 例: `:IMAdd 测试 ceshi`
- `:IMRemove [word] [key]` - 从字典删除词
  - 例: `:IMRemove 测试 ceshi`
- `:IMReorder [word] [key]` - 更改词的顺序

## 按键映射

### 基本操作

- `;;` - 切换输入法开/关（Normal/Insert/Visual 模式）
- `;:` - 切换到下一个字典数据库
- `;,` - 打开添加词对话框
- `;.` - 打开删除词对话框

### 输入中的操作（Insert 模式，输入法启用时）

- `0-9` - 选择候选词（0 是第 10 个候选）
- `<Space>` - 确定第一个候选
- `<Enter>` - 关闭候选菜单
- `<Esc>` - 取消输入并关闭候选菜单
- `<Backspace>` - 删除 1 个字符
- `<Tab>` / `<S-Tab>` - 上下移动候选
- `-` / `=` 或 `,` / `.` - 上下翻页
- `[` / `]` - 左/右分割确定
- `<C-d>` - 删除当前选中的候选词

## 故障排除

### 词库未加载

1. **检查词库路径**：
   ```vim
   :lua print(vim.g.zfvimim_dict_path)
   ```

2. **检查文件是否存在**：
   ```vim
   :lua print(vim.fn.filereadable("/path/to/dict.yaml"))
   ```

3. **查看错误信息**：
   ```vim
   :messages
   ```

### 缓存问题

如果词库更改后未反映：

```vim
:ZFVimIMCacheUpdate
```

### 重新加载插件

```vim
:ZFVimIMReload
```

## 配置示例

### 完整配置示例

#### 示例 1：使用插件目录下的词库（推荐，最简单）

在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 使用插件 dict/ 目录下的词库（只需指定文件名，不含扩展名）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

**说明**：
- 插件会自动在 `~/.local/share/nvim/lazy/ZFVimIM/dict/` 目录下查找 `sbzr.userdb.yaml`
- 如果文件不存在，会自动回退到 `default_pinyin.yaml`

#### 示例 2：使用自定义词库路径（绝对路径）

在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 使用绝对路径指定词库位置
vim.g.zfvimim_dict_path = "/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.yaml"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

#### 示例 3：使用 Neovim 配置目录下的词库

在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 使用 Neovim 配置目录下的词库
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

**注意**：需要确保 `~/.config/nvim/zfvimim_db/sbzr.userdb.yaml` 文件存在。

#### 示例 4：在 options.lua 中设置全局变量（推荐用于多词库切换）

在 `~/.config/nvim/lua/config/options.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 词库路径（最高优先级，会覆盖插件配置）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

-- 或者使用插件目录下的词库
-- vim.g.zfvimim_default_dict_name = "sbzr.userdb"

-- 其他 ZFVimIM 配置
vim.g.ZFVimIM_matchLimit = 2000      -- 匹配结果的最大数量
vim.g.ZFVimIM_predictLimit = 1000    -- 预测输入的最大数量
vim.g.ZFVimIM_sentence = 1           -- 启用句子补全
vim.g.ZFVimIM_crossable = 2          -- 跨数据库搜索
vim.g.ZFVimIM_freeScroll = 0         -- 自由滚动模式
```

然后在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

#### 示例 5：完整配置（包含所有常用设置）

在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
-- ZFVimIM 完整配置示例

-- ===== 词库配置 =====
-- 方法1：使用插件目录下的词库（推荐）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

-- 方法2：使用自定义路径（取消注释以使用）
-- vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

-- ===== 补全设置 =====
vim.g.ZFVimIM_matchLimit = 2000      -- 匹配结果的最大数量（默认: 2000）
vim.g.ZFVimIM_predictLimit = 1000    -- 预测输入的最大数量（默认: 1000）
vim.g.ZFVimIM_sentence = 1           -- 启用句子补全（默认: 1）
vim.g.ZFVimIM_crossable = 2          -- 跨数据库搜索（默认: 2）
                                    -- 0: 禁用, 1: 仅完全匹配, 2: 包含预测, 3: 包含部分匹配

-- ===== 显示设置 =====
vim.g.ZFVimIM_freeScroll = 0         -- 自由滚动模式（默认: 0）
                                    -- 1 时，候选超过 10 个也可滚动

-- ===== 按键映射设置 =====
vim.g.ZFVimIM_keymap = 1             -- 启用按键映射（默认: 1）
vim.g.ZFVimIM_key_pageUp = ['-', ',']    -- 上翻页键
vim.g.ZFVimIM_key_pageDown = ['=', '.']  -- 下翻页键

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

## 词库管理

### 创建自定义词库

1. 创建 YAML 格式的词库文件：

```yaml
# my_dict.yaml
a: [啊, 阿, 吖]
ai: [爱, 唉, 埃]
nihao: [你好, 你号]
wo: [我, 窝, 握]
```

2. 在配置文件中指定路径：

```lua
local ZFVIMIM_DICT_PATH = "/path/to/my_dict.yaml"
```

3. 重启 Neovim 或运行 `:ZFVimIMReload`

### 添加新词

**方法 1：使用命令**

```vim
:IMAdd 测试 ceshi
```

**方法 2：直接编辑词库文件**

编辑 YAML 文件，添加新词条：

```yaml
ceshi: [测试, 测时, 侧视]
```

然后运行：

```vim
:ZFVimIMCacheUpdate
```

## 升级说明

- 若需更新核心实现，请在 `iamcheyan/ZFVimIM` fork 中同步修改后再运行 `:Lazy sync`
- 仅替换词库时，只需更新词库文件，无需改动插件代码
- 词库更改后记得运行 `:ZFVimIMCacheUpdate` 更新缓存

## 相关链接

- 原项目：[ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)
- 适配版本：[iamcheyan/ZFVimIM](https://github.com/iamcheyan/ZFVimIM)
