# SBZR 模块

声笔自然（SBZR）输入模式模块。

## 功能特性

- 输入4码后，可以使用 `a/e/u/i/o` 快速选择第2-6个候选词
- 候选词标签：`['', 'a', 'e', 'u', 'i', 'o']`（第1个无标签，第2-6个对应 a/e/u/i/o）
- 每页显示6个候选词，提高选择效率
- 翻页功能：
  - `,` 键：向上翻页
  - `.` 键：向下翻页
  - `←` 键：向上翻页
  - `→` 键：向下翻页
  - 支持浏览所有候选词，不受6个显示限制

## 启用方式

在配置文件中设置：

```lua
vim.g.ZFVimIM_settings = { 'sbzr' }
vim.g.zfvimim_default_dict_name = "sbzr"
```

或者使用模块自带的配置文件：

```lua
-- 加载模块配置
dofile(vim.fn.stdpath('data') .. '/lazy/ZFVimIM/modules/sbzr/config.lua')
```

## 文件说明

- `ZFVimIM_sbzr.vim` - SBZR 模块核心代码
- `config.lua` - 模块配置文件
- 词库文件：`dict/sbzr.yaml`（统一存放在 dict/ 目录）

## 禁用模块

删除或重命名 `modules/sbzr/` 目录，或从配置中移除 `'sbzr'` 设置即可禁用。

