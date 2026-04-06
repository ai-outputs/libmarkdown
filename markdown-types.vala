/**
 * Markdown Types - 类型定义和接口
 * 
 * 本模块定义了 Markdown 内存表示的核心类型系统，
 * 包括节点类型枚举、访问者接口和基础抽象类。
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * Markdown 节点类型枚举
     * 
     * 定义了所有支持的 Markdown 元素类型，包括块级元素和行内元素。
     * 每种类型对应特定的 Markdown 语法结构。
     */
    public enum NodeType {
        /** 文档根节点 */
        DOCUMENT,
        
        // ========== 块级元素 ==========
        
        /** 标题 (Heading) - 支持 H1-H6 */
        HEADING,
        
        /** 段落 (Paragraph) */
        PARAGRAPH,
        
        /** 无序列表 (Unordered List) */
        BULLET_LIST,
        
        /** 有序列表 (Ordered List) */
        ORDERED_LIST,
        
        /** 列表项 (List Item) */
        LIST_ITEM,
        
        /** 代码块 (Code Block / Fenced Code) */
        CODE_BLOCK,
        
        /** 引用块 (Blockquote) */
        BLOCK_QUOTE,
        
        /** 主题分隔线 (Thematic Break / Horizontal Rule) */
        THEMATIC_BREAK,
        
        /** HTML 块 (HTML Block) */
        HTML_BLOCK,
        
        // ========== 行内元素 ==========
        
        /** 纯文本 (Text) */
        TEXT,
        
        /** 强调/斜体 (Emphasis/Italic) */
        EMPHASIS,
        
        /** 加粗 (Strong/Bold) */
        STRONG,
        
        /** 行内代码 (Inline Code) */
        INLINE_CODE,
        
        /** 链接 (Link) */
        LINK,
        
        /** 图片 (Image) */
        IMAGE,
        
        /** 删除线 (Strikethrough) - GFM 扩展 */
        STRIKETHROUGH,
        
        /** HTML 行内元素 */
        HTML_INLINE,
        
        /** 软换行 (Soft Line Break) */
        SOFTBREAK,
        
        /** 硬换行 (Hard Line Break) */
        HARDBREAK;

        /**
         * 判断是否为块级元素
         * 
         * @return 如果是块级元素返回 true，否则返回 false
         */
        public bool is_block() {
            switch (this) {
                case DOCUMENT:
                case HEADING:
                case PARAGRAPH:
                case BULLET_LIST:
                case ORDERED_LIST:
                case LIST_ITEM:
                case CODE_BLOCK:
                case BLOCK_QUOTE:
                case THEMATIC_BREAK:
                case HTML_BLOCK:
                    return true;
                default:
                    return false;
            }
        }

        /**
         * 判断是否为行内元素
         * 
         * @return 如果是行内元素返回 true，否则返回 false
         */
        public bool is_inline() {
            return !is_block();
        }

        /**
         * 获取节点类型的可读名称
         * 
         * @return 节点类型的字符串表示
         */
        public string to_readable_string() {
            switch (this) {
                case DOCUMENT: return "Document";
                case HEADING: return "Heading";
                case PARAGRAPH: return "Paragraph";
                case BULLET_LIST: return "BulletList";
                case ORDERED_LIST: return "OrderedList";
                case LIST_ITEM: return "ListItem";
                case CODE_BLOCK: return "CodeBlock";
                case BLOCK_QUOTE: return "BlockQuote";
                case THEMATIC_BREAK: return "ThematicBreak";
                case HTML_BLOCK: return "HtmlBlock";
                case TEXT: return "Text";
                case EMPHASIS: return "Emphasis";
                case STRONG: return "Strong";
                case INLINE_CODE: return "InlineCode";
                case LINK: return "Link";
                case IMAGE: return "Image";
                case STRIKETHROUGH: return "Strikethrough";
                case HTML_INLINE: return "HtmlInline";
                case SOFTBREAK: return "Softbreak";
                case HARDBREAK: return "Hardbreak";
                default: return "Unknown";
            }
        }
    }

    /**
     * 节点访问者接口
     * 
     * 实现访问者模式，用于遍历和处理 Markdown 节点树。
     * 支持在访问前后执行自定义操作，可用于：
     * - 节点树遍历
     * - 内容转换
     * - 格式化输出
     * - 节点统计
     */
    public interface NodeVisitor : Object {
        
        /**
         * 进入节点时调用
         * 
         * 在访问节点的子节点之前调用。
         * 返回值决定是否继续遍历子节点。
         * 
         * @param node 当前访问的节点
         * @return 返回 true 继续遍历子节点，返回 false 跳过子节点
         */
        public abstract bool enter_node(Node node);

        /**
         * 离开节点时调用
         * 
         * 在访问完节点的所有子节点之后调用。
         * 用于执行后处理或清理操作。
         * 
         * @param node 当前访问的节点
         */
        public abstract void leave_node(Node node);
    }

    /**
     * 标题级别枚举
     * 
     * 定义了 Markdown 支持的标题级别，从 H1 到 H6。
     */
    public enum HeadingLevel {
        H1 = 1,
        H2 = 2,
        H3 = 3,
        H4 = 4,
        H5 = 5,
        H6 = 6;

        /**
         * 从整数创建标题级别
         * 
         * @param level 标题级别数值 (1-6)
         * @return 对应的 HeadingLevel 枚举值
         * @throws MarkdownError 如果级别不在 1-6 范围内
         */
        public static HeadingLevel from_int(int level) throws MarkdownError {
            if (level < 1 || level > 6) {
                throw new MarkdownError.INVALID_HEADING_LEVEL(
                    "Heading level must be between 1 and 6, got %d".printf(level)
                );
            }
            return (HeadingLevel)level;
        }

        /**
         * 获取标题前缀字符串
         * 
         * @return 对应级别的 # 前缀字符串
         */
        public string to_prefix() {
            return string.nfill((size_t)this, '#');
        }
    }

    /**
     * Markdown 错误域
     * 
     * 定义了 Markdown 处理过程中可能出现的错误类型。
     */
    public errordomain MarkdownError {
        /** 解析错误 - 输入的 Markdown 格式有问题 */
        PARSE_ERROR,
        
        /** 无效的标题级别 */
        INVALID_HEADING_LEVEL,
        
        /** 无效的节点操作 */
        INVALID_NODE_OPERATION,
        
        /** IO 错误 - 读写文件失败 */
        IO_ERROR,
        
        /** 无效的参数 */
        INVALID_ARGUMENT,
        
        /** 不支持的特性 */
        UNSUPPORTED_FEATURE
    }

    /**
     * 解析选项配置
     * 
     * 控制解析器的行为和启用的扩展特性。
     */
    public class ParseOptions : Object {
        
        /** 是否启用 GitHub Flavored Markdown 扩展 */
        public bool enable_gfm { get; set; default = true; }
        
        /** 是否解析删除线语法 */
        public bool enable_strikethrough { get; set; default = true; }
        
        /** 是否解析表格语法 */
        public bool enable_tables { get; set; default = true; }
        
        /** 是否解析任务列表语法 */
        public bool enable_task_lists { get; set; default = true; }
        
        /** 是否解析自动链接 */
        public bool enable_autolinks { get; set; default = true; }
        
        /** 是否保留原始位置信息 */
        public bool preserve_source_positions { get; set; default = true; }
        
        /** 是否规范化内联文本 */
        public bool normalize_text { get; set; default = true; }
        
        /** 最大解析深度，防止栈溢出 */
        public int max_parse_depth { get; set; default = 100; }

        /**
         * 创建默认解析选项
         * 
         * @return 配置了默认值的 ParseOptions 实例
         */
        public static ParseOptions defaults() {
            return new ParseOptions();
        }

        /**
         * 创建严格 CommonMark 兼容的解析选项
         * 
         * 禁用所有扩展特性，仅支持标准 CommonMark 规范。
         * 
         * @return 严格模式的 ParseOptions 实例
         */
        public static ParseOptions strict() {
            var opts = new ParseOptions();
            opts.enable_gfm = false;
            opts.enable_strikethrough = false;
            opts.enable_tables = false;
            opts.enable_task_lists = false;
            opts.enable_autolinks = false;
            return opts;
        }
    }

    /**
     * 渲染选项配置
     * 
     * 控制渲染器的输出格式和行为。
     */
    public class RenderOptions : Object {
        
        /** 缩进字符串（用于代码块等） */
        public string indent_string { get; set; default = "    "; }
        
        /** 是否保留原始位置信息 */
        public bool preserve_positions { get; set; default = false; }
        
        /** 换行符风格 */
        public string line_ending { get; set; default = "\n"; }
        
        /** 是否美化输出 */
        public bool pretty_print { get; set; default = false; }
        
        /** 代码块默认语言 */
        public string? default_code_language { get; set; default = null; }
        
        /** 最大行宽（0 表示不限制） */
        public int max_line_width { get; set; default = 0; }
        
        /** 是否转义 HTML */
        public bool escape_html { get; set; default = false; }
        
        /** 引用块前缀字符 */
        public string blockquote_prefix { get; set; default = "> "; }

        /**
         * 创建默认渲染选项
         * 
         * @return 配置了默认值的 RenderOptions 实例
         */
        public static RenderOptions defaults() {
            return new RenderOptions();
        }

        /**
         * 创建紧凑格式的渲染选项
         * 
         * 适合机器处理，减少不必要的空白。
         * 
         * @return 紧凑模式的 RenderOptions 实例
         */
        public static RenderOptions compact() {
            var opts = new RenderOptions();
            opts.pretty_print = false;
            opts.indent_string = "\t";
            return opts;
        }
    }

    /**
     * 源码位置信息
     * 
     * 记录节点在原始 Markdown 文本中的位置，
     * 用于错误报告和源码映射。
     */
    public struct SourcePosition {
        /** 起始行号（从 1 开始） */
        public int start_line;
        
        /** 起始列号（从 1 开始） */
        public int start_column;
        
        /** 结束行号 */
        public int end_line;
        
        /** 结束列号 */
        public int end_column;

        /**
         * 创建无效的位置信息
         * 
         * @return 所有字段都为 0 的位置信息
         */
        public static SourcePosition invalid() {
            return { 0, 0, 0, 0 };
        }

        /**
         * 创建单点位置
         * 
         * @param line 行号
         * @param column 列号
         * @return 起始和结束位置相同的位置信息
         */
        public static SourcePosition point(int line, int column) {
            return { line, column, line, column };
        }

        /**
         * 创建范围位置
         * 
         * @param start_line 起始行
         * @param start_column 起始列
         * @param end_line 结束行
         * @param end_column 结束列
         * @return 完整的位置信息
         */
        public static SourcePosition range(
            int start_line, int start_column,
            int end_line, int end_column
        ) {
            return { start_line, start_column, end_line, end_column };
        }

        /**
         * 判断位置是否有效
         * 
         * @return 如果位置信息有效返回 true
         */
        public bool is_valid() {
            return start_line > 0 && start_column > 0;
        }

        /**
         * 获取可读的位置字符串
         * 
         * @return 格式化的位置信息字符串
         */
        public string to_string() {
            if (!is_valid()) {
                return "<invalid position>";
            }
            if (start_line == end_line && start_column == end_column) {
                return "%d:%d".printf(start_line, start_column);
            }
            return "%d:%d-%d:%d".printf(
                start_line, start_column,
                end_line, end_column
            );
        }
    }

    /**
     * 链接定义信息
     * 
     * 存储文档中定义的链接引用信息。
     */
    public class LinkDefinition : Object {
        
        /** 链接标签（引用 ID） */
        public string label { get; set; }
        
        /** 链接目标 URL */
        public string destination { get; set; }
        
        /** 链接标题（可选） */
        public string? title { get; set; }

        /**
         * 创建链接定义
         * 
         * @param label 链接标签
         * @param destination 目标 URL
         * @param title 可选标题
         */
        public LinkDefinition(string label, string destination, string? title = null) {
            Object(
                label: label,
                destination: destination,
                title: title
            );
        }
    }
}
