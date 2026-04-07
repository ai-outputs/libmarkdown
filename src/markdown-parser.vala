/**
 * Markdown Parser Module
 *
 * Supports CommonMark spec, GFM extensions (tables, task lists, strikethrough),
 * and YAML Front Matter
 */

using Gee;

namespace Markdown {

    /**
     * Markdown parser options
     */
    public class ParseOptions : Object {
        public bool enable_gfm { get; set; default = true; }
        public bool enable_front_matter { get; set; default = true; }
        public bool enable_html { get; set; default = true; }
        public bool track_positions { get; set; default = true; }
        public bool parse_breaks { get; set; default = true; }

        public ParseOptions() {
            // Defaults are fine
        }
    }

    /**
     * Parser error information
     */
    public class ParseError : Object {
        public int line { get; set; }
        public int column { get; set; }
        public string message { get; set; }

        public ParseError(int line, int column, string message) {
            this.line = line;
            this.column = column;
            this.message = message;
        }
    }

    /**
     * Main Markdown Parser class
     */
    public class Parser : Object {
        private ParseOptions options;
        private string source;
        private int pos;
        private int line;
        private int column;
        private Gee.List<ParseError> errors;
        private int length;

        public Parser(ParseOptions? options = null) {
            this.options = options ?? new ParseOptions();
            this.errors = new ArrayList<ParseError>();
        }

        /**
         * Parse a Markdown string into a Document
         */
        public Document parse(string markdown) {
            source = markdown;
            length = source.length;
            pos = 0;
            line = 1;
            column = 1;
            errors.clear();

            var document = new Document();

            // Parse front matter if enabled
            if (options.enable_front_matter && has_front_matter()) {
                parse_front_matter(document);
            }

            // Parse block-level content
            parse_blocks(document);

            return document;
        }

        /**
         * Check if source starts with YAML front matter
         */
        private bool has_front_matter() {
            if (length < 4) return false;
            if (source[0] != '-' || source[1] != '-') return false;
            return true;
        }

        /**
         * Parse YAML front matter
         */
        private void parse_front_matter(Document document) {
            // Skip opening ---
            advance_n(3);
            skip_newline();

            var yaml_lines = new StringBuilder();

            while (pos < length) {
                if (source[pos] == '-' && source[pos + 1] == '-' && source[pos + 2] == '-') {
                    advance_n(3);
                    skip_newline();
                    break;
                }

                var line_start = pos;
                while (pos < length && source[pos] != '\n') {
                    advance();
                }
                yaml_lines.append(source.substring(line_start, pos - line_start));
                yaml_lines.append_c('\n');
                skip_newline();
            }

            // Parse simple YAML key: value pairs
            parse_simple_yaml(document, yaml_lines.str);
        }

        /**
         * Parse simple YAML key-value pairs
         */
        private void parse_simple_yaml(Document document, string yaml) {
            var lines = yaml.split("\n");
            foreach (var yaml_line in lines) {
                var trimmed = yaml_line.strip();
                if (trimmed.length == 0) continue;

                // Handle key: value
                int colon_pos = trimmed.index_of(":");
                if (colon_pos > 0) {
                    var key = trimmed.substring(0, colon_pos).strip();
                    var value = "";
                    if (colon_pos < trimmed.length - 1) {
                        value = trimmed.substring(colon_pos + 1).strip();
                        // Remove quotes if present
                        if ((value.has_prefix("\"") && value.has_suffix("\"")) ||
                            (value.has_prefix("'") && value.has_suffix("'"))) {
                            value = value.substring(1, value.length - 2);
                        }
                    }
                    document.front_matter[key] = value;
                }
            }
        }

        /**
         * Parse block-level elements
         */
        private void parse_blocks(Document document) {
            while (pos < length) {
                skip_blank_lines();

                if (pos >= length) break;

                var block = parse_block();
                if (block != null) {
                    document.append_child(block);
                }
            }
        }

        /**
         * Parse a single block element
         */
        private Node? parse_block() {
            if (is_heading()) return parse_heading();
            if (is_code_fence()) return parse_code_block();
            if (is_blockquote()) return parse_blockquote();
            if (is_list()) return parse_list();
            if (is_thematic_break()) return parse_thematic_break();
            if (is_html_block()) return parse_html_block();
            if (options.enable_gfm && is_table()) return parse_table();

            return parse_paragraph();
        }

        /**
         * Check if current position is a heading
         */
        private bool is_heading() {
            if (pos >= length) return false;
            int count = 0;
            while (pos + count < length && source[pos + count] == '#') {
                count++;
            }
            return count >= 1 && count <= 6 && pos + count < length &&
                   (source[pos + count] == ' ' || source[pos + count] == '\n');
        }

        /**
         * Parse heading
         */
        private Node parse_heading() {
            int level = 0;
            while (pos < length && source[pos] == '#') {
                level++;
                advance();
            }

            skip_spaces();
            var start_line = line;
            var start_col = column;

            var heading = new Heading(level);

            // Parse inline content
            parse_inline_content(heading);

            // Track position
            if (options.track_positions) {
                heading.position = new SourcePosition(start_line, start_col, line, column);
            }

            return heading;
        }

        /**
         * Check if current position is a code fence
         */
        private bool is_code_fence() {
            if (pos >= length) return false;
            if (source[pos] != '`' && source[pos] != '~') return false;

            char fence_char = source[pos];
            int count = 0;
            while (pos + count < length && source[pos + count] == fence_char) {
                count++;
            }

            return count >= 3;
        }

        /**
         * Parse fenced code block
         */
        private Node parse_code_block() {
            char fence_char = source[pos];
            int fence_len = 0;
            while (pos < length && source[pos] == fence_char) {
                fence_len++;
                advance();
            }

            // Parse language info
            string? language = null;
            skip_spaces();
            var lang_start = pos;
            while (pos < length && source[pos] != '\n') {
                advance();
            }
            if (pos > lang_start) {
                language = source.substring(lang_start, pos - lang_start).strip();
            }
            skip_newline();

            var code_block = new CodeBlock(language, true);
            var content = new StringBuilder();

            // Parse until closing fence
            while (pos < length) {
                // Check for closing fence
                int fence_count = 0;
                int check_pos = pos;
                while (check_pos < length && source[check_pos] == fence_char) {
                    fence_count++;
                    check_pos++;
                }

                if (fence_count >= fence_len) {
                    pos = check_pos;
                    break;
                }

                // Add line to content
                while (pos < length && source[pos] != '\n') {
                    content.append_c(source[pos]);
                    advance();
                }
                content.append_c('\n');
                skip_newline();
            }

            code_block.append_child(new Text(content.str));

            return code_block;
        }

        /**
         * Check if current position is a blockquote
         */
        private bool is_blockquote() {
            return pos < length && source[pos] == '>';
        }

        /**
         * Parse blockquote
         */
        private Node parse_blockquote() {
            var blockquote = new Blockquote();

            advance(); // Skip >
            skip_spaces();

            // Parse blockquote content as inline
            var para = new Paragraph();
            parse_inline_content(para);
            blockquote.append_child(para);

            return blockquote;
        }

        /**
         * Check if current position is a list
         */
        private bool is_list() {
            return is_bullet_list() || is_ordered_list() || is_task_list();
        }

        private bool is_bullet_list() {
            if (pos >= length) return false;
            return (source[pos] == '-' || source[pos] == '*' || source[pos] == '+') &&
                   (pos + 1 >= length || source[pos + 1] == ' ');
        }

        private bool is_ordered_list() {
            if (pos >= length) return false;
            int digits = 0;
            while (pos + digits < length && source[pos + digits].isdigit()) {
                digits++;
            }
            return digits > 0 && pos + digits < length &&
                   (source[pos + digits] == '.' || source[pos + digits] == ')');
        }

        private bool is_task_list() {
            return false; // Simplified for now
        }

        /**
         * Parse list
         */
        private Node parse_list() {
            ListType list_type = ListType.BULLET;
            int start_number = 1;

            if (is_ordered_list()) {
                list_type = ListType.ORDERED;
                var num_start = pos;
                while (pos < length && source[pos].isdigit()) {
                    advance();
                }
                start_number = int.parse(source.substring(num_start, pos - num_start));
                advance(); // Skip . or )
            } else if (is_bullet_list()) {
                advance(); // Skip bullet char
            } else if (is_task_list()) {
                list_type = ListType.TASK;
            }

            skip_spaces();

            var list = new List(list_type, start_number);

            // Check for task list item
            if (options.enable_gfm && pos < length && source[pos] == '[') {
                return parse_task_list_item(list);
            }

            var item = new ListItem(start_number);
            parse_inline_content(item);
            list.append_child(item);

            // Parse additional list items
            while (pos < length) {
                skip_newline();
                if (!is_list()) break;
                if (is_ordered_list()) {
                    var num_start = pos;
                    while (pos < length && source[pos].isdigit()) advance();
                    var num = int.parse(source.substring(num_start, pos - num_start));
                    advance();
                    skip_spaces();
                    var next_item = new ListItem(num);
                    parse_inline_content(next_item);
                    list.append_child(next_item);
                } else if (is_bullet_list()) {
                    advance();
                    skip_spaces();
                    var next_item = new ListItem();
                    parse_inline_content(next_item);
                    list.append_child(next_item);
                } else {
                    break;
                }
            }

            return list;
        }

        /**
         * Parse task list item
         */
        private Node parse_task_list_item(List list) {
            advance(); // Skip [
            bool checked = pos < length && source[pos] == 'x' || source[pos] == 'X';
            if (checked) advance();
            if (pos < length && source[pos] == ']') advance();
            skip_spaces();

            var task_item = new TaskListItem(checked);
            parse_inline_content(task_item);
            list.append_child(task_item);

            return list;
        }

        /**
         * Check for thematic break
         */
        private bool is_thematic_break() {
            if (pos >= length) return false;
            char c = source[pos];
            if (c != '-' && c != '*' && c != '_') return false;

            int count = 0;
            int i = pos;
            while (i < length && (source[i] == c || source[i] == ' ')) {
                if (source[i] == c) count++;
                i++;
            }

            return count >= 3;
        }

        /**
         * Parse thematic break
         */
        private Node parse_thematic_break() {
            while (pos < length && source[pos] != '\n') {
                advance();
            }
            skip_newline();

            return new ThematicBreak();
        }

        /**
         * Check for HTML block
         */
        private bool is_html_block() {
            if (!options.enable_html) return false;
            if (pos >= length || source[pos] != '<') return false;

            // Simple check for common block tags
            string[] block_tags = { "div", "p", "pre", "script", "style", "blockquote" };
            foreach (var tag in block_tags) {
                if (source[pos:].down().has_prefix("<" + tag)) {
                    return true;
                }
            }

            return false;
        }

        /**
         * Parse HTML block
         */
        private Node parse_html_block() {
            var content = new StringBuilder();

            while (pos < length && source[pos] != '\n') {
                content.append_c(source[pos]);
                advance();
            }
            skip_newline();

            return new HtmlBlock(content.str);
        }

        /**
         * Check for table (GFM)
         */
        private bool is_table() {
            // Simple check - actual parsing is more complex
            return false;
        }

        /**
         * Parse table (GFM)
         */
        private Node? parse_table() {
            return null; // Table parsing requires look-ahead
        }

        /**
         * Parse paragraph
         */
        private Node parse_paragraph() {
            var paragraph = new Paragraph();
            parse_inline_content(paragraph);
            return paragraph;
        }

        /**
         * Parse inline content into a node
         */
        private void parse_inline_content(Node parent) {
            var text_content = new StringBuilder();

            while (pos < length && source[pos] != '\n') {
                if (source[pos] == '*') {
                    // Flush pending text
                    if (text_content.len > 0) {
                        parent.append_child(new Text(text_content.str));
                        text_content = new StringBuilder();
                    }
                    parent.append_child(parse_emphasis());
                } else if (source[pos] == '`') {
                    if (text_content.len > 0) {
                        parent.append_child(new Text(text_content.str));
                        text_content = new StringBuilder();
                    }
                    parent.append_child(parse_inline_code());
                } else if (source[pos] == '[') {
                    if (text_content.len > 0) {
                        parent.append_child(new Text(text_content.str));
                        text_content = new StringBuilder();
                    }
                    parent.append_child(parse_link_or_image());
                } else if (options.enable_gfm && source[pos] == '~' && pos + 1 < length && source[pos + 1] == '~') {
                    if (text_content.len > 0) {
                        parent.append_child(new Text(text_content.str));
                        text_content = new StringBuilder();
                    }
                    parent.append_child(parse_strikethrough());
                } else {
                    text_content.append_c(source[pos]);
                    advance();
                }
            }

            // Flush remaining text
            if (text_content.len > 0) {
                parent.append_child(new Text(text_content.str));
            }

            // Skip newline
            if (pos < length && source[pos] == '\n') {
                skip_newline();
            }
        }

        /**
         * Parse emphasis (* or **)
         */
        private Node parse_emphasis() {
            int star_count = 0;
            while (pos < length && source[pos] == '*') {
                star_count++;
                advance();
            }

            var content_start = pos;
            int closing_count = 0;

            // Find closing
            while (pos < length) {
                if (source[pos] == '*') {
                    closing_count = 0;
                    while (pos < length && source[pos] == '*') {
                        closing_count++;
                        advance();
                    }

                    if (closing_count >= star_count) {
                        // Found closing
                        var content = source.substring(content_start,
                            pos - closing_count - content_start);

                        if (star_count >= 2) {
                            var strong = new Strong();
                            strong.append_child(new Text(content));
                            return strong;
                        } else {
                            var emph = new Emphasis();
                            emph.append_child(new Text(content));
                            return emph;
                        }
                    }
                } else {
                    advance();
                }
            }

            // No closing found, return as text
            return new Text(string.nfill(star_count, '*'));
        }

        /**
         * Parse inline code
         */
        private Node parse_inline_code() {
            int backtick_count = 0;
            while (pos < length && source[pos] == '`') {
                backtick_count++;
                advance();
            }

            var content = new StringBuilder();

            while (pos < length) {
                int current_backticks = 0;
                while (pos < length && source[pos] == '`') {
                    current_backticks++;
                    advance();
                }

                if (current_backticks >= backtick_count) {
                    break;
                }

                if (current_backticks > 0) {
                    for (int i = 0; i < current_backticks; i++) {
                        content.append_c('`');
                    }
                } else {
                    content.append_c(source[pos]);
                    advance();
                }
            }

            return new Code(content.str);
        }

        /**
         * Parse link or image
         */
        private Node parse_link_or_image() {
            bool is_image = pos > 0 && source[pos - 1] == '!';

            if (is_image) {
                advance(); // Skip !
            }

            advance(); // Skip [

            // Parse link text
            var text_start = pos;
            while (pos < length && source[pos] != ']') {
                advance();
            }

            var text = source.substring(text_start, pos - text_start);
            advance(); // Skip ]

            // Parse URL
            if (pos >= length || source[pos] != '(') {
                return new Text("[" + text + "]");
            }
            advance(); // Skip (

            skip_spaces();
            var url_start = pos;
            while (pos < length && source[pos] != ')' && source[pos] != ' ') {
                advance();
            }

            var url = source.substring(url_start, pos - url_start);

            // Parse optional title
            string? title = null;
            skip_spaces();
            if (pos < length && (source[pos] == '"' || source[pos] == '\'')) {
                var quote = source[pos];
                advance();
                var title_start = pos;
                while (pos < length && source[pos] != quote) {
                    advance();
                }
                title = source.substring(title_start, pos - title_start);
                advance(); // Skip quote
            }

            if (pos < length && source[pos] == ')') {
                advance();
            }

            if (is_image) {
                var image = new Image(url, title, text);
                image.append_child(new Text(text));
                return image;
            } else {
                var link = new Link(url, title);
                link.append_child(new Text(text));
                return link;
            }
        }

        /**
         * Parse strikethrough (GFM)
         */
        private Node parse_strikethrough() {
            advance(); advance(); // Skip ~~

            var content_start = pos;

            while (pos < length) {
                if (source[pos] == '~' && pos + 1 < length && source[pos + 1] == '~') {
                    var content = source.substring(content_start, pos - content_start);
                    advance(); advance();

                    var strike = new Strikethrough();
                    strike.append_child(new Text(content));
                    return strike;
                }
                advance();
            }

            return new Text("~~");
        }

        // Helper methods

        private void advance() {
            if (pos < length) {
                if (source[pos] == '\n') {
                    line++;
                    column = 1;
                } else {
                    column++;
                }
                pos++;
            }
        }

        private void advance_n(int count) {
            for (int i = 0; i < count && pos < length; i++) {
                advance();
            }
        }

        private void skip_spaces() {
            while (pos < length && source[pos] == ' ') {
                advance();
            }
        }

        private void skip_newline() {
            if (pos < length && source[pos] == '\n') {
                advance();
            }
        }

        private void skip_blank_lines() {
            while (pos < length) {
                skip_spaces();
                if (pos < length && source[pos] == '\n') {
                    advance();
                } else {
                    break;
                }
            }
        }

        /**
         * Get parsing errors
         */
        public Gee.List<ParseError> get_errors() {
            return errors.read_only_view;
        }
    }
}
