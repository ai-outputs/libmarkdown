/**
 * Markdown Writer Module
 *
 * Serializes Markdown document tree back to Markdown text format
 */

using Gee;

namespace Markdown {

    /**
     * Writer options for formatting output
     */
    public class WriteOptions : Object {
        public bool emit_front_matter { get; set; default = true; }
        public bool emit_gfm_extensions { get; set; default = true; }
        public int indent_size { get; set; default = 4; }
        public bool use_atx_headings { get; set; default = true; }
        public int list_bullet_style { get; set; default = 0; } // 0: -, 1: *, 2: +
        public bool use_reference_links { get; set; default = false; }
        public int line_width { get; set; default = 80; }

        public WriteOptions() {
            // Defaults are fine
        }
    }

    /**
     * Markdown Writer - converts document tree to Markdown text
     */
    public class Writer : Visitor {
        private StringBuilder output;
        private WriteOptions options;
        private int indent_level;
        private bool at_line_start;
        private Gee.List<LinkReference?> link_references;
        private int list_item_number;
        private ListType current_list_type;

        private struct LinkReference {
            string label;
            string url;
            string? title;
        }

        public Writer(WriteOptions? options = null) {
            this.options = options ?? new WriteOptions();
            this.output = new StringBuilder();
            this.indent_level = 0;
            this.at_line_start = true;
            this.link_references = new ArrayList<LinkReference?>();
            this.list_item_number = 1;
            this.current_list_type = ListType.BULLET;
        }

        /**
         * Write a Document to Markdown string
         */
        public string write(Document document) {
            output.truncate(0);
            indent_level = 0;
            at_line_start = true;
            link_references.clear();

            // Emit front matter if present
            if (options.emit_front_matter && document.front_matter.size > 0) {
                emit_front_matter(document);
            }

            // Visit all nodes
            document.accept(this);

            return output.str;
        }

        /**
         * Write any node to string
         */
        public string write_node(Node node) {
            output.truncate(0);
            indent_level = 0;
            at_line_start = true;

            node.accept(this);

            return output.str;
        }

        /**
         * Emit YAML front matter
         */
        private void emit_front_matter(Document document) {
            write_line("---");
            foreach (var entry in document.front_matter.entries) {
                var value = entry.value;
                // Quote values with special characters
                if (value.contains(":") || value.contains("#") || value.contains("\n")) {
                    value = "\"" + value.replace("\"", "\\\"") + "\"";
                }
                write_line("%s: %s".printf(entry.key, value));
            }
            write_line("---");
            write_newline();
        }

        // Visitor implementation

        public override void visit_document(Document node) {
            visit_children(node);

            // Emit link references if using reference-style links
            if (options.use_reference_links && link_references.size > 0) {
                write_newline();
                foreach (var link_ref in link_references) {
                    write_line("[%s]: %s".printf(link_ref.label, link_ref.url));
                }
            }
        }

        public override void visit_heading(Heading node) {
            write_indent();

            // ATX-style heading with # prefix
            for (int i = 0; i < node.level; i++) {
                write_char('#');
            }
            write_char(' ');

            visit_children(node);

            write_newline();
        }

        public override void visit_paragraph(Paragraph node) {
            write_indent();
            visit_children(node);
            write_newline();
            write_newline();
        }

        public override void visit_text(Text node) {
            write_text(node.content);
        }

        public override void visit_emphasis(Emphasis node) {
            write_char('*');
            visit_children(node);
            write_char('*');
        }

        public override void visit_strong(Strong node) {
            write_text("**");
            visit_children(node);
            write_text("**");
        }

        public override void visit_code(Code node) {
            write_char('`');
            write_text(node.content);
            write_char('`');
        }

        public override void visit_code_block(CodeBlock node) {
            write_indent();

            if (node.is_fenced) {
                write_text("```");
                if (node.language != null && node.language.length > 0) {
                    write_text(node.language);
                }
                write_newline();

                // Write content
                if (node.first_child() != null) {
                    var text = (Text)node.first_child();
                    write_text(text.content);
                }

                write_line("```");
            } else {
                // Indented code block
                if (node.first_child() != null) {
                    var text = (Text)node.first_child();
                    var lines = text.content.split("\n");
                    foreach (var line in lines) {
                        if (line.length > 0) {
                            write_indent();
                            write_text("    ");
                            write_line(line);
                        }
                    }
                }
            }
            write_newline();
        }

        public override void visit_link(Link node) {
            if (options.use_reference_links) {
                // Reference-style link
                write_char('[');
                visit_children(node);
                write_char(']');
                write_char('[');

                var label = get_node_text(node);
                write_text(label);

                write_char(']');

                // Add reference
                link_references.add(LinkReference() {
                    label = label,
                    url = node.url,
                    title = node.title
                });
            } else {
                // Inline link
                write_char('[');
                visit_children(node);
                write_char(']');
                write_char('(');
                write_text(node.url);

                if (node.title != null && node.title.length > 0) {
                    write_text(" \"");
                    write_text(node.title);
                    write_char('"');
                }
                write_char(')');
            }
        }

        public override void visit_image(Image node) {
            write_char('!');
            write_char('[');

            if (node.alt_text != null) {
                write_text(node.alt_text);
            } else {
                visit_children(node);
            }

            write_char(']');
            write_char('(');
            write_text(node.url);

            if (node.title != null && node.title.length > 0) {
                write_text(" \"");
                write_text(node.title);
                write_char('"');
            }
            write_char(')');
        }

        public override void visit_list(List node) {
            current_list_type = node.list_type;
            list_item_number = node.start_number;
            visit_children(node);
            write_newline();
        }

        public override void visit_list_item(ListItem node) {
            write_indent();

            if (current_list_type == ListType.ORDERED) {
                write_text("%d. ".printf(list_item_number));
                list_item_number++;
            } else {
                char[] bullets = { '-', '*', '+' };
                write_char(bullets[options.list_bullet_style]);
                write_char(' ');
            }

            visit_children(node);
            write_newline();
        }

        public override void visit_task_list_item(TaskListItem node) {
            write_indent();

            if (current_list_type == ListType.ORDERED) {
                write_text("%d. ".printf(list_item_number));
                list_item_number++;
            } else {
                char[] bullets = { '-', '*', '+' };
                write_char(bullets[options.list_bullet_style]);
            }

            write_char(' ');

            if (node.is_checked) {
                write_text("[x] ");
            } else {
                write_text("[ ] ");
            }

            visit_children(node);
            write_newline();
        }

        public override void visit_blockquote(Blockquote node) {
            write_indent();
            write_text("> ");

            // Collect text for blockquote
            var content = new StringBuilder();
            collect_text(node, content);

            // Write blockquote lines
            var lines = content.str.split("\n");
            foreach (var line in lines) {
                if (line.length > 0) {
                    write_line(line);
                }
            }

            write_newline();
        }

        public override void visit_thematic_break(ThematicBreak node) {
            write_indent();
            write_line("---");
            write_newline();
        }

        public override void visit_strikethrough(Strikethrough node) {
            if (options.emit_gfm_extensions) {
                write_text("~~");
                visit_children(node);
                write_text("~~");
            } else {
                visit_children(node);
            }
        }

        public override void visit_table(Table node) {
            if (!options.emit_gfm_extensions) {
                // Fall back to paragraphs
                visit_children(node);
                return;
            }

            var rows = node.children;

            if (rows.size == 0) return;

            // Write header row
            if (rows.size > 0 && ((TableRow)rows[0]).is_header) {
                var header_row = (TableRow)rows[0];
                write_char('|');
                foreach (var cell in header_row.children) {
                    visit_children(cell);
                    write_char('|');
                }
                write_newline();

                // Write separator
                write_char('|');
                foreach (var cell in header_row.children) {
                    var table_cell = (TableCell)cell;
                    var align = table_cell.alignment;

                    if (align == TableCell.Alignment.LEFT || align == TableCell.Alignment.DEFAULT) {
                        write_text(":---");
                    } else if (align == TableCell.Alignment.CENTER) {
                        write_text(":---:");
                    } else {
                        write_text("---:");
                    }
                    write_char('|');
                }
                write_newline();
            }

            // Write body rows
            for (int i = 1; i < rows.size; i++) {
                var row = (TableRow)rows[i];
                write_char('|');
                foreach (var cell in row.children) {
                    visit_children(cell);
                    write_char('|');
                }
                write_newline();
            }

            write_newline();
        }

        public override void visit_table_row(TableRow node) {
            // Handled by table visitor
        }

        public override void visit_table_cell(TableCell node) {
            // Handled by table visitor
        }

        public override void visit_line_break(LineBreak node) {
            write_text("  ");
            write_newline();
            write_indent();
        }

        public override void visit_soft_break(SoftBreak node) {
            write_newline();
            write_indent();
        }

        public override void visit_html_block(HtmlBlock node) {
            write_text(node.content);
            write_newline();
            write_newline();
        }

        public override void visit_html_inline(HtmlInline node) {
            write_text(node.content);
        }

        // Helper methods

        private void write_text(string text) {
            output.append(text);
            at_line_start = false;
        }

        private void write_char(char c) {
            output.append_c(c);
            at_line_start = false;
        }

        private void write_line(string text) {
            output.append(text);
            output.append_c('\n');
            at_line_start = true;
        }

        private void write_newline() {
            output.append_c('\n');
            at_line_start = true;
        }

        private void write_indent() {
            if (at_line_start) {
                for (int i = 0; i < indent_level; i++) {
                    for (int j = 0; j < options.indent_size; j++) {
                        output.append_c(' ');
                    }
                }
                at_line_start = false;
            }
        }

        private string get_node_text(Node node) {
            var sb = new StringBuilder();
            collect_text(node, sb);
            return sb.str;
        }

        private void collect_text(Node node, StringBuilder sb) {
            if (node is Text) {
                sb.append(((Text)node).content);
            } else {
                foreach (var child in node.children) {
                    collect_text(child, sb);
                }
            }
        }
    }
}
