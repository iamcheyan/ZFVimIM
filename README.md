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
- **本地词库支持**：通过 `vim.g.zfvimim_dict_path` 指定词库位置，支持 YAML 和 TXT 格式

## 预览效果

### 基础输入法功能

![预览](preview.gif)

### 跨数据库查询功能

![跨数据库预览](preview_crossdb.gif)

## 快速使用

### 默认词库

插件内置默认词库为 `default_pinyin.yaml`，位于插件目录的 `dict/` 文件夹下：

- 默认路径：`~/.local/share/nvim/lazy/ZFVimIM/dict/default_pinyin.yaml`
- 包含常用汉字和词汇，可直接使用

**词库加载优先级**：

1. 如果设置了 `vim.g.zfvimim_dict_path`，优先使用指定的词库文件（绝对路径或相对路径）
2. 如果设置了 `vim.g.zfvimim_default_dict_name`，使用插件 `dict/` 目录下对应名称的词库
3. 否则，使用默认词库 `default_pinyin.yaml`

### 词库切换配置

#### 方法 1：使用自定义词库路径（推荐）

在配置文件中（如 `lua/config/options.lua` 或 `init.lua`）设置：

```lua
-- 使用自定义词库（绝对路径）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

-- 或者使用相对路径（相对于 Neovim 配置目录）
vim.g.zfvimim_dict_path = "~/my_dicts/custom.yaml"
```

**说明**：

- 支持 `.yaml`、`.yml`格式
- 如果指定的文件不存在，会自动回退到默认词库
- 可以使用绝对路径或相对路径（`~` 会被展开）

#### 方法 2：使用插件目录下的其他词库

如果你想使用插件 `dict/` 目录下的其他词库文件（如 `sbzr.userdb.yaml`），可以设置：

```lua
-- 使用插件 dict/ 目录下的其他词库（只需指定文件名，不含扩展名）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"
```

**说明**：

- 只需指定文件名（不含 `.yaml` 扩展名）
- 插件会自动在 `dict/` 目录下查找对应文件（`.yaml` 格式）
- 如果文件不存在，会回退到 `default_pinyin.yaml`

#### 方法 3：恢复默认词库

如果想恢复使用默认的 `default_pinyin.yaml`，只需删除或注释掉相关配置：

```lua
-- 删除或注释掉这两行即可恢复默认词库
-- vim.g.zfvimim_dict_path = "..."
-- vim.g.zfvimim_default_dict_name = "..."
```

### 配置示例

```lua
-- 示例 1：使用自定义词库（推荐方式）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"

-- 示例 2：使用插件目录下的其他词库
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

-- 示例 3：使用默认词库（无需配置，或删除上述配置）
-- 插件会自动使用 dict/default_pinyin.yaml
```

4. **词库格式**：
   词库支持 YAML 格式（推荐）和 TXT 格式（向后兼容）。

   **YAML 格式**（推荐）：

   ```yaml
   a: [啊, 阿, 吖]
   ai: [爱, 唉, 埃]
   ```

   **TXT 格式**（向后兼容）：

   ```
   a 啊 阿 吖
   ai 爱 唉 埃
   ```
5. **使用方法**：
   Neovim 启动后 `;;` 进入输入状态，`0-9`/空格选词，`Esc` 退出。

## 核心特性

### 1. 浮动窗口绘制

使用 Neovim 原生浮动窗口（floating window）显示候选词列表，具有以下特点：

- **美观的界面**：候选词显示在光标下方，不遮挡编辑内容
- **高亮显示**：当前选中的候选词使用醒目的绿色高亮
- **显示编码**：每个候选词显示原始编码（如 `[ceshi]`），方便学习
- **实时更新**：输入时实时更新候选词列表
- **自动定位**：浮动窗口自动跟随光标位置

### 2. 缩写编码

支持 4 字符缩写编码，快速输入长词：

- **3 字词缩写**：使用首字符、第二字符、尾字符的拼音
  - 例如：`测试输入` 的完整编码是 `ceshishuru`，可以使用缩写 `cssu`（首 `c` + 二 `s` + 尾 `u`）
- **4 字及以上缩写**：使用首字符、第二字符、第三字符、尾字符的拼音
  - 例如：`中华人民共和国` 可以使用缩写 `zhrg`（首 `z` + 二 `h` + 三 `r` + 尾 `g`）
- **自动匹配**：输入 4 字符时，如果匹配到缩写编码，会自动显示对应的长词

### 3. 智能排序优化

多维度排序算法，确保最常用的词优先显示：

- **使用频率排序**：根据词的使用频率自动调整顺序，常用词优先
- **单字优先**：单字词优先于多字词显示，提高输入效率
- **完全匹配优先**：完全匹配的编码优先于部分匹配
- **长度优先**：在相同匹配度下，较短的词优先显示
- **频率文件**：使用频率保存在 `~/.local/share/nvim/ZFVimIM_word_freq.txt`
- **自动学习**：每次选择词后自动更新频率，10 次使用后自动保存

### 4. 自动造词

智能学习用户输入习惯，自动创建新词：

- **触发条件**：
  - 连续选择多个词（2 个以上）
  - 所有词来自同一个数据库
  - 组合后的总长度不超过 `g:ZFVimIM_autoAddWordLen`（默认 12 字符）
- **自动保存**：新词自动添加到词库并保存到文件
- **自定义检查器**：可通过 `g:ZFVimIM_autoAddWordChecker` 自定义造词规则

**示例**：

- 输入 `ceshi` 选择 `测试`，然后输入 `shuru` 选择 `输入`
- 系统自动创建新词 `测试输入`，编码为 `ceshishuru`
- 下次输入 `ceshishuru` 时可以直接选择 `测试输入`

### 5. 翻页功能

支持候选词列表翻页浏览：

- **翻页键**：`-`/`=` 或 `,`/`.` 进行上下翻页（可通过 `g:ZFVimIM_key_pageUp/Down` 自定义）
- **自由滚动模式**：设置 `g:ZFVimIM_freeScroll = 1` 可启用自由滚动，不受 10 个候选词限制
- **页码显示**：在自由滚动模式下，显示完整的页码（如 `01`, `02` 等）

### 6. 动态频率调整

- **自动学习**：使用频率自动记录，常用词自动提升优先级
- **频率文件**：`~/.local/share/nvim/ZFVimIM_word_freq.txt` 保存频率数据
- **自动保存**：每 10 次使用自动保存，Vim 退出时也会保存
- **最大频率**：1000 次（防止溢出）
- **最大条目数**：10000 条（超出时删除最少使用的条目）

## 缓存管理

字典文件更改后，需要更新缓存。

### 缓存更新命令

以下命令可以手动更新缓存：

```vim
" 删除所有缓存文件
:ZFVimIMCacheClear

" 删除缓存并重新加载字典（推荐）
:ZFVimIMCacheUpdate
```

### 使用示例

1. **字典文件更改后**：

   ```vim
   :ZFVimIMCacheUpdate
   ```

   这会删除所有缓存，重新加载字典并生成新的缓存。
2. **仅删除缓存**：

   ```vim
   :ZFVimIMCacheClear
   ```

   下次字典加载时会自动生成新缓存。
3. **重新加载插件**：

   ```vim
   :ZFVimIMReload
   ```

   重新加载整个插件（缓存会自动更新）。

### 故障排除

- 字典更改后未反映 → 执行 `:ZFVimIMCacheUpdate`
- 缓存可能损坏 → 执行 `:ZFVimIMCacheClear` 删除缓存后重启 Vim

## 功能列表

### 命令

#### 插件管理

- `:ZFVimIMReload` - 重新加载整个插件
- `:ZFVimIMCacheClear` - 删除所有缓存文件
- `:ZFVimIMCacheUpdate` - 删除缓存并重新加载字典（推荐）

#### 字典编辑

- `:IMAdd [word] [key]` - 添加词到字典
  - 例: `:IMAdd 测试 ceshi`
  - `:IMAdd!` - 立即应用（临时增加 `g:ZFVimIM_dbEditApplyFlag`）
- `:IMRemove [word] [key]` - 从字典删除词
  - 例: `:IMRemove 测试 ceshi`
  - 省略 `key` 时，从所有匹配的键中删除
  - `:IMRemove!` - 立即应用
- `:IMReorder [word] [key]` - 更改词的顺序（重置频率）
  - 例: `:IMReorder 测试 ceshi`
  - `:IMReorder!` - 立即应用

### 按键映射

#### 基本操作

- `;;` - 切换输入法开/关（Normal/Insert/Visual 模式）
- `;:` - 切换到下一个字典数据库（Normal/Insert/Visual 模式）
- `;,` - 打开添加词对话框（Normal/Insert/Visual 模式）
- `;.` - 打开删除词对话框（Normal/Insert/Visual 模式）

#### 输入中的操作（Insert 模式，输入法启用时）

- `0-9` - 选择候选词（0 是第 10 个候选）
- `<Space>` - 确定第一个候选
- `<Enter>` - 关闭候选菜单（无候选时正常换行）
- `<Esc>` - 取消输入并关闭候选菜单
- `<Backspace>` - 删除 1 个字符（候选菜单显示时更新候选）
- `<Tab>` / `<S-Tab>` - 上下移动候选
- `-` / `=` 或 `,` / `.` - 上下翻页（可通过 `g:ZFVimIM_key_pageUp/Down` 更改）
- `[` / `]` - 左/右分割确定（可通过 `g:ZFVimIM_key_chooseL/R` 更改）
- `<C-d>` - 删除当前选中的候选词（可通过 `g:ZFVimIM_key_deleteWord` 更改）

### 配置变量

#### 字典设置

```lua
-- 默认字典名（无扩展名，自动添加 .yaml）
-- 用于指定插件 dict/ 目录下的词库文件名（不含扩展名）
-- 例如：设置为 "sbzr.userdb" 会查找 dict/sbzr.userdb.yaml
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

-- 自定义字典路径（绝对路径或相对路径，支持 .yaml/.yml）
-- 优先级高于 zfvimim_default_dict_name
-- 如果文件不存在，会自动回退到默认词库
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"
```

**词库加载优先级说明**：

1. `zfvimim_dict_path`（最高优先级）- 指定完整路径的词库文件
2. `zfvimim_default_dict_name` - 指定插件 `dict/` 目录下的词库文件名
3. `default_pinyin.yaml`（默认）- 如果以上都未设置，使用内置默认词库

#### 补全设置

```lua
-- 匹配结果的最大数量（默认: 2000）
vim.g.ZFVimIM_matchLimit = 2000

-- 预测输入的最大数量（默认: 1000）
vim.g.ZFVimIM_predictLimit = 1000

-- 有匹配时的预测输入数（默认: 5）
vim.g.ZFVimIM_predictLimitWhenMatch = 5

-- 启用句子补全（默认: 1）
vim.g.ZFVimIM_sentence = 1

-- 跨数据库搜索（默认: 2）
-- 0: 禁用, 1: 仅完全匹配, 2: 包含预测, 3: 包含部分匹配
vim.g.ZFVimIM_crossable = 2

-- 跨数据库搜索的最大结果数（默认: 2）
vim.g.ZFVimIM_crossDbLimit = 2

-- 跨数据库结果的显示位置（默认: 5）
vim.g.ZFVimIM_crossDbPos = 5
```

#### 自动添加设置

```lua
-- 自动添加词的最大长度（默认: 12 = 3*4）
vim.g.ZFVimIM_autoAddWordLen = 12

-- 自动添加检查器函数列表
-- 函数接收 userWord 列表，返回是否添加（1: 添加, 0: 不添加）
vim.g.ZFVimIM_autoAddWordChecker = []
```

#### 按键映射设置

```lua
-- 启用按键映射（默认: 1）
vim.g.ZFVimIM_keymap = 1

-- 自定义按键映射（默认值）
vim.g.ZFVimIM_key_pageUp = ['-', ',']      -- 上翻页（- 或 ,）
vim.g.ZFVimIM_key_pageDown = ['=', '.']   -- 下翻页（= 或 .）
vim.g.ZFVimIM_key_chooseL = ['[']     -- 左分割
vim.g.ZFVimIM_key_chooseR = [']']     -- 右分割
vim.g.ZFVimIM_key_backspace = ['<bs>'] -- 退格
vim.g.ZFVimIM_key_esc = ['<esc>']     -- 退出
vim.g.ZFVimIM_key_enter = ['<cr>']    -- 回车
vim.g.ZFVimIM_key_space = ['<space>'] -- 空格
vim.g.ZFVimIM_key_tabNext = ['<tab>'] -- 下一个候选
vim.g.ZFVimIM_key_tabPrev = ['<s-tab>'] -- 上一个候选
vim.g.ZFVimIM_key_deleteWord = ['<c-d>'] -- 删除词

-- 候选选择用的额外按键（2-9 的候选用）
vim.g.ZFVimIM_key_candidates = []
```

#### 显示设置

```lua
-- 按键提示显示长度（默认: 无限制，0 禁用）
-- 负数表示不截断，正数按长度截断
vim.g.ZFVimIM_showKeyHint = -1

-- 显示跨数据库提示（默认: 1）
vim.g.ZFVimIM_showCrossDbHint = 1

-- 自由滚动模式（默认: 0）
-- 1 时，候选超过 10 个也可滚动
vim.g.ZFVimIM_freeScroll = 0

-- 状态栏显示设置
vim.g.ZFVimIME_IMEStatus_tagL = ' <'  -- 左标签
vim.g.ZFVimIME_IMEStatus_tagR = '> '  -- 右标签
```

#### 其他设置

```lua
-- 符号映射（键 -> 符号列表或函数）
vim.g.ZFVimIM_symbolMap = {}

-- 缓存路径（默认: ~/.vim_cache/ZFVimIM）
vim.g.ZFVimIM_cachePath = vim.fn.expand("~/.vim_cache/ZFVimIM")

-- 仅在 Insert 模式启用（默认: 1）
vim.g.ZFVimIME_enableOnInsertOnly = 1

-- 缓冲区同步（默认: 1）
vim.g.ZFVimIME_syncBuffer = 1

-- 将 <C-c> 视为 <Esc>（默认: 1）
vim.g.ZFVimIME_fixCtrlC = 1

-- 字典编辑历史限制（默认: 500）
vim.g.ZFVimIM_dbEditLimit = 500
```

### 主要功能

#### 1. 动态频率调整（Dynamic Frequency Adjustment）

- **自动学习**：根据使用频率自动调整候选顺序
- **频率文件**：保存在 `~/.local/share/nvim/ZFVimIM_word_freq.txt`
- **自动保存**：每 10 次使用自动保存，Vim 退出时也保存
- **最大频率**：1000 次（防止溢出）
- **最大条目数**：10000 条

#### 2. 词删除功能

- **输入中删除**：`<C-d>` 立即删除当前选中的候选
- **命令删除**：`:IMRemove [word] [key]` 删除
- **自动保存**：删除后自动保存到字典文件
- **频率重置**：删除时同时删除频率数据

#### 3. 缓存系统

- **自动缓存**：字典加载时自动生成
- **缓存位置**：`~/.vim_cache/ZFVimIM/dbCache_*.vim`
- **更新检查**：自动忽略比字典文件旧的缓存
- **手动更新**：`:ZFVimIMCacheUpdate` 强制更新

#### 4. 自动造词

- **条件**：
  - 连续选择多个词
  - 来自同一个数据库
  - 总长度不超过 `g:ZFVimIM_autoAddWordLen`
- **自定义检查器**：通过 `g:ZFVimIM_autoAddWordChecker` 控制
- **自动保存**：添加后自动保存到字典文件

#### 5. 句子补全（Sentence Completion）

- **功能**：组合多个词补全长句
- **示例**：`ceshi` → `测试`，`shuru` → `输入` → `测试输入` 补全
- **设置**：`g:ZFVimIM_sentence = 1` 启用

#### 6. 跨数据库搜索

- **功能**：从当前数据库以外的数据库搜索候选
- **级别**：
  - `0`: 禁用
  - `1`: 仅显示完全匹配
  - `2`: 包含预测（默认）
  - `3`: 包含部分匹配
- **限制**：`g:ZFVimIM_crossDbLimit` 限制最大结果数

#### 7. 预测输入（Predictive Input）

- **功能**：输入途中预测候选
- **示例**：输入 `ces` 时显示 `ceshi` 的候选
- **限制**：`g:ZFVimIM_predictLimit` 限制最大预测数

#### 8. 搜索缓存

- **功能**：在内存中缓存数据库搜索结果
- **大小限制**：最大 300 条（超出时删除最旧的 200 条）
- **自动清除**：字典编辑时自动清除

### 事件

以下事件已定义，可通过 `autocmd User` 监听：

- `ZFVimIM_event_OnDbInit` - 数据库初始化时
- `ZFVimIM_event_OnStart` - 输入法开始时
- `ZFVimIM_event_OnStop` - 输入法停止时
- `ZFVimIM_event_OnEnable` - 输入法启用时
- `ZFVimIM_event_OnDisable` - 输入法禁用时
- `ZFVimIM_event_OnAddWord` - 添加词时
  - `g:ZFVimIM_event_OnAddWord` 设置为 `{dbId, key, word}`
- `ZFVimIM_event_OnDbChange` - 切换数据库时
- `ZFVimIM_event_OnUpdate` - 更新候选时
- `ZFVimIM_event_OnUpdateOmni` - 更新候选菜单时
- `ZFVimIM_event_OnCompleteDone` - 确定候选时
  - `g:ZFVimIM_choosedWord` 设置为选中的词信息
- `ZFVimIM_event_OnUpdateDb` - 更新数据库时

### 数据结构

#### 数据库结构

```vim
g:ZFVimIM_db = [
  {
    'dbId': 1,                    -- 自动生成ID
    'name': 'sbzr',               -- 数据库名
    'priority': 100,              -- 优先级（小者优先）
    'switchable': 1,              -- 可切换
    'editable': 1,                -- 可编辑
    'crossable': 2,               -- 跨搜索级别
    'crossDbLimit': 2,            -- 跨搜索结果数限制
    'dbMap': {                    -- 字典数据（按 a-z 分割）
      'a': ['a#啊,阿#3,2', ...],
      'b': ['ba#吧,把#1', ...],
    },
    'dbEdit': [],                 -- 编辑历史
    'dbSearchCache': {},          -- 搜索缓存
    'implData': {                 -- 实现数据
      'dictPath': '/path/to/dict.yaml',  -- 支持 .yaml/.yml
    },
  },
]
```

#### 补全结果结构

```vim
[
  {
    'dbId': 1,                    -- 数据库ID
    'len': 2,                     -- 匹配的键长度
    'key': 'ceshi',               -- 完整键
    'word': '测试',               -- 词
    'type': 'match',              -- 类型: match/predict/sentence/subMatch
    'sentenceList': [             -- 仅句子补全时
      {'key': 'ceshi', 'word': '测试'},
      {'key': 'shuru', 'word': '输入'},
    ],
  },
]
```

## 升级策略

- 若需更新核心实现，请在 `iamcheyan/ZFVimIM` fork 中同步修改后再运行 `:Lazy sync`。
- 仅替换词库时，只需更新 `zfvimim_db` 目录内容，无需改动本仓库。
