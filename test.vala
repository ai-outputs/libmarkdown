/**
 * Markdown 模块单元测试
 * 
 * 本文件包含模块的完整单元测试。
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

using Markdown;

/**
 * 测试运行器
 */
public int main(string[] args) {
    GLib.Test.init(ref args);
    GLib.Test.set_nonfatal_assertions();
    
    // 注册测试套件
    GLib.Test.add_func("/markdown/types/node_type", test_node_type);
    GLib.Test.add_func("/markdown/types/heading_level", test_heading_level);
    GLib.Test.add_func("/markdown/types/source_position", test_source_position);
    GLib.Test.add_func("/markdown/nodes/basic", test_nodes_basic);
    GLib.Test.add_func("/markdown/nodes/tree", test_nodes_tree);
    GLib.Test.add_func("/markdown/nodes/clone", test_nodes_clone);
    GLib.Test.add_func("/markdown/reader/heading", test_reader_heading);
    GLib.Test.add_func("/markdown/reader/paragraph", test_reader_paragraph);
    GLib.Test.add_func("/markdown/reader/list", test_reader_list);
    GLib.Test.add_func("/markdown/reader/code_block", test_reader_code_block);
    GLib.Test.add_func("/markdown/reader/inline", test_reader_inline);
    GLib.Test.add_func("/markdown/writer/basic", test_writer_basic);
    GLib.Test.add_func("/markdown/writer/roundtrip", test_writer_roundtrip);
    GLib.Test.add_func("/markdown/factory/create", test_factory_create);
    
    return GLib.Test.run();
}

// ============================================================
// 类型测试
// ============================================================

private void test_node_type() {
    // 测试块级/行内判断
    assert_true(NodeType.DOCUMENT.is_block());
    assert_true(NodeType.HEADING.is_block());
    assert_true(NodeType.PARAGRAPH.is_block());
    assert_true(NodeType.CODE_BLOCK.is_block());
    
    assert_true(NodeType.TEXT.is_inline());
    assert_true(NodeType.EMPHASIS.is_inline());
    assert_true(NodeType.LINK.is_inline());
    
    // 测试可读名称
    assert_cmpstr(NodeType.HEADING.to_readable_string(), GLib.CompareOperator.EQ, "Heading");
    assert_cmpstr(NodeType.BULLET_LIST.to_readable_string(), GLib.CompareOperator.EQ, "BulletList");
    assert_cmpstr(NodeType.INLINE_CODE.to_readable_string(), GLib.CompareOperator.EQ, "InlineCode");
}

private void test_heading_level() {
    // 测试从整数创建
    try {
        var h1 = HeadingLevel.from_int(1);
        assert_cmpint((int)h1, GLib.CompareOperator.EQ, 1);
        
        var h6 = HeadingLevel.from_int(6);
        assert_cmpint((int)h6, GLib.CompareOperator.EQ, 6);
    } catch (MarkdownError e) {
        assert_not_reached();
    }
    
    // 测试无效级别
    try {
        HeadingLevel.from_int(0);
        assert_not_reached();
    } catch (MarkdownError e) {
        // 预期异常
    }
    
    try {
        HeadingLevel.from_int(7);
        assert_not_reached();
    } catch (MarkdownError e) {
        // 预期异常
    }
    
    // 测试前缀
    assert_cmpstr(HeadingLevel.H1.to_prefix(), GLib.CompareOperator.EQ, "#");
    assert_cmpstr(HeadingLevel.H2.to_prefix(), GLib.CompareOperator.EQ, "##");
    assert_cmpstr(HeadingLevel.H6.to_prefix(), GLib.CompareOperator.EQ, "######");
}

private void test_source_position() {
    // 测试无效位置
    var invalid = SourcePosition.invalid();
    assert_false(invalid.is_valid());
    
    // 测试单点位置
    var point = SourcePosition.point(10, 20);
    assert_true(point.is_valid());
    assert_cmpint(point.start_line, GLib.CompareOperator.EQ, 10);
    assert_cmpint(point.start_column, GLib.CompareOperator.EQ, 20);
    assert_cmpint(point.end_line, GLib.CompareOperator.EQ, 10);
    assert_cmpint(point.end_column, GLib.CompareOperator.EQ, 20);
    
    // 测试范围位置
    var range = SourcePosition.range(1, 1, 5, 10);
    assert_true(range.is_valid());
    assert_cmpint(range.start_line, GLib.CompareOperator.EQ, 1);
    assert_cmpint(range.end_line, GLib.CompareOperator.EQ, 5);
    
    // 测试字符串表示
    assert_cmpstr(point.to_string(), GLib.CompareOperator.EQ, "10:20");
    assert_cmpstr(range.to_string(), GLib.CompareOperator.EQ, "1:1-5:10");
}

// ============================================================
// 节点测试
// ============================================================

private void test_nodes_basic() {
    // 测试文本节点
    var text = new Text("Hello, World!");
    assert_cmpint(text.node_type, GLib.CompareOperator.EQ, NodeType.TEXT);
    assert_cmpstr(text.text, GLib.CompareOperator.EQ, "Hello, World!");
    assert_cmpstr(text.get_text_content(), GLib.CompareOperator.EQ, "Hello, World!");
    
    // 测试标题节点
    var heading = new Heading(HeadingLevel.H2);
    assert_cmpint(heading.node_type, GLib.CompareOperator.EQ, NodeType.HEADING);
    assert_cmpint((int)heading.level, GLib.CompareOperator.EQ, 2);
    
    // 测试代码块节点
    var code = new CodeBlock();
    code.code = "print('hello')";
    code.language = "python";
    assert_cmpint(code.node_type, GLib.CompareOperator.EQ, NodeType.CODE_BLOCK);
    assert_cmpstr(code.language, GLib.CompareOperator.EQ, "python");
}

private void test_nodes_tree() {
    // 创建简单的文档树
    var doc = new Document();
    
    var heading = new Heading(HeadingLevel.H1);
    var text = new Text("Title");
    
    try {
        heading.append_child(text);
        doc.append_child(heading);
        
        // 测试父子关系
        assert(text.parent == heading);
        assert(heading.parent == doc);
        
        // 测试子节点数量
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 1);
        assert_cmpint(heading.child_count, GLib.CompareOperator.EQ, 1);
        
        // 测试 first_child
        assert(doc.first_child == heading);
        assert(heading.first_child == text);
        
        // 测试遍历
        int count = 0;
        doc.traverse((node, depth) => {
            count++;
            return true;
        });
        assert_cmpint(count, GLib.CompareOperator.EQ, 3);
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

private void test_nodes_clone() {
    // 创建并克隆文本节点
    var text = new Text("Original");
    text.source_position = SourcePosition.point(1, 1);
    
    var text_clone = text.clone() as Text;
    assert_cmpstr(text_clone.text, GLib.CompareOperator.EQ, "Original");
    assert(text_clone.source_position.is_valid());
    
    // 创建并克隆标题节点
    var heading = new Heading(HeadingLevel.H2);
    try {
        heading.append_child(new Text("Heading Text"));
    } catch (MarkdownError e) {
        assert_not_reached();
    }
    
    var heading_clone = heading.clone() as Heading;
    assert_cmpint((int)heading_clone.level, GLib.CompareOperator.EQ, 2);
    assert_cmpint(heading_clone.child_count, GLib.CompareOperator.EQ, 1);
}

// ============================================================
// 解析器测试
// ============================================================

private void test_reader_heading() {
    var reader = new MarkdownReader();
    
    try {
        // ATX 标题
        var doc = reader.parse("# Heading 1");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 1);
        
        var heading = doc.first_child as Heading;
        assert(heading != null);
        assert_cmpint((int)heading.level, GLib.CompareOperator.EQ, 1);
        assert_cmpstr(heading.get_text_content(), GLib.CompareOperator.EQ, "Heading 1");
        
        // 多级标题
        doc = reader.parse("## Heading 2\n### Heading 3");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 2);
        
        var h2 = doc.first_child as Heading;
        var h3 = doc.last_child as Heading;
        assert_cmpint((int)h2.level, GLib.CompareOperator.EQ, 2);
        assert_cmpint((int)h3.level, GLib.CompareOperator.EQ, 3);
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

private void test_reader_paragraph() {
    var reader = new MarkdownReader();
    
    try {
        var doc = reader.parse("This is a paragraph.");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 1);
        
        var para = doc.first_child as Paragraph;
        assert(para != null);
        assert_cmpstr(para.get_text_content(), GLib.CompareOperator.EQ, "This is a paragraph.");
        
        // 多段落
        doc = reader.parse("First paragraph.\n\nSecond paragraph.");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 2);
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

private void test_reader_list() {
    var reader = new MarkdownReader();
    
    try {
        // 无序列表
        var doc = reader.parse("- Item 1\n- Item 2\n- Item 3");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 1);
        
        var list = doc.first_child as BulletList;
        assert(list != null);
        assert_cmpint(list.child_count, GLib.CompareOperator.EQ, 3);
        
        // 有序列表
        doc = reader.parse("1. First\n2. Second\n3. Third");
        
        var olist = doc.first_child as OrderedList;
        assert(olist != null);
        assert_cmpint(olist.start_number, GLib.CompareOperator.EQ, 1);
        assert_cmpint(olist.child_count, GLib.CompareOperator.EQ, 3);
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

private void test_reader_code_block() {
    var reader = new MarkdownReader();
    
    try {
        var doc = reader.parse("```\ncode here\n```");
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, 1);
        
        var code = doc.first_child as CodeBlock;
        assert(code != null);
        assert(code.is_fenced);
        assert_cmpstr(code.code.strip(), GLib.CompareOperator.EQ, "code here");
        
        // 带语言的代码块
        doc = reader.parse("```python\nprint('hello')\n```");
        code = doc.first_child as CodeBlock;
        assert_cmpstr(code.language, GLib.CompareOperator.EQ, "python");
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

private void test_reader_inline() {
    var reader = new MarkdownReader();
    
    try {
        // 强调和加粗
        var doc = reader.parse("**bold** and *italic*");
        var para = doc.first_child as Paragraph;
        assert(para != null);
        assert_cmpint(para.child_count, GLib.CompareOperator.EQ, 4); // strong, text, emphasis
        
        // 行内代码
        doc = reader.parse("Use `code` here");
        para = doc.first_child as Paragraph;
        bool has_inline_code = false;
        foreach (var child in para.children) {
            if (child.node_type == NodeType.INLINE_CODE) {
                has_inline_code = true;
                assert_cmpstr(((InlineCode)child).code, GLib.CompareOperator.EQ, "code");
            }
        }
        assert(has_inline_code);
        
        // 链接
        doc = reader.parse("[Link](https://example.com)");
        para = doc.first_child as Paragraph;
        var link = para.first_child as Link;
        assert(link != null);
        assert_cmpstr(link.destination, GLib.CompareOperator.EQ, "https://example.com");
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

// ============================================================
// 生成器测试
// ============================================================

private void test_writer_basic() {
    var writer = new MarkdownWriter();
    
    // 创建文档
    var doc = new Document();
    try {
        var heading = new Heading(HeadingLevel.H1);
        heading.append_child(new Text("Title"));
        doc.append_child(heading);
        
        var para = new Paragraph();
        para.append_child(new Text("Content"));
        doc.append_child(para);
    } catch (MarkdownError e) {
        assert_not_reached();
    }
    
    string output = writer.render(doc);
    assert_cmpstr(output, GLib.CompareOperator.EQ, "# Title\n\nContent");
}

private void test_writer_roundtrip() {
    var reader = new MarkdownReader();
    var writer = new MarkdownWriter();
    
    try {
        // 简单的往返测试
        string original = "# Title\n\nParagraph";
        var doc = reader.parse(original);
        string output = writer.render(doc);
        
        // 再次解析输出
        var doc2 = reader.parse(output);
        
        // 比较结构
        assert_cmpint(doc.child_count, GLib.CompareOperator.EQ, doc2.child_count);
        
        var h1 = doc.first_child as Heading;
        var h2 = doc2.first_child as Heading;
        assert_cmpint((int)h1.level, GLib.CompareOperator.EQ, (int)h2.level);
        
    } catch (MarkdownError e) {
        assert_not_reached();
    }
}

// ============================================================
// 工厂测试
// ============================================================

private void test_factory_create() {
    // 测试各种工厂方法
    var heading = NodeFactory.heading(HeadingLevel.H1, "Title");
    assert_cmpint(heading.node_type, GLib.CompareOperator.EQ, NodeType.HEADING);
    assert_cmpint((int)heading.level, GLib.CompareOperator.EQ, 1);
    assert_cmpstr(heading.get_text_content(), GLib.CompareOperator.EQ, "Title");
    
    var para = NodeFactory.paragraph("Content");
    assert_cmpint(para.node_type, GLib.CompareOperator.EQ, NodeType.PARAGRAPH);
    
    var link = NodeFactory.link("Text", "https://example.com");
    assert_cmpint(link.node_type, GLib.CompareOperator.EQ, NodeType.LINK);
    assert_cmpstr(link.destination, GLib.CompareOperator.EQ, "https://example.com");
    
    var image = NodeFactory.image("Alt", "image.png");
    assert_cmpint(image.node_type, GLib.CompareOperator.EQ, NodeType.IMAGE);
    
    var strong = NodeFactory.strong("Bold");
    assert_cmpint(strong.node_type, GLib.CompareOperator.EQ, NodeType.STRONG);
    
    var emphasis = NodeFactory.emphasis("Italic");
    assert_cmpint(emphasis.node_type, GLib.CompareOperator.EQ, NodeType.EMPHASIS);
    
    var list = NodeFactory.bullet_list({"A", "B", "C"});
    assert_cmpint(list.node_type, GLib.CompareOperator.EQ, NodeType.BULLET_LIST);
    assert_cmpint(list.child_count, GLib.CompareOperator.EQ, 3);
    
    var olist = NodeFactory.ordered_list({"1", "2"}, 1);
    assert_cmpint(olist.node_type, GLib.CompareOperator.EQ, NodeType.ORDERED_LIST);
    assert_cmpint(olist.start_number, GLib.CompareOperator.EQ, 1);
}
