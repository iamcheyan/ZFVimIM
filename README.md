# 升级 ZFVimIM 说明

## 关于本项目

本项目基于 [ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)，由于原项目已停止维护，无法在新版本的 Neovim 中使用，本版本已适配 Neovim 0.11（测试版本：v0.11.5）。

做了以下最小化改动，便于与本地词库配合：

- 通过 `vim.g.zfvimim_dict_path` 指定词库位置（默认读取 `~/.dotfiles/config/nvim/zfvimim_db/sbzr.userdb.yaml`）。
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
- 位置：`~/.local/share/nvim/lazy/ZFVimIM/dict/default_pinyin.yaml`
- 包含常用汉字和词汇，可直接使用

**自动加载机制**：
- 如果未设置 `vim.g.zfvimim_dict_path`，插件会自动加载默认词库 `dict/default_pinyin.yaml`（如果不存在则回退到 `.txt` 格式）
- 如果设置了 `vim.g.zfvimim_dict_path`，则使用指定的词库文件（支持 `.yaml`、`.yml` 和 `.txt` 格式）

### 配置步骤

1. **无需配置（推荐首次使用）**：
   插件会自动使用默认词库，无需任何配置即可开始使用。

2. **使用自定义词库**：
   在 `lua/config/options.lua` 设置：
   ```lua
   vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"
   ```

3. **显式指定默认词库**（可选）：
   如果需要显式指定默认词库路径：
   ```lua
   vim.g.zfvimim_dict_path = vim.fn.stdpath("data") .. "/lazy/ZFVimIM/dict/default_pinyin.yaml"
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

4. **使用方法**：
   Neovim 启动后 `;;` 进入输入状态，`0-9`/空格选词，`Esc` 退出。

## キャッシュ管理

辞書ファイルを変更した場合、キャッシュを更新する必要があります。

### キャッシュ更新コマンド

以下のコマンドでキャッシュを手動で更新できます：

```vim
" すべてのキャッシュファイルを削除
:ZFVimIMCacheClear

" キャッシュを削除して辞書を再読み込み（推奨）
:ZFVimIMCacheUpdate
```

### 使用例

1. **辞書ファイルを変更した後**：
   ```vim
   :ZFVimIMCacheUpdate
   ```
   これにより、すべてのキャッシュが削除され、辞書が再読み込みされて新しいキャッシュが生成されます。

2. **キャッシュのみを削除したい場合**：
   ```vim
   :ZFVimIMCacheClear
   ```
   次回の辞書読み込み時に新しいキャッシュが自動生成されます。

3. **プラグイン全体を再読み込みする場合**：
   ```vim
   :ZFVimIMReload
   ```
   プラグイン全体を再読み込みします（キャッシュは自動的に更新されます）。

### トラブルシューティング

- 辞書を変更したのに反映されない場合 → `:ZFVimIMCacheUpdate` を実行
- キャッシュが破損している可能性がある場合 → `:ZFVimIMCacheClear` でキャッシュを削除してから Vim を再起動

## 機能一覧

### コマンド

#### プラグイン管理
- `:ZFVimIMReload` - プラグイン全体を再読み込み
- `:ZFVimIMCacheClear` - すべてのキャッシュファイルを削除
- `:ZFVimIMCacheUpdate` - キャッシュを削除して辞書を再読み込み（推奨）

#### 辞書編集
- `:IMAdd [word] [key]` - 単語を辞書に追加
  - 例: `:IMAdd 测试 ceshi`
  - `:IMAdd!` - 即座に適用（`g:ZFVimIM_dbEditApplyFlag` を一時的に増加）
- `:IMRemove [word] [key]` - 辞書から単語を削除
  - 例: `:IMRemove 测试 ceshi`
  - `key` を省略すると、該当するすべてのキーから削除
  - `:IMRemove!` - 即座に適用
- `:IMReorder [word] [key]` - 単語の順序を変更（頻度をリセット）
  - 例: `:IMReorder 测试 ceshi`
  - `:IMReorder!` - 即座に適用

### キーマッピング

#### 基本操作
- `;;` - 入力法のオン/オフを切り替え（Normal/Insert/Visual モード）
- `;:` - 次の辞書データベースに切り替え（Normal/Insert/Visual モード）
- `;,` - 単語追加ダイアログを開く（Normal/Insert/Visual モード）
- `;.` - 単語削除ダイアログを開く（Normal/Insert/Visual モード）

#### 入力中の操作（Insert モード、入力法有効時）
- `0-9` - 候補を選択（0 は 10 番目の候補）
- `<Space>` - 最初の候補を確定
- `<Enter>` - 候補メニューを閉じる（候補がない場合は通常の改行）
- `<Esc>` - 入力をキャンセルして候補メニューを閉じる
- `<Backspace>` - 1文字削除（候補メニュー表示中は候補を更新）
- `<Tab>` / `<S-Tab>` - 候補を上下に移動
- `-` / `=` または `,` / `.` - 候補ページを上下に移動（`g:ZFVimIM_key_pageUp/Down` で変更可能）
- `[` / `]` - 左/右に分割して確定（`g:ZFVimIM_key_chooseL/R` で変更可能）
- `<C-d>` - 現在選択中の候補を辞書から削除（`g:ZFVimIM_key_deleteWord` で変更可能）

### 設定変数

#### 辞書設定
```lua
-- デフォルト辞書名（拡張子なし、.yaml が自動追加、.txt にフォールバック）
vim.g.zfvimim_default_dict_name = "sbzr.userdb"

-- カスタム辞書パス（絶対パスまたは相対パス、.yaml/.yml/.txt をサポート）
vim.g.zfvimim_dict_path = vim.fn.stdpath("config") .. "/zfvimim_db/sbzr.userdb.yaml"
```

#### 補完設定
```lua
-- マッチ結果の最大数（デフォルト: 2000）
vim.g.ZFVimIM_matchLimit = 2000

-- 予測入力の最大数（デフォルト: 1000）
vim.g.ZFVimIM_predictLimit = 1000

-- マッチがある場合の予測入力数（デフォルト: 5）
vim.g.ZFVimIM_predictLimitWhenMatch = 5

-- 文補完を有効化（デフォルト: 1）
vim.g.ZFVimIM_sentence = 1

-- クロスデータベース検索（デフォルト: 2）
-- 0: 無効, 1: 完全一致のみ, 2: 予測も含む, 3: 部分一致も含む
vim.g.ZFVimIM_crossable = 2

-- クロスデータベース検索の最大結果数（デフォルト: 2）
vim.g.ZFVimIM_crossDbLimit = 2

-- クロスデータベース結果の表示位置（デフォルト: 5）
vim.g.ZFVimIM_crossDbPos = 5
```

#### 自動追加設定
```lua
-- 自動追加する単語の最大長（デフォルト: 12 = 3*4）
vim.g.ZFVimIM_autoAddWordLen = 12

-- 自動追加チェッカー関数のリスト
-- 関数は userWord リストを受け取り、追加するかどうかを返す（1: 追加, 0: 追加しない）
vim.g.ZFVimIM_autoAddWordChecker = []
```

#### キーマッピング設定
```lua
-- キーマッピングを有効化（デフォルト: 1）
vim.g.ZFVimIM_keymap = 1

-- カスタムキーマッピング（デフォルト値）
vim.g.ZFVimIM_key_pageUp = ['-', ',']      -- ページアップ（- または ,）
vim.g.ZFVimIM_key_pageDown = ['=', '.']   -- ページダウン（= または .）
vim.g.ZFVimIM_key_chooseL = ['[']     -- 左に分割
vim.g.ZFVimIM_key_chooseR = [']']     -- 右に分割
vim.g.ZFVimIM_key_backspace = ['<bs>'] -- バックスペース
vim.g.ZFVimIM_key_esc = ['<esc>']     -- エスケープ
vim.g.ZFVimIM_key_enter = ['<cr>']    -- エンター
vim.g.ZFVimIM_key_space = ['<space>'] -- スペース
vim.g.ZFVimIM_key_tabNext = ['<tab>'] -- 次の候補
vim.g.ZFVimIM_key_tabPrev = ['<s-tab>'] -- 前の候補
vim.g.ZFVimIM_key_deleteWord = ['<c-d>'] -- 単語削除

-- 候補選択用の追加キー（2-9 の候補用）
vim.g.ZFVimIM_key_candidates = []
```

#### 表示設定
```lua
-- キーヒントを表示する長さ（デフォルト: 無制限、0 で無効）
-- 负数表示不截断，正数按长度截断。
vim.g.ZFVimIM_showKeyHint = -1

-- クロスデータベースヒントを表示（デフォルト: 1）
vim.g.ZFVimIM_showCrossDbHint = 1

-- 自由スクロールモード（デフォルト: 0）
-- 1 にすると、候補が 10 個を超えてもスクロール可能
vim.g.ZFVimIM_freeScroll = 0

-- ステータスライン表示設定
vim.g.ZFVimIME_IMEStatus_tagL = ' <'  -- 左タグ
vim.g.ZFVimIME_IMEStatus_tagR = '> '  -- 右タグ
```

#### その他の設定
```lua
-- 記号マップ（キー -> 記号のリストまたは関数）
vim.g.ZFVimIM_symbolMap = {}

-- キャッシュパス（デフォルト: ~/.vim_cache/ZFVimIM）
vim.g.ZFVimIM_cachePath = vim.fn.expand("~/.vim_cache/ZFVimIM")

-- Insert モードでのみ有効化（デフォルト: 1）
vim.g.ZFVimIME_enableOnInsertOnly = 1

-- バッファ同期（デフォルト: 1）
vim.g.ZFVimIME_syncBuffer = 1

-- <C-c> を <Esc> として扱う（デフォルト: 1）
vim.g.ZFVimIME_fixCtrlC = 1

-- 辞書編集の履歴制限（デフォルト: 500）
vim.g.ZFVimIM_dbEditLimit = 500
```

### 主要機能

#### 1. 動的頻度調整（Dynamic Frequency Adjustment）
- **自動学習**: 使用頻度に基づいて候補の順序を自動調整
- **頻度ファイル**: `~/.local/share/nvim/ZFVimIM_word_freq.txt` に保存
- **自動保存**: 10回使用ごとに自動保存、Vim終了時にも保存
- **最大頻度**: 1000回まで（オーバーフロー防止）
- **最大エントリ数**: 10000エントリまで保持

#### 2. 単語削除機能
- **入力中削除**: `<C-d>` で現在選択中の候補を即座に削除
- **コマンド削除**: `:IMRemove [word] [key]` で削除
- **自動保存**: 削除後、辞書ファイルに自動保存
- **頻度リセット**: 削除時に頻度データも削除

#### 3. キャッシュシステム
- **自動キャッシュ**: 辞書読み込み時に自動生成
- **キャッシュ場所**: `~/.vim_cache/ZFVimIM/dbCache_*.vim`
- **更新チェック**: 辞書ファイルより古いキャッシュは自動的に無視
- **手動更新**: `:ZFVimIMCacheUpdate` で強制更新

#### 4. 自動単語追加
- **条件**: 
  - 複数の単語を連続して選択
  - 同じデータベースから
  - 合計長が `g:ZFVimIM_autoAddWordLen` 以下
- **カスタムチェッカー**: `g:ZFVimIM_autoAddWordChecker` で制御可能
- **自動保存**: 追加後、辞書ファイルに自動保存

#### 5. 文補完（Sentence Completion）
- **機能**: 複数の単語を組み合わせて長い文を補完
- **例**: `ceshi` → `测试`、`shuru` → `输入` → `测试输入` として補完
- **設定**: `g:ZFVimIM_sentence = 1` で有効化

#### 6. クロスデータベース検索
- **機能**: 現在のデータベース以外からも候補を検索
- **レベル**:
  - `0`: 無効
  - `1`: 完全一致のみ表示
  - `2`: 予測も含む（デフォルト）
  - `3`: 部分一致も含む
- **制限**: `g:ZFVimIM_crossDbLimit` で最大結果数を制限

#### 7. 予測入力（Predictive Input）
- **機能**: 入力途中で候補を予測
- **例**: `ces` 入力時に `ceshi` の候補を表示
- **制限**: `g:ZFVimIM_predictLimit` で最大予測数

#### 8. 検索キャッシュ
- **機能**: データベース検索結果をメモリにキャッシュ
- **サイズ制限**: 最大300エントリ（超過時は古い200エントリを削除）
- **自動クリア**: 辞書編集時に自動クリア

### イベント

以下のイベントが定義されており、`autocmd User` で監視可能：

- `ZFVimIM_event_OnDbInit` - データベース初期化時
- `ZFVimIM_event_OnStart` - 入力法開始時
- `ZFVimIM_event_OnStop` - 入力法停止時
- `ZFVimIM_event_OnEnable` - 入力法有効化時
- `ZFVimIM_event_OnDisable` - 入力法無効化時
- `ZFVimIM_event_OnAddWord` - 単語追加時
  - `g:ZFVimIM_event_OnAddWord` に `{dbId, key, word}` が設定される
- `ZFVimIM_event_OnDbChange` - データベース切り替え時
- `ZFVimIM_event_OnUpdate` - 候補更新時
- `ZFVimIM_event_OnUpdateOmni` - 候補メニュー更新時
- `ZFVimIM_event_OnCompleteDone` - 候補確定時
  - `g:ZFVimIM_choosedWord` に選択された単語情報が設定される
- `ZFVimIM_event_OnUpdateDb` - データベース更新時

### データ構造

#### データベース構造
```vim
g:ZFVimIM_db = [
  {
    'dbId': 1,                    -- 自動生成ID
    'name': 'sbzr',               -- データベース名
    'priority': 100,              -- 優先度（小さい方が優先）
    'switchable': 1,              -- 切り替え可能か
    'editable': 1,                -- 編集可能か
    'crossable': 2,               -- クロス検索レベル
    'crossDbLimit': 2,            -- クロス検索結果数制限
    'dbMap': {                    -- 辞書データ（a-z で分割）
      'a': ['a#啊,阿#3,2', ...],
      'b': ['ba#吧,把#1', ...],
    },
    'dbEdit': [],                 -- 編集履歴
    'dbSearchCache': {},          -- 検索キャッシュ
    'implData': {                 -- 実装データ
      'dictPath': '/path/to/dict.yaml',  -- .yaml/.yml/.txt をサポート
    },
  },
]
```

#### 補完結果構造
```vim
[
  {
    'dbId': 1,                    -- データベースID
    'len': 2,                     -- マッチしたキーの長さ
    'key': 'ceshi',               -- 完全なキー
    'word': '测试',               -- 単語
    'type': 'match',              -- タイプ: match/predict/sentence/subMatch
    'sentenceList': [             -- 文補完の場合のみ
      {'key': 'ceshi', 'word': '测试'},
      {'key': 'shuru', 'word': '输入'},
    ],
  },
]
```

## 升级策略

- 若需更新核心实现，请在 `iamcheyan/ZFVimIM` fork 中同步修改后再运行 `:Lazy sync`。
- 仅替换词库时，只需更新 `zfvimim_db` 目录内容，无需改动本仓库。
