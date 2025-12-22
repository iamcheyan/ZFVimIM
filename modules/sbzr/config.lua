--- ZFVimIM SBZR 模块配置文件
---
--- 此文件位于 modules 目录中，用于配置 SBZR（声笔自然）模块
---
--- SBZR 模式特性：
--- - 输入4码后，可以使用 a/e/u/i/o 快速选择第2-6个候选词
--- - 候选词标签：['', 'a', 'e', 'u', 'i', 'o']（第1个无标签，第2-6个对应 a/e/u/i/o）
--- - 自动限制候选词数量为6个，提高选择效率
---
--- 使用方法：
--- 1. 在主配置文件中启用 SBZR 模块：
---    vim.g.ZFVimIM_settings = { 'sbzr' }
---    vim.g.zfvimim_default_dict_name = "sbzr"
---
--- 2. 或者直接加载此配置文件：
---    dofile(vim.fn.stdpath('data') .. '/lazy/ZFVimIM/modules/sbzr/config.lua')

-- ============================================================
-- SBZR 模块配置
-- ============================================================

-- 启用 SBZR 模式
vim.g.ZFVimIM_settings = { 'sbzr' }

-- 设置词库名称（统一从 dict/ 目录查找）
vim.g.zfvimim_default_dict_name = "sbzr"
