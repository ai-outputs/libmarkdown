/**
 * HTML Renderer Module
 *
 * Renders Markdown document tree to HTML format
 */

using Gee;

namespace Markdown {

    /**
     * HTML rendering options
     */
    public class HtmlOptions : Object {
        public bool emit_doctype { get; set; default = false; }
        public bool emit_html_wrapper { get; set; default = false; }
        public bool safe_links { get; set; default = true; }
        public bool escape_html { get; set; default = true; }
        public bool soft_break_as_br { get; set; default = false; }
        public bool source_pos { get; set; default = false; }
        public string? css_class { get; set; default = null; }

        public HtmlOptions() {
            // Defaults are fine
        }
    }

    /**
     * HTML Renderer - converts Markdown to HTML
     */
    public class HtmlRenderer : Visitor {
        private StringBuilder output;
        private HtmlOptions options;
        private int list_item_number;
        private ListType current_list_type;
        private bool in_tight_list;

        public HtmlRenderer(HtmlOptions? options = null) {
            this.options = options ?? new HtmlOptions();
            this.output = new StringBuilder();
            this.list_item_number = 1;
            this.current_list_type = ListType.BULLET;
            this.in_tight_list = false;
        }

        /**
         * Render a Document to HTML string
         */
        public string render(Document document) {
            output.truncate(0);

            if (options.emit_doctype) {
                output.append("<!DOCTYPE html>\n");
            }

            if (options.emit_html_wrapper) {
                output.append("<html>\n<head>\n");
                output.append("<meta charset=\"utf-8\">\n");
                output.append("</head>\n<body>\n");
            }

            if (options.css_class != null) {
                output.append("<div class=\"%s\">\n".printf(options.css_class));
            }

            document.accept(this);

            if (options.css_class != null) {
                output.append("</div>\n");
            }

            if (options.emit_html_wrapper) {
                output.append("</body>\n</html>\n");
            }

            return output.str;
        }

        /**
         * Render any node to HTML string
         */
        public string render_node(Node node) {
            output.truncate(0);
            node.accept(this);
            return output.str;
        }

        // Visitor implementation

        public override void visit_document(Document node) {
            visit_children(node);
        }

        public override void visit_heading(Heading node) {
            var tag = "h%d".printf(node.level);

            output.append("<%s".printf(tag));
            emit_source_pos(node);
            output.append(">");

            visit_children(node);

            output.append("</%s>\n".printf(tag));
        }

        public override void visit_paragraph(Paragraph node) {
            if (!in_tight_list) {
                output.append("<p");
                emit_source_pos(node);
                output.append(">");
            }

            visit_children(node);

            if (!in_tight_list) {
                output.append("</p>\n");
            } else {
                output.append("\n");
            }
        }

        public override void visit_text(Text node) {
            output.append(escape_html(node.content));
        }

        public override void visit_emphasis(Emphasis node) {
            output.append("<em>");
            visit_children(node);
            output.append("</em>");
        }

        public override void visit_strong(Strong node) {
            output.append("<strong>");
            visit_children(node);
            output.append("</strong>");
        }

        public override void visit_code(Code node) {
            output.append("<code>");
            output.append(escape_html(node.content));
            output.append("</code>");
        }

        public override void visit_code_block(CodeBlock node) {
            output.append("<pre");

            if (node.language != null && node.language.length > 0) {
                output.append(" class=\"language-%s\"".printf(escape_html(node.language)));
            }

            emit_source_pos(node);
            output.append("><code>");

            if (node.first_child() != null) {
                var text = (Text)node.first_child();
                output.append(escape_html(text.content));
            }

            output.append("</code></pre>\n");
        }

        public override void visit_link(Link node) {
            output.append("<a href=\"%s\"".printf(escape_html(safe_url(node.url))));

            if (node.title != null && node.title.length > 0) {
                output.append(" title=\"%s\"".printf(escape_html(node.title)));
            }

            emit_source_pos(node);
            output.append(">");

            visit_children(node);

            output.append("</a>");
        }

        public override void visit_image(Image node) {
            output.append("<img src=\"%s\"".printf(escape_html(safe_url(node.url))));

            if (node.alt_text != null) {
                output.append(" alt=\"%s\"".printf(escape_html(node.alt_text)));
            } else {
                var alt = get_node_text(node);
                output.append(" alt=\"%s\"".printf(escape_html(alt)));
            }

            if (node.title != null && node.title.length > 0) {
                output.append(" title=\"%s\"".printf(escape_html(node.title)));
            }

            emit_source_pos(node);
            output.append(" />");
        }

        public override void visit_list(List node) {
            current_list_type = node.list_type;
            in_tight_list = node.tight;
            list_item_number = node.start_number;

            if (node.list_type == ListType.ORDERED || node.list_type == ListType.TASK) {
                output.append("<ol");
                if (node.start_number != 1) {
                    output.append(" start=\"%d\"".printf(node.start_number));
                }
            } else {
                output.append("<ul");
            }

            emit_source_pos(node);
            output.append(">\n");

            visit_children(node);

            if (node.list_type == ListType.ORDERED || node.list_type == ListType.TASK) {
                output.append("</ol>\n");
            } else {
                output.append("</ul>\n");
            }

            in_tight_list = false;
        }

        public override void visit_list_item(ListItem node) {
            output.append("<li");

            emit_source_pos(node);
            output.append(">");

            visit_children(node);

            output.append("</li>\n");
        }

        public override void visit_task_list_item(TaskListItem node) {
            output.append("<li");

            emit_source_pos(node);

            if (node.is_checked) {
                output.append(" class=\"task-list-item checked\"");
            } else {
                output.append(" class=\"task-list-item\"");
            }

            output.append(">");

            output.append("<input type=\"checkbox\" disabled");
            if (node.is_checked) {
                output.append(" checked");
            }
            output.append("> ");

            visit_children(node);

            output.append("</li>\n");
        }

        public override void visit_blockquote(Blockquote node) {
            output.append("<blockquote");
            emit_source_pos(node);
            output.append(">\n");

            visit_children(node);

            output.append("</blockquote>\n");
        }

        public override void visit_thematic_break(ThematicBreak node) {
            output.append("<hr");
            emit_source_pos(node);
            output.append(" />\n");
        }

        public override void visit_strikethrough(Strikethrough node) {
            output.append("<del>");
            visit_children(node);
            output.append("</del>");
        }

        public override void visit_table(Table node) {
            output.append("<table");
            emit_source_pos(node);
            output.append(">\n");

            bool has_header = false;
            foreach (var child in node.children) {
                if (child is TableRow) {
                    var row = (TableRow)child;
                    if (row.is_header) {
                        has_header = true;
                        output.append("<thead>\n");
                        row.accept(this);
                        output.append("</thead>\n");
                        break;
                    }
                }
            }

            output.append("<tbody>\n");

            bool in_body = false;
            foreach (var child in node.children) {
                if (child is TableRow) {
                    var row = (TableRow)child;
                    if (!row.is_header) {
                        in_body = true;
                        row.accept(this);
                    }
                }
            }

            output.append("</tbody>\n");
            output.append("</table>\n");
        }

        public override void visit_table_row(TableRow node) {
            output.append("<tr>\n");
            visit_children(node);
            output.append("</tr>\n");
        }

        public override void visit_table_cell(TableCell node) {
            string tag = (node.parent as TableRow)?.is_header ? "th" : "td";

            output.append("<%s".printf(tag));

            if (node.alignment != TableCell.Alignment.DEFAULT) {
                string align;
                switch (node.alignment) {
                    case TableCell.Alignment.LEFT:
                        align = "left";
                        break;
                    case TableCell.Alignment.CENTER:
                        align = "center";
                        break;
                    case TableCell.Alignment.RIGHT:
                        align = "right";
                        break;
                    default:
                        align = null;
                        break;
                }
                if (align != null) {
                    output.append(" style=\"text-align: %s\"".printf(align));
                }
            }

            emit_source_pos(node);
            output.append(">");

            visit_children(node);

            output.append("</%s>".printf(tag));
        }

        public override void visit_line_break(LineBreak node) {
            output.append("<br />\n");
        }

        public override void visit_soft_break(SoftBreak node) {
            if (options.soft_break_as_br) {
                output.append("<br />\n");
            } else {
                output.append("\n");
            }
        }

        public override void visit_html_block(HtmlBlock node) {
            if (options.escape_html) {
                output.append(escape_html(node.content));
            } else {
                output.append(node.content);
            }
            output.append("\n");
        }

        public override void visit_html_inline(HtmlInline node) {
            if (options.escape_html) {
                output.append(escape_html(node.content));
            } else {
                output.append(node.content);
            }
        }

        // Helper methods

        private void emit_source_pos(Node node) {
            if (options.source_pos && node.position != null) {
                output.append(" data-sourcepos=\"%d:%d-%d:%d\"".printf(
                    node.position.start_line,
                    node.position.start_column,
                    node.position.end_line,
                    node.position.end_column
                ));
            }
        }

        private string escape_html(string text) {
            if (!options.escape_html) {
                return text;
            }

            unichar uc;
            var sb = new StringBuilder();
            int char_count = text.char_count ();
            for(int i = 0; i < char_count; i++) {
                uc = text.get_char(i);
                switch (uc) {
                    case '&':
                        sb.append("&amp;");
                        break;
                    case '<':
                        sb.append("&lt;");
                        break;
                    case '>':
                        sb.append("&gt;");
                        break;
                    case '"':
                        sb.append("&quot;");
                        break;
                    case '\'':
                        sb.append("&#39;");
                        break;
                    default:
                        sb.append(uc.to_string());
                        break;
                }
            }
            return sb.str;
        }

        private string safe_url(string url) {
            if (!options.safe_links) {
                return url;
            }

            // Block dangerous protocols
            var lower = url.down();
            if (lower.has_prefix("javascript:") ||
                lower.has_prefix("vbscript:") ||
                lower.has_prefix("data:")) {
                return "";
            }

            return url;
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
