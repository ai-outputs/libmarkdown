/**
 * Markdown Writer - Markdown 生成器实现
 * 
 * 本模块实现了将 Markdown 节点树序列化为文本的功能。
 * 支持多种输出格式和渲染选项。
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * Markdown 生成器
     * 
     * 将 Markdown 节点树转换为 Markdown 文本。
     * 支持自定义输出格式和渲染选项。
     * 
     * 使用示例：
     * ```vala
     * var writer = new MarkdownWriter();
     * string markdown = writer.render(document);
     * ```
     */
    public class MarkdownWriter : Object {
        
        /** 渲染选项 */
        public RenderOptions options { get; construct; }
        
        /** 输出构建器 */
        private StringBuilder _builder;
        
        /** 当前列表编号 */
        private int _list_counter;
        
        /** 当前列表类型 */
        private bool _in_ordered_list;
        
        /** 缩进级别 */
        private int _indent_level;

        /**
         * 构造函数
         * 
         * @param options 渲染选项，如果为 null 则使用默认选项
         */
        public MarkdownWriter(RenderOptions? options = null) {
            Object(options: options ?? RenderOptions.defaults());
        }

        /**
         * 渲染文档节点
         * 
         * 将文档节点树转换为 Markdown 文本。
         * 如果文档包含元数据，会先输出 YAML Front Matter。
         * 
         * @param document 文档根节点
         * @return 生成的 Markdown 文本
         */
        public string render(Document document) {
            return_val_if_fail(document != null, "");
            
            _builder = new StringBuilder();
            _list_counter = 1;
            _in_ordered_list = false;
            _indent_level = 0;
            
            // 渲染 YAML Front Matter 元数据
            if (document.has_metadata) {
                render_front_matter(document.metadata);
                _builder.append(options.line_ending);
            }
            
            // 渲染所有子节点
            bool first = true;
            foreach (var child in document.children) {
                if (!first) {
                    _builder.append(options.line_ending);
                }
                first = false;
                
                render_node(child);
            }
            
            // 渲染链接定义
            var link_defs = document.get_all_link_definitions();
            if (link_defs.size > 0) {
                _builder.append(options.line_ending);
                _builder.append(options.line_ending);
                
                foreach (var def in link_defs) {
                    render_link_definition(def);
                }
            }
            
            return _builder.str;
        }

        /**
         * 渲染 YAML Front Matter
         * 
         * @param metadata 元数据对象
         */
        private void render_front_matter(Metadata metadata) {
            _builder.append("---\n");
            _builder.append(metadata.to_yaml_string());
            _builder.append("\n---");
        }

        /**
         * 渲染单个节点
         * 
         * 将任意节点渲染为 Markdown 文本。
         * 
         * @param node 要渲染的节点
         * @return 生成的 Markdown 文本
         */
        public string render_node_one(Node node) {
            return_val_if_fail(node != null, "");
            
            var old_builder = _builder.str.dup();
            _builder.erase(0);
            
            render_node(node);
            
            var result = _builder.str.dup();
            _builder.erase(0);
            _builder.append(old_builder);
            return result;
        }

        /**
         * 渲染到文件
         * 
         * 将文档渲染并保存到文件。
         * 
         * @param document 文档节点
         * @param file 目标文件
         * @throws MarkdownError 如果写入失败
         */
        public void render_to_file(Document document, File file) throws MarkdownError {
            string content = render(document);
            
            try {
                FileUtils.set_contents(file.get_path(), content);
            } catch (FileError e) {
                throw new MarkdownError.IO_ERROR(
                    "Failed to write file: %s".printf(e.message)
                );
            }
        }

        /**
         * 渲染到路径
         * 
         * @param document 文档节点
         * @param path 目标文件路径
         * @throws MarkdownError 如果写入失败
         */
        public void render_to_path(Document document, string path) throws MarkdownError {
            render_to_file(document, File.new_for_path(path));
        }

        // ============================================================
        // 内部渲染方法
        // ============================================================

        /**
         * 渲染节点（内部方法）
         */
        private void render_node(Node node) {
            switch (node.node_type) {
                case NodeType.DOCUMENT:
                    render_document((Document)node);
                    break;
                    
                case NodeType.HEADING:
                    render_heading((Heading)node);
                    break;
                    
                case NodeType.PARAGRAPH:
                    render_paragraph((Paragraph)node);
                    break;
                    
                case NodeType.BULLET_LIST:
                    render_bullet_list((BulletList)node);
                    break;
                    
                case NodeType.ORDERED_LIST:
                    render_ordered_list((OrderedList)node);
                    break;
                    
                case NodeType.LIST_ITEM:
                    render_list_item((ListItem)node);
                    break;
                    
                case NodeType.CODE_BLOCK:
                    render_code_block((CodeBlock)node);
                    break;
                    
                case NodeType.BLOCK_QUOTE:
                    render_block_quote((BlockQuote)node);
                    break;
                    
                case NodeType.THEMATIC_BREAK:
                    render_thematic_break((ThematicBreak)node);
                    break;
                    
                case NodeType.HTML_BLOCK:
                    render_html_block((HtmlBlock)node);
                    break;
                    
                case NodeType.TEXT:
                    render_text((Text)node);
                    break;
                    
                case NodeType.EMPHASIS:
                    render_emphasis((Emphasis)node);
                    break;
                    
                case NodeType.STRONG:
                    render_strong((Strong)node);
                    break;
                    
                case NodeType.INLINE_CODE:
                    render_inline_code((InlineCode)node);
                    break;
                    
                case NodeType.LINK:
                    render_link((Link)node);
                    break;
                    
                case NodeType.IMAGE:
                    render_image((Image)node);
                    break;
                    
                case NodeType.STRIKETHROUGH:
                    render_strikethrough((Strikethrough)node);
                    break;
                    
                case NodeType.HTML_INLINE:
                    render_html_inline((HtmlInline)node);
                    break;
                    
                case NodeType.SOFTBREAK:
                    render_softbreak((Softbreak)node);
                    break;
                    
                case NodeType.HARDBREAK:
                    render_hardbreak((Hardbreak)node);
                    break;
                    
                default:
                    warning("Unknown node type: %s", node.node_type.to_readable_string());
                    break;
            }
        }

        /**
         * 渲染文档节点
         */
        private void render_document(Document node) {
            bool first = true;
            foreach (var child in node.children) {
                if (!first) {
                    _builder.append(options.line_ending);
                    if (child.node_type != NodeType.THEMATIC_BREAK) {
                        _builder.append(options.line_ending);
                    }
                }
                first = false;
                
                render_node(child);
            }
        }

        /**
         * 渲染标题
         */
        private void render_heading(Heading node) {
            // 添加缩进
            write_indent();
            
            // 写入 # 前缀
            _builder.append(node.level.to_prefix());
            _builder.append_c(' ');
            
            // 渲染行内内容
            render_inline_children(node);
        }

        /**
         * 渲染段落
         */
        private void render_paragraph(Paragraph node) {
            write_indent();
            render_inline_children(node);
        }

        /**
         * 渲染无序列表
         */
        private void render_bullet_list(BulletList node) {
            bool first = true;
            
            foreach (var child in node.children) {
                if (!first) {
                    if (node.is_tight) {
                        _builder.append(options.line_ending);
                    } else {
                        _builder.append(options.line_ending);
                        _builder.append(options.line_ending);
                    }
                }
                first = false;
                
                render_list_item_with_marker((ListItem)child, node.bullet_char);
            }
        }

        /**
         * 渲染有序列表
         */
        private void render_ordered_list(OrderedList node) {
            _list_counter = node.start_number;
            _in_ordered_list = true;
            
            bool first = true;
            
            foreach (var child in node.children) {
                if (!first) {
                    if (node.is_tight) {
                        _builder.append(options.line_ending);
                    } else {
                        _builder.append(options.line_ending);
                        _builder.append(options.line_ending);
                    }
                }
                first = false;
                
                render_list_item_with_marker((ListItem)child, node.delimiter);
                _list_counter++;
            }
            
            _in_ordered_list = false;
        }

        /**
         * 渲染列表项（带标记）
         */
        private void render_list_item_with_marker(ListItem item, char marker_or_delimiter) {
            // 写入标记
            if (_in_ordered_list) {
                _builder.append("%d%c ".printf(_list_counter, marker_or_delimiter));
            } else {
                _builder.append("%c ".printf(marker_or_delimiter));
            }
            
            // 任务列表项
            if (item.checked != null) {
                _builder.append("[%s] ".printf(item.checked ? "x" : " "));
            }
            
            // 渲染内容
            if (item.first_child != null) {
                render_inline_children(item);
            }
        }

        /**
         * 渲染列表项
         */
        private void render_list_item(ListItem node) {
            // 此方法通常不直接调用，由 render_list_item_with_marker 处理
            render_inline_children(node);
        }

        /**
         * 渲染代码块
         */
        private void render_code_block(CodeBlock node) {
            write_indent();
            
            if (node.is_fenced) {
                // 围栏代码块
                for (int i = 0; i < node.fence_length; i++) {
                    _builder.append_c(node.fence_char);
                }
                
                if (node.language != null) {
                    _builder.append(node.language);
                }
                
                _builder.append(options.line_ending);
                _builder.append(node.code);
                
                // 确保代码块以换行结束
                if (node.code.length > 0 && !node.code.has_suffix("\n")) {
                    _builder.append(options.line_ending);
                }
                
                for (int i = 0; i < node.fence_length; i++) {
                    _builder.append_c(node.fence_char);
                }
            } else {
                // 缩进代码块
                string[] lines = node.code.split("\n");
                bool first = true;
                
                foreach (string line in lines) {
                    if (!first) {
                        _builder.append(options.line_ending);
                    }
                    first = false;
                    
                    _builder.append(options.indent_string);
                    _builder.append(line);
                }
            }
        }

        /**
         * 渲染引用块
         */
        private void render_block_quote(BlockQuote node) {
            // 收集内容
            var content_builder = new StringBuilder();
            var old_builder = _builder.str.dup();
            _builder.erase(0);
            _indent_level++;
            
            bool first = true;
            foreach (var child in node.children) {
                if (!first) {
                    _builder.append(options.line_ending);
                }
                first = false;
                
                render_node(child);
            }
            
            _indent_level--;
            string content = _builder.str.dup();
            _builder.erase(0);
            _builder.append(old_builder);
            
            // 添加 > 前缀
            string[] lines = content.split("\n");
            
            bool first_line = true;
            foreach (string line in lines) {
                if (!first_line) {
                    _builder.append(options.line_ending);
                }
                first_line = false;
                
                _builder.append(options.blockquote_prefix);
                _builder.append(line);
            }
        }

        /**
         * 渲染主题分隔线
         */
        private void render_thematic_break(ThematicBreak node) {
            write_indent();
            _builder.append("---");
        }

        /**
         * 渲染 HTML 块
         */
        private void render_html_block(HtmlBlock node) {
            _builder.append(node.html);
        }

        /**
         * 渲染文本
         */
        private void render_text(Text node) {
            string text = node.text;
            
            // 根据选项转义特殊字符
            if (options.escape_html) {
                text = text.replace("&", "&amp;")
                           .replace("<", "&lt;")
                           .replace(">", "&gt;");
            }
            
            _builder.append(text);
        }

        /**
         * 渲染强调
         */
        private void render_emphasis(Emphasis node) {
            char delimiter = node.use_asterisk ? '*' : '_';
            _builder.append_c(delimiter);
            render_inline_children(node);
            _builder.append_c(delimiter);
        }

        /**
         * 渲染加粗
         */
        private void render_strong(Strong node) {
            char delimiter = node.use_asterisk ? '*' : '_';
            _builder.append_c(delimiter);
            _builder.append_c(delimiter);
            render_inline_children(node);
            _builder.append_c(delimiter);
            _builder.append_c(delimiter);
        }

        /**
         * 渲染行内代码
         */
        private void render_inline_code(InlineCode node) {
            for (int i = 0; i < node.backtick_count; i++) {
                _builder.append_c('`');
            }
            _builder.append(node.code);
            for (int i = 0; i < node.backtick_count; i++) {
                _builder.append_c('`');
            }
        }

        /**
         * 渲染链接
         */
        private void render_link(Link node) {
            if (node.is_autolink) {
                // 自动链接：<url>
                _builder.append("<");
                _builder.append(node.destination);
                _builder.append(">");
            } else if (node.is_reference_link) {
                // 引用链接：[text][ref]
                _builder.append("[");
                render_inline_children(node);
                _builder.append("][");
                _builder.append(node.reference_label);
                _builder.append("]");
            } else {
                // 行内链接：[text](url "title")
                _builder.append("[");
                render_inline_children(node);
                _builder.append("](");
                _builder.append(node.destination);
                
                if (node.title != null) {
                    _builder.append(" \"");
                    _builder.append(node.title);
                    _builder.append("\"");
                }
                
                _builder.append(")");
            }
        }

        /**
         * 渲染图片
         */
        private void render_image(Image node) {
            if (node.reference_label != null) {
                // 引用图片：![alt][ref]
                _builder.append("![");
                render_inline_children(node);
                _builder.append("][");
                _builder.append(node.reference_label);
                _builder.append("]");
            } else {
                // 行内图片：![alt](url "title")
                _builder.append("![");
                render_inline_children(node);
                _builder.append("](");
                _builder.append(node.destination);
                
                if (node.title != null) {
                    _builder.append(" \"");
                    _builder.append(node.title);
                    _builder.append("\"");
                }
                
                _builder.append(")");
            }
        }

        /**
         * 渲染删除线
         */
        private void render_strikethrough(Strikethrough node) {
            _builder.append("~~");
            render_inline_children(node);
            _builder.append("~~");
        }

        /**
         * 渲染行内 HTML
         */
        private void render_html_inline(HtmlInline node) {
            if (options.escape_html) {
                string escaped = node.html
                    .replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;");
                _builder.append(escaped);
            } else {
                _builder.append(node.html);
            }
        }

        /**
         * 渲染软换行
         */
        private void render_softbreak(Softbreak node) {
            _builder.append(options.line_ending);
        }

        /**
         * 渲染硬换行
         */
        private void render_hardbreak(Hardbreak node) {
            _builder.append("  ");
            _builder.append(options.line_ending);
        }

        /**
         * 渲染链接定义
         */
        private void render_link_definition(LinkDefinition def) {
            _builder.append("[%s]: %s".printf(def.label, def.destination));
            
            if (def.title != null) {
                _builder.append(" \"%s\"".printf(def.title));
            }
            
            _builder.append(options.line_ending);
        }

        /**
         * 渲染行内子节点
         */
        private void render_inline_children(Node node) {
            foreach (var child in node.children) {
                render_node(child);
            }
        }

        /**
         * 写入缩进
         */
        private void write_indent() {
            for (int i = 0; i < _indent_level; i++) {
                _builder.append(options.indent_string);
            }
        }
    }

    // ============================================================
    // 遍历和打印工具
    // ============================================================

    /**
     * 节点树打印器
     * 
     * 用于调试和可视化节点树结构。
     */
    public class NodePrinter : Object, NodeVisitor {
        
        /** 输出构建器 */
        private StringBuilder _builder;
        
        /** 当前缩进级别 */
        private int _indent;
        
        /** 缩进字符串 */
        public string indent_string { get; set; default = "  "; }
        
        /** 是否显示位置信息 */
        public bool show_positions { get; set; default = false; }
        
        /** 是否显示文本内容 */
        public bool show_text_content { get; set; default = true; }

        /**
         * 打印节点树
         * 
         * @param node 要打印的根节点
         * @return 格式化的节点树字符串
         */
        public string print(Node node) {
            _builder = new StringBuilder();
            _indent = 0;
            
            node.accept(this);
            
            return _builder.str;
        }

        /**
         * 进入节点时的处理
         */
        public bool enter_node(Node node) {
            write_indent();
            _builder.append(node.to_description());
            
            // 位置信息
            if (show_positions && node.source_position.is_valid()) {
                _builder.append(" @ ");
                _builder.append(node.source_position.to_string());
            }
            
            // 文本内容
            if (show_text_content && node is Text) {
                _builder.append(": \"%s\"".printf(((Text)node).text));
            } else if (show_text_content && node is CodeBlock) {
                var code = ((CodeBlock)node).code;
                if (code.length > 50) {
                    code = code.substring(0, 50) + "...";
                }
                _builder.append(": \"%s\"".printf(code.replace("\n", "\\n")));
            } else if (show_text_content && node is InlineCode) {
                _builder.append(": \"%s\"".printf(((InlineCode)node).code));
            }
            
            _builder.append("\n");
            
            _indent++;
            return true;
        }

        /**
         * 离开节点时的处理
         */
        public void leave_node(Node node) {
            _indent--;
        }

        /**
         * 写入缩进
         */
        private void write_indent() {
            for (int i = 0; i < _indent; i++) {
                _builder.append(indent_string);
            }
        }
    }

    /**
     * 节点统计器
     * 
     * 统计节点树中各类节点的数量。
     */
    public class NodeCounter : Object, NodeVisitor {
        
        /** 节点计数映射 */
        private Gee.HashMap<NodeType, int> _counts;

        public NodeCounter() {
            _counts = new Gee.HashMap<NodeType, int>();
        }

        /**
         * 统计节点树
         * 
         * @param node 要统计的根节点
         */
        public void count(Node node) {
            _counts.clear();
            node.accept(this);
        }

        /**
         * 获取指定类型节点的数量
         * 
         * @param type 节点类型
         * @return 节点数量
         */
        public int get_count(NodeType type) {
            return _counts[type];
        }

        /**
         * 获取所有统计结果
         * 
         * @return 类型到数量的映射
         */
        public Gee.Map<NodeType, int> get_all_counts() {
            return _counts.read_only_view;
        }

        /**
         * 获取统计摘要字符串
         * 
         * @return 格式化的统计摘要
         */
        public string get_summary() {
            var builder = new StringBuilder();
            builder.append("Node Statistics:\n");
            
            foreach (var entry in _counts.entries) {
                builder.append("  %s: %d\n".printf(
                    entry.key.to_readable_string(),
                    entry.value
                ));
            }
            
            return builder.str;
        }

        public bool enter_node(Node node) {
            int current = _counts[node.node_type];
            _counts[node.node_type] = current + 1;
            return true;
        }

        public void leave_node(Node node) {
            // 无需处理
        }
    }
}
