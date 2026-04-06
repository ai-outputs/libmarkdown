/**
 * Markdown 模块使用示例
 * 
 * 本文件展示了如何使用 Vala Markdown 模块进行读写操作。
 * 
 * 编译方法：
 * valac --pkg gee-0.8 --pkg glib-2.0 --pkg gio-2.0 \
 *       markdown-types.vala markdown-nodes.vala \
 *       markdown-reader.vala markdown-writer.vala \
 *       markdown.vala example.vala -o markdown-example
 * 
 * 运行方法：
 * ./markdown-example
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

using Markdown;

/**
 * 示例程序主入口
 */
public int main(string[] args) {
    // 初始化模块
    markdown_init();
    
    print("=== Vala Markdown 模块示例 ===\n\n");
    
    try {
        // 示例 1：基础解析和渲染
        example_basic_parse();
        
        // 示例 2：程序化创建文档
        example_create_document();
        
        // 示例 3：节点遍历和操作
        example_traverse_nodes();
        
        // 示例 4：使用节点工厂
        example_node_factory();
        
        // 示例 5：完整文档解析
        example_complex_document();
        
    } catch (MarkdownError e) {
        stderr.printf("错误: %s\n", e.message);
        return 1;
    }
    
    print("\n=== 示例执行完成 ===\n");
    return 0;
}

/**
 * 示例 1：基础解析和渲染
 */
private void example_basic_parse() throws MarkdownError {
    print("【示例 1】基础解析和渲染\n");
    print("---------------------------\n");
    
    string markdown_text = """# 示例标题

这是一个简单的段落，包含 **加粗** 和 *斜体* 文本。

## 二级标题

- 列表项 1
- 列表项 2
- 列表项 3

```vala
// 代码块示例
print("Hello, World!");
```
""";

    // 解析 Markdown
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    print("解析成功！文档包含 %d 个顶层节点\n", doc.child_count);
    
    // 重新渲染
    var writer = new MarkdownWriter();
    string output = writer.render(doc);
    
    print("渲染输出：\n%s\n", output);
}

/**
 * 示例 2：程序化创建文档
 */
private void example_create_document() throws MarkdownError {
    print("\n【示例 2】程序化创建文档\n");
    print("---------------------------\n");
    
    // 创建文档
    var doc = new Document();
    
    // 添加标题
    var heading = new Heading(HeadingLevel.H1);
    heading.append_child(new Text("程序化创建的文档"));
    doc.append_child(heading);
    
    // 添加段落
    var para = new Paragraph();
    para.append_child(new Text("这是一个通过 API 创建的段落，包含 "));
    
    var strong = new Strong();
    strong.append_child(new Text("加粗文本"));
    para.append_child(strong);
    
    para.append_child(new Text(" 和 "));
    
    var emphasis = new Emphasis();
    emphasis.append_child(new Text("斜体文本"));
    para.append_child(emphasis);
    
    para.append_child(new Text("。"));
    doc.append_child(para);
    
    // 添加无序列表
    var list = new BulletList();
    list.bullet_char = '-';
    
    var item1 = new ListItem();
    item1.append_child(new Text("第一项"));
    list.append_child(item1);
    
    var item2 = new ListItem();
    item2.append_child(new Text("第二项"));
    list.append_child(item2);
    
    doc.append_child(list);
    
    // 渲染输出
    var writer = new MarkdownWriter();
    string output = writer.render(doc);
    
    print("创建的文档：\n%s\n", output);
}

/**
 * 示例 3：节点遍历和操作
 */
private void example_traverse_nodes() throws MarkdownError {
    print("\n【示例 3】节点遍历和操作\n");
    print("---------------------------\n");
    
    string markdown_text = "# 标题\n\n段落 **加粗** 文本。\n\n- 列表项";
    
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    // 使用 NodePrinter 打印节点树
    var printer = new NodePrinter();
    printer.show_positions = false;
    string tree = printer.print(doc);
    
    print("节点树结构：\n%s\n", tree);
    
    // 使用 NodeCounter 统计节点
    var counter = new NodeCounter();
    counter.count(doc);
    print("节点统计：\n%s", counter.get_summary());
}

/**
 * 示例 4：使用节点工厂
 */
private void example_node_factory() throws MarkdownError {
    print("\n【示例 4】使用节点工厂\n");
    print("---------------------------\n");
    
    // 使用工厂方法快速创建节点
    var heading = NodeFactory.heading(HeadingLevel.H2, "工厂创建的标题");
    
    var para = NodeFactory.paragraph("这是一个段落。");
    
    var link = NodeFactory.link("链接文本", "https://example.com", "链接标题");
    
    var image = NodeFactory.image("图片描述", "https://example.com/image.png");
    
    var strong = NodeFactory.strong("加粗文本");
    
    var emphasis = NodeFactory.emphasis("斜体文本");
    
    var list = NodeFactory.bullet_list({"项目一", "项目二", "项目三"});
    
    var ordered = NodeFactory.ordered_list({"步骤一", "步骤二", "步骤三"}, 1);
    
    // 创建文档并添加节点
    var doc = new Document();
    doc.append_child(heading);
    doc.append_child(para);
    
    // 添加包含链接的段落
    var link_para = new Paragraph();
    link_para.append_child(new Text("这是一个 "));
    link_para.append_child(link);
    link_para.append_child(new Text("。"));
    doc.append_child(link_para);
    
    // 添加图片
    var img_para = new Paragraph();
    img_para.append_child(image);
    doc.append_child(img_para);
    
    // 添加格式化文本段落
    var format_para = new Paragraph();
    format_para.append_child(strong);
    format_para.append_child(new Text(" 和 "));
    format_para.append_child(emphasis);
    doc.append_child(format_para);
    
    // 添加列表
    doc.append_child(list);
    doc.append_child(ordered);
    
    // 渲染
    var writer = new MarkdownWriter();
    string output = writer.render(doc);
    
    print("工厂创建的文档：\n%s\n", output);
}

/**
 * 示例 5：完整复杂文档解析
 */
private void example_complex_document() throws MarkdownError {
    print("\n【示例 5】复杂文档解析\n");
    print("---------------------------\n");
    
    string markdown_text = """# API 文档

## 概述

这是一个完整的 API 文档示例，展示了 Markdown 的各种特性。

## 功能列表

1. **解析功能**
   - 支持 CommonMark 规范
   - 支持 GFM 扩展
   - 支持自定义解析选项

2. **生成功能**
   - 可自定义输出格式
   - 支持缩进配置
   - 支持换行符配置

## 代码示例

```vala
// 创建解析器
var reader = new MarkdownReader();
var doc = reader.parse(markdown_text);

// 渲染输出
var writer = new MarkdownWriter();
string output = writer.render(doc);
```

## 链接和引用

- 官方网站：[Vala 语言](https://vala.dev "Vala 官网")
- 文档参考：[GLib 文档](https://docs.gtk.org/glib/)

---

*最后更新：2024年*
""";

    // 解析
    var reader = new MarkdownReader();
    var doc = reader.parse(markdown_text);
    
    print("解析成功！\n");
    
    // 统计
    var counter = new NodeCounter();
    counter.count(doc);
    
    print("文档包含：\n");
    print("  - 标题：%d 个\n", counter.get_count(NodeType.HEADING));
    print("  - 段落：%d 个\n", counter.get_count(NodeType.PARAGRAPH));
    print("  - 列表：%d 个\n", 
          counter.get_count(NodeType.BULLET_LIST) + 
          counter.get_count(NodeType.ORDERED_LIST));
    print("  - 代码块：%d 个\n", counter.get_count(NodeType.CODE_BLOCK));
    print("  - 链接：%d 个\n", counter.get_count(NodeType.LINK));
    
    // 打印节点树（前几层）
    print("\n节点树预览：\n");
    var printer = new NodePrinter();
    printer.show_text_content = false;
    print("%s", printer.print(doc));
}
