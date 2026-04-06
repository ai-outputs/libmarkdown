/**
 * YAML Front Matter 示例
 * 
 * 本文件展示了如何使用 YAML 元数据功能。
 * 
 * 编译方法：
 * valac --pkg gee-0.8 --pkg glib-2.0 --pkg gio-2.0 \
 *       yaml-types.vala yaml-reader.vala \
 *       markdown-types.vala markdown-nodes.vala \
 *       markdown-reader.vala markdown-writer.vala \
 *       markdown.vala example-yaml.vala -o yaml-example
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

using Markdown;

/**
 * YAML Front Matter 示例程序
 */
public int main(string[] args) {
    print("=== YAML Front Matter 示例 ===\n\n");
    
    try {
        // 示例 1：解析带元数据的文档
        example_parse_front_matter();
        
        // 示例 2：创建带元数据的文档
        example_create_with_metadata();
        
        // 示例 3：操作元数据
        example_manipulate_metadata();
        
        // 示例 4：复杂元数据结构
        example_complex_metadata();
        
    } catch (MarkdownError e) {
        stderr.printf("错误: %s\n", e.message);
        return 1;
    }
    
    print("\n=== 示例执行完成 ===\n");
    return 0;
}

/**
 * 示例 1：解析带 YAML Front Matter 的文档
 */
private void example_parse_front_matter() throws MarkdownError {
    print("【示例 1】解析 YAML Front Matter\n");
    print("---------------------------------\n");
    
    string markdown_text = """---
title: API 文档指南
author: 张三
date: 2024-01-15
tags:
  - markdown
  - vala
  - documentation
version: 1.0.0
draft: false
---

# API 文档指南

本文档介绍如何使用 Markdown 模块。

## 概述

这是一个 **完整** 的示例文档。
""";

    // 解析文档
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    // 检查是否有元数据
    if (doc.has_metadata) {
        print("文档包含元数据！\n\n");
        
        var meta = doc.metadata;
        
        // 读取简单字段
        print("标题: %s\n", meta.get_string("title", "未命名"));
        print("作者: %s\n", meta.get_string("author", "未知"));
        print("日期: %s\n", meta.get_string("date", ""));
        print("版本: %s\n", meta.get_string("version", ""));
        print("草稿: %s\n", meta.get_boolean("draft") ? "是" : "否");
        
        // 读取标签列表
        print("标签: ");
        var tags = meta.get_string_list("tags");
        print(string.joinv(", ", tags));
        print("\n");
        
        // 使用便捷方法获取标题
        print("\n文档标题（自动检测）: %s\n", doc.get_title());
    } else {
        print("文档不包含元数据\n");
    }
    
    print("\n");
}

/**
 * 示例 2：创建带元数据的文档
 */
private void example_create_with_metadata() throws MarkdownError {
    print("【示例 2】创建带元数据的文档\n");
    print("---------------------------------\n");
    
    // 创建文档
    var doc = new Document();
    
    // 添加元数据
    var meta = doc.get_or_create_metadata();
    meta.set_string("title", "我的文档");
    meta.set_string("author", "李四");
    meta.set_string("date", "2024-03-20");
    meta.set_boolean("published", true);
    meta.set_integer("views", 100);
    
    // 添加字符串列表
    meta.set_string_list("categories", {"技术", "编程", "Vala"});
    
    // 添加内容
    doc.append_child(NodeFactory.heading(HeadingLevel.H1, "我的文档"));
    doc.append_child(NodeFactory.paragraph("这是一个由程序创建的文档，包含 YAML 元数据。"));
    
    // 渲染输出
    var writer = new MarkdownWriter();
    string output = writer.render(doc);
    
    print("生成的 Markdown：\n%s\n", output);
}

/**
 * 示例 3：操作元数据
 */
private void example_manipulate_metadata() throws MarkdownError {
    print("【示例 3】操作元数据\n");
    print("---------------------------------\n");
    
    string markdown_text = """---
title: 原始标题
version: 1.0
---

# 内容
""";
    
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    print("原始标题: %s\n", doc.get_metadata_string("title"));
    
    // 修改元数据
    doc.set_metadata_string("title", "修改后的标题");
    doc.set_metadata_string("modified", "2024-03-20");
    
    print("修改后标题: %s\n", doc.get_metadata_string("title"));
    print("修改日期: %s\n", doc.get_metadata_string("modified"));
    
    // 使用元数据对象直接操作
    if (doc.has_metadata) {
        var meta = doc.metadata;
        
        // 检查键是否存在
        print("\n键 'title' 存在: %s\n", meta.has_key("title") ? "是" : "否");
        print("键 'unknown' 存在: %s\n", meta.has_key("unknown") ? "是" : "否");
        
        // 获取所有键
        print("\n所有元数据键: ");
        var keys = meta.get_keys();
        print(string.joinv(", ", keys.to_array()));
        print("\n");
    }
    
    print("\n");
}

/**
 * 示例 4：复杂元数据结构
 */
private void example_complex_metadata() throws MarkdownError {
    print("【示例 4】复杂元数据结构\n");
    print("---------------------------------\n");
    
    string markdown_text = """---
title: 复杂元数据示例
metadata:
  created: 2024-01-01
  updated: 2024-03-20
  author:
    name: 王五
    email: wangwu@example.com
settings:
  theme: dark
  language: zh-CN
  features:
    - toc
    - search
    - comments
---

# 文档内容

这是一个包含复杂元数据结构的文档。
""";
    
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    if (doc.has_metadata) {
        var meta = doc.metadata;
        var data = meta.get_data();
        
        print("顶层元数据键:\n");
        foreach (var key in data.keys) {
            print("  - %s\n", key);
        }
        
        // 访问嵌套数据
        var metadata_val = data.get_value("metadata");
        if (metadata_val != null && metadata_val.value_type == ValueType.MAP) {
            var metadata_map = metadata_val.get_map();
            print("\nmetadata 字段内容:\n");
            foreach (var entry in metadata_map.entries) {
                print("  %s: %s\n", entry.key, entry.value.to_string());
            }
        }
        
        var settings_val = data.get_value("settings");
        if (settings_val != null && settings_val.value_type == ValueType.MAP) {
            var settings_map = settings_val.get_map();
            print("\nsettings 字段内容:\n");
            foreach (var entry in settings_map.entries) {
                if (entry.value.value_type == ValueType.LIST) {
                    var list = entry.value.get_list();
                    var items = new string[list.size];
                    int i = 0;
                    foreach (var item in list) {
                        items[i++] = item.get_string();
                    }
                    print("  %s: [%s]\n", entry.key, string.joinv(", ", items));
                } else {
                    print("  %s: %s\n", entry.key, entry.value.to_string());
                }
            }
        }
    }
    
    print("\n完整输出：\n");
    var writer = new MarkdownWriter();
    print("%s\n", writer.render(doc));
}
