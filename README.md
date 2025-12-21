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
- **本地词库支持**：通过配置文件或全局变量指定词库位置，支持 TXT 格式

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

插件会自动在 `~/.local/share/nvim/lazy/ZFVimIM/dict/` 目录下查找 `sbzr.userdb.txt`。

#### 方法 2：使用自定义词库路径（绝对路径）

编辑 `~/.config/nvim/lua/plugins/zfvimim.lua` 文件：

```lua
-- ZFVimIM 词库配置
-- 使用绝对路径指定词库位置
vim.g.zfvimim_dict_path = "/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt"

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
  vim.g.zfvimim_dict_path = "/Users/username/path/to/dict.txt"
  ```

- **使用 Neovim 配置目录**：
  ```lua
  vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"
  ```

- **使用数据目录**：
  ```lua
  vim.g.zfvimim_dict_path = vim.fn.stdpath("data") .. "/ZFVimIM/my_dict.txt"
  ```

#### 方法 3：在 options.lua 中设置（全局配置）

在 `~/.config/nvim/lua/config/options.lua` 或 `init.lua` 中设置：

```lua
-- 词库路径（最高优先级，会覆盖插件配置）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"

-- 或者使用插件目录下的词库
-- vim.g.zfvimim_default_dict_name = "sbzr.userdb"
```

**优先级说明**：

1. `vim.g.zfvimim_dict_path`（最高优先级）- 指定完整路径的词库文件
2. `vim.g.zfvimim_default_dict_name` - 指定插件 `dict/` 目录下的词库文件名
3. `default_pinyin.txt`（默认）- 如果以上都未设置，使用内置默认词库

### 3. 词库文件格式

#### TXT 格式（推荐）

```txt
a: [啊, 阿, 吖]
ai: [爱, 唉, 埃]
nihao: [你好, 你号]
ceshi: [测试, 测时]
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

**演示操作：**

![](assast/preview.gif)

## 配置说明

### 词库路径配置

配置文件位置：`~/.config/nvim/lua/plugins/zfvimim.lua`

```lua
-- 修改这一行来更改词库路径
local ZFVIMIM_DICT_PATH = "/path/to/your/dict.txt"
```

**注意事项**：

- 如果指定的词库文件不存在，插件会显示警告并使用默认词库
- 路径会被自动标准化（`vim.fs.normalize`）
- 支持绝对路径和相对路径（`~` 会被展开）

### 默认词库位置

插件内置的默认词库位于：

- `~/.local/share/nvim/lazy/ZFVimIM/dict/default_pinyin.txt`

如果未配置自定义词库，插件会尝试使用默认词库。

### 常用词库文件

插件目录下可能包含以下词库文件：

- `default_pinyin.txt` - 默认拼音词库
- `sbzr.userdb.txt` - 用户词库（如果存在）

你可以直接使用这些文件，或复制后修改。

## 高级配置

### 全局配置变量

在 Neovim 配置文件中设置（优先级高于配置文件）：

```lua
-- 词库路径（最高优先级）
vim.g.zfvimim_dict_path = "/path/to/dict.txt"

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

**跨数据库搜索演示：**

![](assast/preview_crossdb.gif)
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

### 调试和状态查询

- `:ZFVimIMInfo` - **显示词库详细信息**（重要命令）

  这个命令可以显示当前 ZFVimIM 插件的完整状态信息，帮助你快速诊断和了解词库加载情况。

  **显示的信息包括：**
  - 当前使用的词库索引和总数
  - 每个词库的详细信息：
    - 词库名称
    - 文件路径
    - 最后修改时间
    - 文件大小（自动转换为 KB/MB）
    - 条目数量（词库中的词条数）
    - 优先级
    - 数据库ID
  - 配置信息：
    - `zfvimim_dict_path` - 自定义词库路径
    - `zfvimim_default_dict_name` - 默认词库名称
    - `ZFVimIM_matchLimit` - 匹配结果限制
    - `ZFVimIM_predictLimit` - 预测输入限制
    - `ZFVimIM_crossDbLimit` - 跨数据库搜索限制

  **使用场景：**
  - 检查词库是否正确加载
  - 查看词库文件路径和状态
  - 诊断词库加载问题
  - 了解当前配置

  **示例输出：**
  ```
  ==========================================
  ZFVimIM 词库信息
  ==========================================
  当前词库索引: 1 / 1

  👉 词库 #1: sbzr.userdb
      路径: /Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt
      最后修改: 2024-12-20 23:06:00
      文件大小: 12.5 MB
      条目数量: 620095
      优先级: 100

  配置信息:
    zfvimim_default_dict_name: sbzr.userdb
    ZFVimIM_matchLimit: 2000
    ZFVimIM_predictLimit: 1000
    ZFVimIM_crossDbLimit: 2
  ==========================================
  ```

  ![](assast/2025-12-20-23-13-34.png)

### 字典编辑

#### `:IMAdd` - 添加词到字典

**功能**：直接将词追加到词库文件末尾，无论输入什么内容都会原样添加。

**格式**：`:IMAdd <编码> <词>`

**示例**：
```vim
" 添加单个词
:IMAdd ceshi 测试

" 添加包含空格的词
:IMAdd cccc 超 超 超 超

" 添加任意内容（会原样追加到文件末尾）
:IMAdd abc 任意内容
```

**说明**：
- 直接将内容追加到词库文件末尾，不做任何验证或处理
- 格式：`编码 词`（与词库文件格式一致）
- 词可以包含多个字符，用空格分隔
- 退出插入模式时会自动清理词库（去除重复、规范格式等）

#### `:IMRemove` - 从字典删除词（支持批量删除）

**功能**：从词库文件中删除指定的词，支持批量删除多个词。

**格式**：`:IMRemove <词1> [词2] [词3] ...`

**示例**：
```vim
" 删除单个词
:IMRemove 测试

" 批量删除多个词
:IMRemove 词1 词2 词3

" 批量删除多个词（实际示例）
:IMRemove 欧洲 鮟鱇 欧营村 欧虞颜柳
```

**说明**：
- 支持批量删除：一次命令可以删除多个词
- 会在整个词库文件中搜索并删除指定的词
- 显示删除结果：每个词的删除数量（例如：`词1(1) 词2(0) 词3(2)`）
- 如果某个词不存在，会显示 `(0)`，但不会报错
- 删除后会自动清理空行（如果某行只剩下编码没有词，会删除整行）

**批量删除示例输出**：
```
[ZFVimIM] Removed words: 欧洲(1):鮟鱇(1):欧营村(0):欧虞颜柳(1)
```
表示：
- `欧洲` 删除了 1 次
- `鮟鱇` 删除了 1 次
- `欧营村` 未找到（0 次）
- `欧虞颜柳` 删除了 1 次

#### `:IMReorder` - 更改词的顺序

**格式**：`:IMReorder <词> [编码]`

**示例**：
```vim
:IMReorder 测试 ceshi
```

**说明**：调整指定词在对应编码下的显示顺序。

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

**首先运行 `:ZFVimIMInfo` 命令查看详细状态信息！**

这个命令会自动检测词库加载状态，并显示：
- 词库文件路径和是否存在
- 文件大小和最后修改时间
- 配置信息
- 故障排除建议

如果词库未加载，该命令会提供详细的诊断信息。

**其他检查方法：**

1. **检查词库路径**：
   ```vim
   :lua print(vim.g.zfvimim_dict_path)
   :lua print(vim.g.zfvimim_default_dict_name)
   ```

2. **检查文件是否存在**：
   ```vim
   :lua print(vim.fn.filereadable("/path/to/dict.txt"))
   ```

3. **查看错误信息**：
   ```vim
   :messages
   ```

### 清理脚本错误：UTF-8 编码错误

**错误信息**：
```
ZFVimIM: Cleanup failed: Error loading dictionary: 'utf-8' codec can't decode byte 0x8d in position 98: invalid start byte
```

**原因**：
- 清理脚本试图处理二进制文件（如 `.db` 文件）而不是文本文件（`.txt`）
- 词库文件损坏或编码不正确

**解决方法**：

1. **确认词库文件格式**：
   - 清理脚本只处理 `.txt` 文件
   - 不要尝试清理 `.db` 二进制文件
   - 确保配置指向的是 `.txt` 文件

2. **检查文件编码**：
   ```bash
   # 检查文件类型
   file ~/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt
   
   # 检查文件编码
   enca ~/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt
   ```

3. **如果文件损坏，从备份恢复**：
   ```bash
   # 检查是否有备份文件
   ls ~/.local/share/nvim/lazy/ZFVimIM/dict/*.backup*
   
   # 如果有备份，恢复它
   cp ~/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt.backup \
      ~/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt
   ```

4. **禁用自动清理（临时方案）**：
   如果问题持续，可以暂时禁用退出时的自动清理：
   ```vim
   " 注释掉或删除自动清理的 autocmd（在插件代码中）
   " 但这不是推荐的长期解决方案
   ```

5. **手动重新生成词库**：
   如果文件确实损坏，可以：
   - 从其他来源重新获取词库文件
   - 使用备份文件
   - 从头开始创建词库

**注意**：`.db` 文件是二进制数据库文件，不应该用文本工具编辑或清理。只清理 `.txt` 文件。

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
- 插件会自动在 `~/.local/share/nvim/lazy/ZFVimIM/dict/` 目录下查找 `sbzr.userdb.txt`
- 如果文件不存在，会自动回退到 `default_pinyin.txt`

#### 示例 2：使用自定义词库路径（绝对路径）

在 `~/.config/nvim/lua/plugins/zfvimim.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 使用绝对路径指定词库位置
vim.g.zfvimim_dict_path = "/Users/tetsuya/.local/share/nvim/lazy/ZFVimIM/dict/sbzr.userdb.txt"

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
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"

return {
  {
    "iamcheyan/ZFVimIM",
    lazy = false,
  },
}
```

**注意**：需要确保 `~/.config/nvim/zfvimim_db/sbzr.userdb.txt` 文件存在。

#### 示例 4：在 options.lua 中设置全局变量（推荐用于多词库切换）

在 `~/.config/nvim/lua/config/options.lua` 中：

```lua
-- ZFVimIM 词库配置
-- 词库路径（最高优先级，会覆盖插件配置）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"

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
-- vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.txt"

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

1. 创建 TXT 格式的词库文件：

```txt
# my_dict.txt
a: [啊, 阿, 吖]
ai: [爱, 唉, 埃]
nihao: [你好, 你号]
wo: [我, 窝, 握]
```

2. 在配置文件中指定路径：

```lua
local ZFVIMIM_DICT_PATH = "/path/to/my_dict.txt"
```

3. 重启 Neovim 或运行 `:ZFVimIMReload`

### 添加新词

**方法 1：使用命令（推荐）**

使用 `:IMAdd` 命令直接添加：

```vim
" 添加单个词
:IMAdd ceshi 测试

" 添加包含多个字符的词
:IMAdd cccc 超 超 超 超

" 添加任意内容（会原样追加）
:IMAdd abc 任意内容
```

**说明**：
- `IMAdd` 会将内容直接追加到词库文件末尾
- 不需要手动编辑文件
- 退出插入模式时会自动清理词库（去除重复、规范格式等）

**方法 2：直接编辑词库文件**

编辑 TXT 文件，添加新词条：

```txt
ceshi 测试 测时 侧视
```

**注意**：TXT 格式是 `编码 词1 词2 ...`，不是 `编码: [词1, 词2]` 格式。

然后运行：

```vim
:ZFVimIMCacheUpdate
```

### 删除词

**使用命令（推荐）**

使用 `:IMRemove` 命令删除词：

```vim
" 删除单个词
:IMRemove 测试

" 批量删除多个词
:IMRemove 词1 词2 词3 词4
```

**说明**：
- 支持批量删除：一次命令可以删除多个词
- 会在整个词库文件中搜索并删除
- 显示删除结果和数量
- 删除后会自动清理空行

**批量删除示例输出**：
```
[ZFVimIM] Removed words: 欧洲(1):鮟鱇(1):欧营村(0):欧虞颜柳(1)
```
表示：
- `欧洲` 删除了 1 次
- `鮟鱇` 删除了 1 次
- `欧营村` 未找到（0 次）
- `欧虞颜柳` 删除了 1 次

**方法 2：直接编辑词库文件**

手动编辑词库文件删除词条，然后运行：

```vim
:ZFVimIMCacheUpdate
```

### 自动清理词库

**功能**：Neovim 退出时会自动执行词库清理脚本，确保词库格式正确。

**清理内容**：
- 去除重复词语
- 规范格式（去除首尾空格、空词等）
- 删除无效条目（空编码、空词列表等）
- 合并相同编码的条目
- 按词数量排序（词多的在前面）

**说明**：
- 即使使用 `IMAdd` 添加了不规范的内容，退出时也会被自动清理
- 清理过程在后台异步执行，不会阻塞退出
- 清理脚本：`misc/dbCleanup.py`

## 升级说明

- 若需更新核心实现，请在 `iamcheyan/ZFVimIM` fork 中同步修改后再运行 `:Lazy sync`
- 仅替换词库时，只需更新词库文件，无需改动插件代码
- 词库更改后记得运行 `:ZFVimIMCacheUpdate` 更新缓存

## 相关链接

- 原项目：[ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)
- 适配版本：[iamcheyan/ZFVimIM](https://github.com/iamcheyan/ZFVimIM)