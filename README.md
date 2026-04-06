# Vala Markdown 模块

一个完整的 Markdown 读写模块，为 Vala 语言客户端提供 Skill 支持。支持 YAML Front Matter 元数据解析。

## 概述

本模块提供了完整的 Markdown 处理能力，包括：

- **解析 (Reading)**：将 Markdown 文本转换为内存中的节点树
- **生成 (Writing)**：将节点树序列化为 Markdown 文本
- **操作 (Manipulation)**：提供完整的节点树操作 API
- **YAML 元数据**：支持 YAML Front Matter 解析和生成

## 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Markdown Module                          │
├─────────────────────────────────────────────────────────────┤
│  快捷函数: parse(), render(), normalize(), read_file()      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Reader    │  │   Writer    │  │    NodeFactory      │  │
│  │  解析器     │  │   生成器    │  │     节点工厂        │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │            │
│         └────────────────┼─────────────────────┘            │
│                          │                                  │
│  ┌───────────────────────┴───────────────────────────────┐  │
│  │                    Node Tree                          │  │
│  │  Document ─┬─ Heading ──── Text                       │  │
│  │            ├─ Paragraph ── Text/Emphasis/Strong/Link  │  │
│  │            ├─ List ─────── ListItem                   │  │
│  │            ├─ CodeBlock                               │  │
│  │            ├─ BlockQuote                              │  │
│  │            └─ Metadata (YAML)                         │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                  │
│  ┌───────────────────────┴───────────────────────────────┐  │
│  │                    Type System                        │  │
│  │  NodeType | YamlValue | Metadata | ParseOptions       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 文件结构

```
vala-markdown/
├── yaml-types.vala          # YAML 类型定义
├── yaml-reader.vala         # YAML 解析器
├── markdown-types.vala      # Markdown 类型定义
├── markdown-nodes.vala      # 节点实现
├── markdown-reader.vala     # 解析器实现
├── markdown-writer.vala     # 生成器实现
├── markdown.vala            # 模块入口
├── example.vala             # 使用示例
├── example-yaml.vala        # YAML 示例
├── test.vala                # 单元测试
├── meson.build              # Meson 构建配置
└── README.md                # 本文件
```

## 快速开始

### 编译

使用 Meson 构建系统：

```bash
# 配置构建
meson setup build

# 编译
cd build
ninja

# 运行测试
ninja test

# 安装
ninja install
```

或使用 valac 直接编译：

```bash
valac --pkg gee-0.8 --pkg glib-2.0 --pkg gio-2.0 \
      yaml-types.vala yaml-reader.vala \
      markdown-types.vala markdown-nodes.vala \
      markdown-reader.vala markdown-writer.vala \
      markdown.vala example.vala -o markdown-example

./markdown-example
```

### 基础用法

```vala
using Markdown;

// 解析 Markdown 文本（自动检测 YAML Front Matter）
var reader = new MarkdownReader();
var doc = reader.parse("""
---
title: 文档标题
author: 作者
---

# Hello

World!
""");

// 访问元数据
if (doc.has_metadata) {
    print("标题: %s\n", doc.get_metadata_string("title"));
    print("作者: %s\n", doc.get_metadata_string("author"));
}

// 渲染为 Markdown
var writer = new MarkdownWriter();
string output = writer.render(doc);
print("%s\n", output);
```

## YAML 元数据支持

### 解析 YAML Front Matter

模块会自动检测和解析文档开头的 YAML 元数据：

```vala
string markdown = """---
title: API 文档
author: 张三
date: 2024-01-15
tags:
  - markdown
  - vala
version: 1.0.0
draft: false
---

# 文档内容
""";

var reader = new MarkdownReader();
var doc = reader.parse(markdown);

if (doc.has_metadata) {
    var meta = doc.metadata;
    
    // 简单字段
    string title = meta.get_string("title");
    bool draft = meta.get_boolean("draft");
    
    // 列表字段
    string[] tags = meta.get_string_list("tags");
}
```

### 创建带元数据的文档

```vala
var doc = new Document();

// 添加元数据
var meta = doc.get_or_create_metadata();
meta.set_string("title", "我的文档");
meta.set_string("author", "李四");
meta.set_boolean("published", true);
meta.set_string_list("tags", {"技术", "编程"});

// 添加内容
doc.append_child(NodeFactory.heading(HeadingLevel.H1, "内容"));

// 渲染（自动包含 YAML Front Matter）
var writer = new MarkdownWriter();
print("%s\n", writer.render(doc));
```

### YAML 值类型

支持完整的 YAML 数据类型：

| 类型 | 类 | 示例 |
|------|-----|------|
| 空值 | `YamlNull` | `null`, `~` |
| 布尔 | `YamlBoolean` | `true`, `false` |
| 整数 | `YamlInteger` | `42`, `-10` |
| 浮点 | `YamlFloat` | `3.14` |
| 字符串 | `YamlString` | `"hello"` |
| 列表 | `YamlList` | `[a, b, c]` |
| 映射 | `YamlMap` | `{key: value}` |
| 日期 | `YamlDate` | `2024-01-15` |

### 访问嵌套数据

```vala
// 假设有如下元数据：
// metadata:
//   author:
//     name: 张三
//     email: zhang@example.com

var meta = doc.metadata;
var data = meta.get_data();

var metadata_val = data.get_value("metadata");
if (metadata_val != null) {
    var map = metadata_val.get_map();
    var author = map.get_value("author");
    if (author != null) {
        var author_map = author.get_map();
        string name = author_map.get_value("name").get_string();
    }
}
```

## 核心接口

### 1. YAML 类型系统 (yaml-types.vala)

#### YamlValue 基类

所有 YAML 值的抽象基类：

```vala
public abstract class YamlValue : Object {
    public abstract ValueType value_type { get; }
    
    public virtual bool get_boolean(bool default = false);
    public virtual int64 get_integer(int64 default = 0);
    public virtual string get_string(string default = "");
    public virtual Gee.List<YamlValue>? get_list();
    public virtual Gee.Map<string, YamlValue>? get_map();
    
    public abstract YamlValue clone();
    public abstract string to_yaml_string(int indent = 0);
}
```

#### Metadata 类

文档元数据容器：

```vala
public class Metadata : Object {
    public YamlMap get_data();
    public void set_value(string key, YamlValue value);
    public YamlValue? get_value(string key);
    public bool has_key(string key);
    
    // 便捷方法
    public string? get_string(string key, string? default = null);
    public bool get_boolean(string key, bool default = false);
    public int64 get_integer(string key, int64 default = 0);
    public string[] get_string_list(string key);
    
    public void set_string(string key, string value);
    public void set_boolean(string key, bool value);
    public void set_integer(string key, int64 value);
    public void set_string_list(string key, string[] values);
    
    public string to_yaml_string();
    public string to_front_matter();
}
```

### 2. Markdown 类型定义 (markdown-types.vala)

#### NodeType 枚举

定义所有支持的 Markdown 元素类型：

```vala
public enum NodeType {
    DOCUMENT,           // 文档根节点
    HEADING,            // 标题 (H1-H6)
    PARAGRAPH,          // 段落
    BULLET_LIST,        // 无序列表
    ORDERED_LIST,       // 有序列表
    LIST_ITEM,          // 列表项
    CODE_BLOCK,         // 代码块
    BLOCK_QUOTE,        // 引用块
    THEMATIC_BREAK,     // 分隔线
    TEXT,               // 纯文本
    EMPHASIS,           // 强调/斜体
    STRONG,             // 加粗
    INLINE_CODE,        // 行内代码
    LINK,               // 链接
    IMAGE,              // 图片
    STRIKETHROUGH,      // 删除线 (GFM)
    // ...
}
```

### 3. Document 节点扩展

Document 类现在支持元数据：

```vala
public class Document : Node {
    // 元数据支持
    public Yaml.Metadata? metadata { get; set; }
    public bool has_metadata { get; }
    public Yaml.Metadata get_or_create_metadata();
    
    // 便捷方法
    public void set_metadata_string(string key, string value);
    public string? get_metadata_string(string key, string? default = null);
    
    // 自动检测标题（从元数据或第一个标题节点）
    public string? get_title();
}
```

## 完整示例

### 带元数据的文档

```vala
using Markdown;

void main() {
    try {
        string markdown = """---
title: 技术博客
author: 开发者
date: 2024-03-20
categories:
  - 技术
  - Vala
  - Markdown
---

# 技术博客

这是一篇技术文章...
""";

        // 解析
        var reader = new MarkdownReader();
        var doc = reader.parse(markdown);
        
        // 读取元数据
        if (doc.has_metadata) {
            var meta = doc.metadata;
            print("标题: %s\n", meta.get_string("title"));
            print("作者: %s\n", meta.get_string("author"));
            print("分类: %s\n", string.joinv(", ", meta.get_string_list("categories")));
        }
        
        // 修改元数据
        doc.set_metadata_string("status", "published");
        
        // 重新渲染
        var writer = new MarkdownWriter();
        print("\n渲染结果:\n%s\n", writer.render(doc));
        
    } catch (MarkdownError e) {
        stderr.printf("Error: %s\n", e.message);
    }
}
```

## 依赖

- GLib >= 2.50
- GObject >= 2.50
- GIO >= 2.50
- libgee >= 0.20

## 许可证

MIT License

## 作者
GLM 5 / Taozuhong

## 版本历史

- **1.1.0** - YAML 元数据支持
  - YAML Front Matter 解析和生成
  - 完整的 YAML 值类型系统
  - Metadata 类提供便捷访问
  - Document 元数据集成

- **1.0.0** - 初始版本
  - 完整的 CommonMark 解析支持
  - GFM 扩展支持（删除线、任务列表）
  - 节点树操作 API
  - 访问者模式支持
  - 节点工厂
  - 辅助工具（打印器、计数器）
