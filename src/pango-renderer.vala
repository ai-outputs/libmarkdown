/**
 * GTK CSS Renderer Module
 *
 * Renders Markdown to GTK-compatible CSS styled format for preview widgets
 */

using Gee;

namespace Markdown {

    /**
     * GTK CSS rendering options
     */
    public class PangoOptions : Object {
        public string font_family { get; set; default = "sans-serif"; }
        public int base_font_size { get; set; default = 11; }
        public bool use_dark_theme { get; set; default = false; }
        public bool show_invisible_chars { get; set; default = false; }
        public int max_line_width { get; set; default = 80; }
        public string? custom_css { get; set; default = null; }

        public PangoOptions() {
            // Defaults are fine
        }
    }

    /**
     * GTK CSS Renderer - converts Markdown to GTK-styled output
     *
     * This renderer produces:
     * 1. Pango markup for GTK labels/widgets
     * 2. CSS styles for GTK text views
     */
    public class PangoRenderer : Visitor {
        private StringBuilder markup;
        private PangoOptions options;
        private int heading_level;
        private bool in_paragraph;
        private int list_depth;
        private Gee.List<StyleRange?> styles;

        private struct StyleRange {
            int start;
            int end;
            string style;
        }

        public PangoRenderer(PangoOptions? options = null) {
            this.options = options ?? new PangoOptions();
            this.markup = new StringBuilder();
            this.heading_level = 0;
            this.in_paragraph = false;
            this.list_depth = 0;
            this.styles = new ArrayList<StyleRange?>();
        }

        /**
         * Render a Document to Pango markup
         */
        public string render(Document document) {
            markup.truncate(0);
            heading_level = 0;
            in_paragraph = false;
            list_depth = 0;
            styles.clear();

            document.accept(this);

            return markup.str;
        }

        /**
         * Generate CSS for GTK text view
         */
        public string generate_css() {
            var css = new StringBuilder();

            css.append("""
/* Markdown GTK CSS */
.textview.markdown {
    font-family: %s;
    font-size: %dpx;
}

""".printf(options.font_family, options.base_font_size));

            // Dark theme adjustments
            if (options.use_dark_theme) {
                css.append("""
/* Dark theme */
.textview.markdown {
    color: #e0e0e0;
    background-color: #1e1e1e;
}
""");
            }

            // Heading styles
            double[] heading_sizes = { 2.0, 1.75, 1.5, 1.25, 1.1, 1.0 };
            for (int i = 0; i < 6; i++) {
                int size = (int)(options.base_font_size * heading_sizes[i]);
                css.append(".heading-%d { font-size: %dpx; font-weight: bold; }\n".printf(i + 1, size));
            }

            // Emphasis styles
            css.append(".emphasis { font-style: italic; }\n");
            css.append(".strong { font-weight: bold; }\n");

            // Code styles
            css.append(".code, .code-block {\n");
            css.append("    font-family: monospace;\n");
            if (options.use_dark_theme) {
                css.append("    background-color: #2d2d2d;\n");
            } else {
                css.append("    background-color: #f5f5f5;\n");
            }
            css.append("}\n");

            // Blockquote styles
            css.append(".blockquote {\n");
            css.append("    border-left: 3px solid ");
            css.append(options.use_dark_theme ? "#555" : "#ddd");
            css.append(";\n");
            css.append("    padding-left: 10px;\n");
            css.append("    margin-left: 5px;\n");
            if (options.use_dark_theme) {
                css.append("    color: #aaa;\n");
            } else {
                css.append("    color: #666;\n");
            }
            css.append("}\n");

            // List styles
            css.append(".list { margin-left: 20px; }\n");
            css.append(".list-item { margin-left: 5px; }\n");

            // Table styles
            css.append(".table { border-collapse: collapse; }\n");
            css.append(".table-cell { padding: 5px; border: 1px solid ");
            css.append(options.use_dark_theme ? "#444" : "#ccc");
            css.append("; }\n");
            css.append(".table-header { font-weight: bold; }\n");

            // Task list styles
            css.append(".task-list-item { margin-left: 5px; }\n");

            // Link styles
            if (options.use_dark_theme) {
                css.append("a { color: #64b5f6; }\n");
            } else {
                css.append("a { color: #1976d2; }\n");
            }

            // Strikethrough
            css.append(".strikethrough { text-decoration: line-through; }\n");

            // Horizontal rule
            css.append(".thematic-break {\n");
            css.append("    border: none;\n");
            css.append("    border-top: 1px solid ");
            css.append(options.use_dark_theme ? "#444" : "#ccc");
            css.append(";\n");
            css.append("    margin: 10px 0;\n");
            css.append("}\n");

            // Custom CSS
            if (options.custom_css != null) {
                css.append("\n/* Custom CSS */\n");
                css.append(options.custom_css);
                css.append("\n");
            }

            return css.str;
        }

        // Visitor implementation

        public override void visit_document(Document node) {
            visit_children(node);
        }

        public override void visit_heading(Heading node) {
            heading_level = node.level;
            markup.append("<span class=\"heading-%d\">".printf(node.level));
            visit_children(node);
            markup.append("</span>\n\n");
            heading_level = 0;
        }

        public override void visit_paragraph(Paragraph node) {
            in_paragraph = true;
            markup.append("<span class=\"paragraph\">");
            visit_children(node);
            markup.append("</span>\n\n");
            in_paragraph = false;
        }

        public override void visit_text(Text node) {
            markup.append(escape_markup(node.content));
        }

        public override void visit_emphasis(Emphasis node) {
            markup.append("<i>");
            visit_children(node);
            markup.append("</i>");
        }

        public override void visit_strong(Strong node) {
            markup.append("<b>");
            visit_children(node);
            markup.append("</b>");
        }

        public override void visit_code(Code node) {
            markup.append("<span class=\"code\">");
            markup.append(escape_markup(node.content));
            markup.append("</span>");
        }

        public override void visit_code_block(CodeBlock node) {
            markup.append("<span class=\"code-block\">");

            if (node.language != null && node.language.length > 0) {
                markup.append("<span class=\"language-%s\">".printf(escape_markup(node.language)));
            }

            if (node.first_child() != null) {
                var text = (Text)node.first_child();
                markup.append(escape_markup(text.content));
            }

            if (node.language != null && node.language.length > 0) {
                markup.append("</span>");
            }

            markup.append("</span>\n\n");
        }

        public override void visit_link(Link node) {
            markup.append("<a href=\"%s\">".printf(escape_markup(node.url)));
            visit_children(node);
            markup.append("</a>");
        }

        public override void visit_image(Image node) {
            markup.append("<span class=\"image\"");
            if (node.alt_text != null) {
                markup.append(" alt=\"%s\"".printf(escape_markup(node.alt_text)));
            }
            markup.append(">[Image: ");
            if (node.alt_text != null) {
                markup.append(escape_markup(node.alt_text));
            } else {
                visit_children(node);
            }
            markup.append("]</span>");
        }

        public override void visit_list(List node) {
            list_depth++;
            string list_class = node.list_type == ListType.ORDERED ? "ordered-list" : "unordered-list";
            markup.append("<span class=\"list %s\">\n".printf(list_class));
            visit_children(node);
            markup.append("</span>\n\n");
            list_depth--;
        }

        public override void visit_list_item(ListItem node) {
            var indent = string.nfill((list_depth - 1) * 2, ' ');

            markup.append("%s<span class=\"list-item\">".printf(indent));

            if ((node.parent as List)?.list_type == ListType.ORDERED) {
                markup.append("%d. ".printf(node.number));
            } else {
                markup.append("• ");
            }

            visit_children(node);
            markup.append("</span>\n");
        }

        public override void visit_task_list_item(TaskListItem node) {
            var indent = string.nfill((list_depth - 1) * 2, ' ');

            markup.append("%s<span class=\"task-list-item\">".printf(indent));

            if (node.is_checked) {
                markup.append("☑ ");
            } else {
                markup.append("☐ ");
            }

            visit_children(node);
            markup.append("</span>\n");
        }

        public override void visit_blockquote(Blockquote node) {
            markup.append("<span class=\"blockquote\">");
            visit_children(node);
            markup.append("</span>\n\n");
        }

        public override void visit_thematic_break(ThematicBreak node) {
            markup.append("<span class=\"thematic-break\">━━━━━━━━━━</span>\n\n");
        }

        public override void visit_strikethrough(Strikethrough node) {
            markup.append("<span class=\"strikethrough\">");
            visit_children(node);
            markup.append("</span>");
        }

        public override void visit_table(Table node) {
            markup.append("<span class=\"table\">\n");
            visit_children(node);
            markup.append("</span>\n\n");
        }

        public override void visit_table_row(TableRow node) {
            markup.append("<span class=\"table-row\">");
            visit_children(node);
            markup.append("</span>\n");
        }

        public override void visit_table_cell(TableCell node) {
            string cell_class = (node.parent as TableRow)?.is_header ? "table-header" : "table-cell";
            markup.append("<span class=\"%s\">".printf(cell_class));

            visit_children(node);

            markup.append("</span> ");
        }

        public override void visit_line_break(LineBreak node) {
            markup.append("\n");
        }

        public override void visit_soft_break(SoftBreak node) {
            markup.append(" ");
    }

        public override void visit_html_block(HtmlBlock node) {
            markup.append("<span class=\"html-block\">");
            markup.append(escape_markup(node.content));
            markup.append("</span>\n\n");
        }

        public override void visit_html_inline(HtmlInline node) {
            markup.append(escape_markup(node.content));
        }

        // Helper methods

        private string escape_markup(string text) {
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
    }

    /**
     * GTK Markdown Preview Widget Helper
     *
     * Provides utility methods for setting up GTK widgets to display Markdown
     */
    public class GtkMarkdownPreview : Object {
        private PangoRenderer renderer;
        private PangoOptions options;

        public GtkMarkdownPreview(PangoOptions? options = null) {
            this.options = options ?? new PangoOptions();
            this.renderer = new PangoRenderer(this.options);
        }

        /**
         * Create a Gtk.Label widget with Markdown content
         */
        public Gtk.Label create_label(Document document) {
            var markup = renderer.render(document);
            var label = new Gtk.Label(null);
            label.set_markup(markup);
            label.set_use_markup(true);
            label.set_wrap(true);
            label.set_selectable(true);

            return label;
        }

        /**
         * Apply CSS to a Gtk.TextBuffer
         */
        public void apply_to_text_buffer(Document document, Gtk.TextBuffer buffer) {
            var css = renderer.generate_css();

            // Create a text tag table with styles
            var tag_table = buffer.get_tag_table();

            // Add tags for different styles
            add_tag(tag_table, "heading-1", "weight", Pango.Weight.BOLD, "scale", 2.0);
            add_tag(tag_table, "heading-2", "weight", Pango.Weight.BOLD, "scale", 1.75);
            add_tag(tag_table, "heading-3", "weight", Pango.Weight.BOLD, "scale", 1.5);
            add_tag(tag_table, "heading-4", "weight", Pango.Weight.BOLD, "scale", 1.25);
            add_tag(tag_table, "heading-5", "weight", Pango.Weight.BOLD, "scale", 1.1);
            add_tag(tag_table, "heading-6", "weight", Pango.Weight.BOLD, "scale", 1.0);
            add_tag(tag_table, "emphasis", "style", Pango.Style.ITALIC);
            add_tag(tag_table, "strong", "weight", Pango.Weight.BOLD);
            add_tag(tag_table, "code", "family", "Monospace");

            // Parse document and add text with tags
            buffer.set_text("");
            add_document_content(buffer, document);
        }

        private void add_tag(Gtk.TextTagTable table, string name, ...) {
            var args = va_list();
            var tag = new Gtk.TextTag(name);

            // Apply properties from variadic args
            // This is simplified - in real implementation would need proper handling

            table.add(tag);
        }

        private void add_document_content(Gtk.TextBuffer buffer, Document document) {
            Gtk.TextIter iter;
            buffer.get_start_iter(out iter);

            // This would be expanded to properly handle all node types
            // For now, just add text content
            var writer = new Writer();
            var text = writer.write(document);

            buffer.insert(ref iter, text, text.length);
        }

        /**
         * Create a complete preview widget (Gtk.ScrolledWindow with TextView)
         */
        public Gtk.Widget create_preview_widget(Document document) {
            var scrolled = new Gtk.ScrolledWindow();
            scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

            var text_view = new Gtk.TextView();
            text_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
            text_view.set_editable(false);
            text_view.set_cursor_visible(false);
            text_view.set_left_margin(10);
            text_view.set_right_margin(10);
            text_view.set_top_margin(10);
            text_view.set_bottom_margin(10);

            apply_to_text_buffer(document, text_view.get_buffer());

            scrolled.child = text_view;

            return scrolled;
        }
    }
}
