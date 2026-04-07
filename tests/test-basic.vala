/**
 * Basic unit tests for Markdown module
 */

using Gee;
using Markdown;

public class MarkdownTests : Object {

    public static int main(string[] args) {
        Test.init(ref args);

        Test.add_func("/parser/basic", test_parser_basic);
        Test.add_func("/parser/heading", test_parser_heading);
        Test.add_func("/parser/list", test_parser_list);
        Test.add_func("/parser/code_block", test_parser_code_block);
        Test.add_func("/parser/front_matter", test_parser_front_matter);
        Test.add_func("/writer/basic", test_writer_basic);
        Test.add_func("/html/basic", test_html_basic);
        Test.add_func("/gtk/basic", test_gtk_basic);

        return Test.run();
    }

    private static void test_parser_basic() {
        var parser = new Parser();
        var doc = parser.parse("Hello, World!");

        assert(doc != null);
        assert(doc.node_type == NodeType.DOCUMENT);
        assert(doc.children.size == 1);

        var para = doc.first_child();
        assert(para is Paragraph);
        assert(para.children.size == 1);

        var text = para.first_child() as Text;
        assert(text != null);
        assert(text.content == "Hello, World!");
    }

    private static void test_parser_heading() {
        var parser = new Parser();

        // Test various heading levels
        for (int i = 1; i <= 6; i++) {
            var heading_markdown = string.nfill(i, '#') + " Heading " + i.to_string();
            var doc = parser.parse(heading_markdown);

            var heading = doc.first_child() as Heading;
            assert(heading != null);
            assert(heading.level == i);

            var text = heading.first_child() as Text;
            assert(text != null);
            assert(text.content == "Heading " + i.to_string());
        }
    }

    private static void test_parser_list() {
        var parser = new Parser();

        // Test bullet list
        var doc = parser.parse("- Item 1\n- Item 2\n- Item 3");

        var list = doc.first_child() as Markdown.List;
        assert(list != null);
        assert(list.list_type == ListType.BULLET);
        assert(list.children.size == 3);

        // Test ordered list
        doc = parser.parse("1. First\n2. Second\n3. Third");

        list = doc.first_child() as Markdown.List;
        assert(list != null);
        assert(list.list_type == ListType.ORDERED);
        assert(list.start_number == 1);
        assert(list.children.size == 3);
    }

    private static void test_parser_code_block() {
        var parser = new Parser();

        // Test fenced code block
        var doc = parser.parse("```vala\nprint(\"Hello\");\n```");

        var code_block = doc.first_child() as CodeBlock;
        assert(code_block != null);
        assert(code_block.language == "vala");
        assert(code_block.is_fenced);

        var text = code_block.first_child() as Text;
        assert(text != null);
        assert(text.content.contains("Hello"));
    }

    private static void test_parser_front_matter() {
        var parser = new Parser();

        var doc = parser.parse("""---
title: Test Document
author: Test Author
---
# Content
""");

        assert(doc.front_matter.size == 2);
        assert(doc.front_matter["title"] == "Test Document");
        assert(doc.front_matter["author"] == "Test Author");
    }

    private static void test_writer_basic() {
        // Create document manually
        var doc = new Document();

        var heading = new Heading(1);
        heading.append_child(new Text("Test Heading"));
        doc.append_child(heading);

        var para = new Paragraph();
        para.append_child(new Text("Test paragraph with "));
        var strong = new Strong();
        strong.append_child(new Text("bold"));
        para.append_child(strong);
        para.append_child(new Text(" text."));
        doc.append_child(para);

        // Write to Markdown
        var writer = new Writer();
        var output = writer.write(doc);

        assert("# Test Heading" in output);
        assert("**bold**" in output);
    }

    private static void test_html_basic() {
        var parser = new Parser();
        var doc = parser.parse("# Hello\n\nThis is **bold**.");

        var renderer = new HtmlRenderer();
        var html = renderer.render(doc);

        assert("<h1>" in html);
        assert("Hello" in html);
        assert("<strong>" in html);
        assert("<strong>bold</strong>" in html);
    }

    private static void test_gtk_basic() {
        var parser = new Parser();
        var doc = parser.parse("# Hello\n\nWorld");

        var renderer = new PangoRenderer();
        var markup = renderer.render(doc);
        var css = renderer.generate_css();

        assert(markup.length > 0);
        assert(".heading-1" in css);
        assert(".strong" in css);
    }
}
