#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
整理不需要的文件到新文件夹

将工具脚本、临时文件、备份文件等移动到 archive/ 目录
"""

import os
import shutil
import sys

# 程序运行必需的脚本（不能移动）
REQUIRED_SCRIPTS = {
    'import_txt_to_db.py',
    'sync_txt_to_db.py',
    'db_export_to_txt.py',
    'db_export_for_edit.py',
    'db_add_word.py',
    'db_remove_word.py',
    'dbLoad.py',
    'dbFunc.py',
    'dbSave.py',
    'dbNormalize.py',
    'dbCleanup.py',
    'db_update_frequency.py',
}

# 需要保留的 dict 文件（根据实际使用情况调整）
# 这里只列出可能需要的，实际根据用户配置决定
KEEP_DICT_FILES = {
    'default.yaml',
    'default.db',
    'sbxlm.sbzr.yaml',
    'sbxlm.sbzr.db',
}


def organize_files(base_dir):
    """整理文件"""
    archive_dir = os.path.join(base_dir, 'archive')
    
    # 创建 archive 目录结构
    archive_misc = os.path.join(archive_dir, 'misc')
    archive_dict = os.path.join(archive_dir, 'dict')
    archive_assast = os.path.join(archive_dir, 'assast')
    
    os.makedirs(archive_misc, exist_ok=True)
    os.makedirs(archive_dict, exist_ok=True)
    os.makedirs(archive_assast, exist_ok=True)
    
    moved_files = []
    
    # 1. 移动 misc/ 目录下的工具脚本
    misc_dir = os.path.join(base_dir, 'misc')
    if os.path.exists(misc_dir):
        for filename in os.listdir(misc_dir):
            if filename.endswith('.py') and filename not in REQUIRED_SCRIPTS:
                src = os.path.join(misc_dir, filename)
                if os.path.isfile(src):
                    dst = os.path.join(archive_misc, filename)
                    shutil.move(src, dst)
                    moved_files.append(('misc', filename))
                    print(f'移动: misc/{filename} -> archive/misc/{filename}')
    
    # 2. 移动 __pycache__ 目录
    pycache_dir = os.path.join(misc_dir, '__pycache__')
    if os.path.exists(pycache_dir):
        archive_pycache = os.path.join(archive_misc, '__pycache__')
        shutil.move(pycache_dir, archive_pycache)
        moved_files.append(('misc', '__pycache__'))
        print(f'移动: misc/__pycache__ -> archive/misc/__pycache__')
    
    # 3. 移动 dict/ 目录下的备份文件
    dict_dir = os.path.join(base_dir, 'dict')
    if os.path.exists(dict_dir):
        # 备份文件
        for filename in os.listdir(dict_dir):
            if filename.endswith('_backup_') or 'backup' in filename.lower():
                src = os.path.join(dict_dir, filename)
                if os.path.isfile(src):
                    dst = os.path.join(archive_dict, filename)
                    shutil.move(src, dst)
                    moved_files.append(('dict', filename))
                    print(f'移动: dict/{filename} -> archive/dict/{filename}')
        
        # 个人词库/声笔自然/ 下的非词库文件
        sbn_dir = os.path.join(dict_dir, '个人词库', '声笔自然')
        if os.path.exists(sbn_dir):
            archive_sbn = os.path.join(archive_dict, '个人词库', '声笔自然')
            os.makedirs(archive_sbn, exist_ok=True)
            
            for filename in os.listdir(sbn_dir):
                if filename not in ['sbxlm.sbzr.yaml']:  # 保留实际使用的词库
                    src = os.path.join(sbn_dir, filename)
                    if os.path.isfile(src):
                        dst = os.path.join(archive_sbn, filename)
                        shutil.move(src, dst)
                        moved_files.append(('dict/个人词库/声笔自然', filename))
                        print(f'移动: dict/个人词库/声笔自然/{filename} -> archive/dict/个人词库/声笔自然/{filename}')
        
        # 参考词库（如果用户不使用）
        # 这里保留，因为可能作为参考使用
        # 如果确定不需要，可以取消注释下面的代码
        # common_pinyin_dir = os.path.join(dict_dir, '常用词库（薄荷全拼）')
        # if os.path.exists(common_pinyin_dir):
        #     archive_common = os.path.join(archive_dict, '常用词库（薄荷全拼）')
        #     shutil.move(common_pinyin_dir, archive_common)
        #     moved_files.append(('dict', '常用词库（薄荷全拼）'))
    
    # 4. 移动 assast/ 目录（示例和文档）
    assast_dir = os.path.join(base_dir, 'assast')
    if os.path.exists(assast_dir):
        shutil.move(assast_dir, archive_assast)
        moved_files.append(('', 'assast'))
        print(f'移动: assast/ -> archive/assast/')
    
    print(f'\n✅ 整理完成！共移动 {len(moved_files)} 个项目')
    print(f'归档目录: {archive_dir}')
    return moved_files


if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    organize_files(base_dir)

