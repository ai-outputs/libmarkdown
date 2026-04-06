/**
 * Markdown Reader - Markdown 解析器实现
 * 
 * 本模块实现了完整的 Markdown 解析功能，将 Markdown 文本转换为内存中的节点树。
 * 支持 CommonMark 规范、GitHub Flavored Markdown 扩展和 YAML Front Matter。
 * 
 * @author GLM-5 / Taozuhong
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * Markdown 解析器
     * 
     * 将 Markdown 文本解析为节点树。支持多种解析选项和扩展特性。
     * 
     * 使用示例：
     * ```vala
     * var parser = new MarkdownReader();
     * var doc = parser.parse("# Hello World\n\nThis is a paragraph.");
     * ```
     */
    public class MarkdownReader : Object {
        
        /** 解析选项 */
        public ParseOptions options { get; construct; }
        
        /** 解析状态 */
        private ParserState _state;
        
        /** 行缓冲区 */
        private string[] _lines;
        
        /** 当前行索引 */
        private int _current_line;
        
        /** 链接定义收集 */
        private Gee.HashMap<string, LinkDefinition> _link_definitions;
        
        /** YAML 解析器 */
        private YamlReader? _yaml_reader;

        /**
         * 构造函数
         * 
         * @param options 解析选项，如果为 null 则使用默认选项
         */
        public MarkdownReader(ParseOptions? options = null) {
            Object(options: options ?? ParseOptions.defaults());
        }

        /**
         * 解析 Markdown 文本
         * 
         * 将输入的 Markdown 字符串解析为文档节点树。
         * 自动检测并解析 YAML Front Matter 元数据。
         * 
         * @param text Markdown 文本
         * @return 解析后的文档根节点
         * @throws MarkdownError 如果解析失败
         */
        public Document parse(string text) throws MarkdownError {
            return_val_if_fail(text != null, null);
            
            // 初始化解析状态
            _state = new ParserState();
            _link_definitions = new Gee.HashMap<string, LinkDefinition>();
            
            // 检查并解析 YAML Front Matter
            string markdown_content = text;
            Metadata? metadata = null;
            
            if (options.enable_gfm && YamlReader.has_front_matter(text)) {
                try {
                    _yaml_reader = new YamlReader();
                    metadata = _yaml_reader.parse_front_matter(text);
                    markdown_content = YamlReader.extract_content(text);
                } catch (YamlError e) {
                    warning("Failed to parse YAML front matter: %s", e.message);
                    // 继续解析，忽略元数据
                }
            }
            
            // 分割行
            _lines = preprocess_text(markdown_content);
            _current_line = 0;
            
            // 创建文档节点
            var document = new Document();
            
            // 设置元数据
            if (metadata != null && metadata.get_data().size > 0) {
                document.metadata = metadata;
            }
            
            // 第一遍：收集链接定义
            collect_link_definitions();
            
            // 重置行索引
            _current_line = 0;
            
            // 第二遍：解析块级元素
            parse_blocks(document);
            
            // 添加链接定义到文档
            foreach (var def in _link_definitions.values) {
                document.add_link_definition(def);
            }
            
            // 解析行内元素
            if (_current_line == _lines.length) {
                parse_inlines(document);
            }
            
            return document;
        }

        /**
         * 从文件解析 Markdown
         * 
         * 读取文件内容并解析为文档节点树。
         * 
         * @param file 文件对象
         * @return 解析后的文档根节点
         * @throws MarkdownError 如果读取或解析失败
         */
        public Document parse_file(File file) throws MarkdownError {
            try {
                string text;
                FileUtils.get_contents(file.get_path(), out text);
                return parse(text);
            } catch (FileError e) {
                throw new MarkdownError.IO_ERROR(
                    "Failed to read file: %s".printf(e.message)
                );
            }
        }

        /**
         * 从路径解析 Markdown
         * 
         * @param path 文件路径
         * @return 解析后的文档根节点
         * @throws MarkdownError 如果读取或解析失败
         */
        public Document parse_path(string path) throws MarkdownError {
            return parse_file(File.new_for_path(path));
        }

        // ============================================================
        // 文本预处理
        // ============================================================

        /**
         * 预处理文本
         * 
         * 统一换行符，分割为行数组。
         */
        private string[] preprocess_text(string text) {
            // 统一换行符为 \n
            string normalized = text.replace("\r\n", "\n").replace("\r", "\n");
            
            // 分割行
            string[] lines = normalized.split("\n");
            
            return lines;
        }

        // ============================================================
        // 链接定义收集
        // ============================================================

        /**
         * 收集链接定义
         * 
         * 第一遍扫描，提取所有链接定义。
         */
        private void collect_link_definitions() {
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                // 跳过空行
                if (is_blank_line(line)) {
                    _current_line++;
                    continue;
                }
                
                // 尝试解析链接定义
                var def = try_parse_link_definition(line);
                if (def != null) {
                    _link_definitions[def.label.down()] = def;
                    _current_line++;
                } else {
                    // 非链接定义，停止扫描
                    break;
                }
            }
        }

        /**
         * 尝试解析链接定义
         * 
         * 链接定义格式：[label]: destination "title"
         */
        private LinkDefinition? try_parse_link_definition(string line) {
            // 简化实现：匹配 [label]: url "title" 格式
            MatchInfo match_info;
            
            // 匹配链接定义
            var regex = new Regex(
                "^\\[([^\\]]+)\\]:\\s*([^\\s]+)(?:\\s+[\"']([^\"']*)[\"'])?$",
                RegexCompileFlags.OPTIMIZE
            );
            
            if (regex.match(line.strip(), 0, out match_info)) {
                string label = match_info.fetch(1);
                string destination = match_info.fetch(2);
                string? title = match_info.fetch(3);
                
                if (title != null && title.length == 0) {
                    title = null;
                }
                
                return new LinkDefinition(label, destination, title);
            }
            
            return null;
        }

        // ============================================================
        // 块级元素解析
        // ============================================================

        /**
         * 解析块级元素
         * 
         * 解析文档中的所有块级元素。
         */
        private void parse_blocks(Document document) throws MarkdownError {
            while (_current_line < _lines.length) {
                var block = parse_block();
                if (block != null) {
                    try {
                        document.append_child(block);
                    } catch (MarkdownError e) {
                        warning("Failed to append block: %s", e.message);
                    }
                }
            }
        }

        /**
         * 解析单个块级元素
         * 
         * 根据当前行内容判断并解析对应的块级元素。
         */
        private Node? parse_block() throws MarkdownError {
            if (_current_line >= _lines.length) {
                return null;
            }
            
            string line = _lines[_current_line];
            
            // 跳过空行
            if (is_blank_line(line)) {
                _current_line++;
                return null;
            }
            
            // 尝试各种块级元素
            
            // 主题分隔线
            if (is_thematic_break(line)) {
                _current_line++;
                return new ThematicBreak();
            }
            
            // ATX 标题
            var heading = try_parse_atx_heading();
            if (heading != null) {
                return heading;
            }
            
            // 围栏代码块
            var code_block = try_parse_fenced_code_block();
            if (code_block != null) {
                return code_block;
            }
            
            // 引用块
            if (line.has_prefix(">")) {
                return parse_block_quote();
            }
            
            // 无序列表
            if (is_bullet_list_start(line)) {
                return parse_bullet_list();
            }
            
            // 有序列表
            if (is_ordered_list_start(line)) {
                return parse_ordered_list();
            }
            
            // 默认：段落
            return parse_paragraph();
        }

        /**
         * 判断是否为空行
         */
        private bool is_blank_line(string line) {
            return line.strip().length == 0;
        }

        /**
         * 判断是否为主题分隔线
         */
        private bool is_thematic_break(string line) {
            string stripped = line.strip();
            if (stripped.length < 3) {
                return false;
            }
            
            char c = '\0';
            int count = 0;
            
            char ch;
            for(int i = 0; i < stripped.length; i++) {
                ch = stripped[i];
                if (ch == '-' || ch == '*' || ch == '_') {
                    if (c == '\0') {
                        c = ch;
                    } else if (c != ch) {
                        return false;
                    }
                    count++;
                } else if (ch != ' ' && ch != '\t') {
                    return false;
                }
            }
            
            return count >= 3;
        }

        /**
         * 尝试解析 ATX 标题
         * 
         * ATX 标题格式：# Heading
         */
        private Heading? try_parse_atx_heading() throws MarkdownError {
            string line = _lines[_current_line];
            
            // 计算前导 # 数量
            int level = 0;
            int i = 0;
            
            while (i < line.length && line[i] == '#') {
                level++;
                i++;
            }
            
            // 标题级别必须在 1-6 之间
            if (level < 1 || level > 6) {
                return null;
            }
            
            // # 后面必须有空格或行尾
            if (i < line.length && line[i] != ' ' && line[i] != '\t') {
                return null;
            }
            
            _current_line++;
            
            // 提取标题文本
            string content = line.substring(i).strip();
            
            // 移除尾部 #
            int end = content.length - 1;
            while (end >= 0 && content[end] == '#') {
                end--;
            }
            // 跳过尾部空格
            while (end >= 0 && (content[end] == ' ' || content[end] == '\t')) {
                end--;
            }
            
            if (end >= 0) {
                content = content.substring(0, end + 1);
            }
            
            var heading = new Heading(HeadingLevel.from_int(level));
            
            // 解析行内内容
            parse_inline_content(heading, content);
            
            return heading;
        }

        /**
         * 尝试解析围栏代码块
         */
        private CodeBlock? try_parse_fenced_code_block() throws MarkdownError {
            string line = _lines[_current_line];
            
            // 检查围栏开始
            char fence_char = '\0';
            int fence_length = 0;
            int i = 0;
            
            // 跳过前导空格（最多 3 个）
            while (i < line.length && i < 3 && line[i] == ' ') {
                i++;
            }
            
            // 检查围栏字符
            if (i < line.length && (line[i] == '`' || line[i] == '~')) {
                fence_char = line[i];
                while (i < line.length && line[i] == fence_char) {
                    fence_length++;
                    i++;
                }
            }
            
            if (fence_length < 3) {
                return null;
            }
            
            // 提取语言标识
            string? language = null;
            if (i < line.length) {
                string rest = line.substring(i).strip();
                if (rest.length > 0) {
                    language = rest;
                }
            }
            
            _current_line++;
            
            // 收集代码内容
            var code_builder = new StringBuilder();
            
            while (_current_line < _lines.length) {
                string code_line = _lines[_current_line];
                
                // 检查围栏结束
                int j = 0;
                while (j < code_line.length && j < 3 && code_line[j] == ' ') {
                    j++;
                }
                
                int end_fence_length = 0;
                while (j < code_line.length && code_line[j] == fence_char) {
                    end_fence_length++;
                    j++;
                }
                
                if (end_fence_length >= fence_length) {
                    // 检查结束围坊后是否只有空格
                    bool only_spaces = true;
                    while (j < code_line.length) {
                        if (code_line[j] != ' ' && code_line[j] != '\t') {
                            only_spaces = false;
                            break;
                        }
                        j++;
                    }
                    
                    if (only_spaces) {
                        _current_line++;
                        break;
                    }
                }
                
                code_builder.append(code_line);
                code_builder.append_c('\n');
                _current_line++;
            }
            
            var code_block = new CodeBlock();
            code_block.code = code_builder.str;
            code_block.language = language;
            code_block.is_fenced = true;
            code_block.fence_char = fence_char;
            code_block.fence_length = fence_length;
            
            return code_block;
        }

        /**
         * 解析引用块
         */
        private BlockQuote parse_block_quote() throws MarkdownError {
            var quote = new BlockQuote();
            var content_lines = new Gee.ArrayList<string>();
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                // 检查是否为引用行
                if (line.has_prefix(">")) {
                    // 移除 > 前缀
                    string content = line.substring(1);
                    if (content.length > 0 && content[0] == ' ') {
                        content = content.substring(1);
                    }
                    content_lines.add(content);
                    _current_line++;
                } else if (is_blank_line(line) && content_lines.size > 0) {
                    // 空行可能属于引用块
                    _current_line++;
                    // 检查下一行
                    if (_current_line < _lines.length) {
                        string next = _lines[_current_line];
                        if (!next.has_prefix(">")) {
                            break;
                        }
                    }
                } else {
                    break;
                }
            }
            
            // 解析引用块内容
            if (content_lines.size > 0) {
                string content = string.joinv("\n", content_lines.to_array());
                var inner_parser = new MarkdownReader(options);
                var inner_doc = inner_parser.parse(content);
                
                foreach (var child in inner_doc.children) {
                    try {
                        quote.append_child(child.clone());
                    } catch (MarkdownError e) {
                        warning("Failed to add child to block quote: %s", e.message);
                    }
                }
            }
            
            return quote;
        }

        /**
         * 判断是否为无序列表开始
         */
        private bool is_bullet_list_start(string line) {
            int i = 0;
            
            // 最多 3 个前导空格
            int space_count = 0;
            while (i < line.length && space_count < 3 && line[i] == ' ') {
                i++;
                space_count++;
            }
            
            if (i >= line.length) {
                return false;
            }
            
            char c = line[i];
            if (c != '-' && c != '*' && c != '+') {
                return false;
            }
            
            // 后面必须跟空格
            if (i + 1 >= line.length) {
                return false;
            }
            
            return line[i + 1] == ' ' || line[i + 1] == '\t';
        }

        /**
         * 解析无序列表
         */
        private BulletList parse_bullet_list() throws MarkdownError {
            var list = new BulletList();
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                if (is_blank_line(line)) {
                    // 检查是否连续两个空行
                    if (_current_line + 1 < _lines.length) {
                        string next = _lines[_current_line + 1];
                        if (is_blank_line(next) || !is_bullet_list_start(next)) {
                            _current_line++;
                            break;
                        }
                    }
                    _current_line++;
                    list.is_tight = false;
                    continue;
                }
                
                if (!is_bullet_list_start(line)) {
                    break;
                }
                
                var item = parse_list_item(true);
                try {
                    list.append_child(item);
                } catch (MarkdownError e) {
                    warning("Failed to add item to list: %s", e.message);
                }
            }
            
            return list;
        }

        /**
         * 判断是否为有序列表开始
         */
        private bool is_ordered_list_start(string line) {
            int i = 0;
            
            // 最多 3 个前导空格
            int space_count = 0;
            while (i < line.length && space_count < 3 && line[i] == ' ') {
                i++;
                space_count++;
            }
            
            if (i >= line.length) {
                return false;
            }
            
            // 检查数字
            if (!line[i].isdigit()) {
                return false;
            }
            
            // 跳过数字
            while (i < line.length && line[i].isdigit()) {
                i++;
            }
            
            if (i >= line.length) {
                return false;
            }
            
            char c = line[i];
            if (c != '.' && c != ')') {
                return false;
            }
            
            // 后面必须跟空格
            if (i + 1 >= line.length) {
                return false;
            }
            
            return line[i + 1] == ' ' || line[i + 1] == '\t';
        }

        /**
         * 解析有序列表
         */
        private OrderedList parse_ordered_list() throws MarkdownError {
            var list = new OrderedList();
            int start_number = 1;
            bool first_item = true;
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                if (is_blank_line(line)) {
                    if (_current_line + 1 < _lines.length) {
                        string next = _lines[_current_line + 1];
                        if (is_blank_line(next) || !is_ordered_list_start(next)) {
                            _current_line++;
                            break;
                        }
                    }
                    _current_line++;
                    list.is_tight = false;
                    continue;
                }
                
                if (!is_ordered_list_start(line)) {
                    break;
                }
                
                var item = parse_list_item(false);
                
                if (first_item) {
                    // 提取起始编号
                    int num = extract_list_number(line);
                    start_number = num;
                    first_item = false;
                }
                
                try {
                    list.append_child(item);
                } catch (MarkdownError e) {
                    warning("Failed to add item to list: %s", e.message);
                }
            }
            
            list.start_number = start_number;
            return list;
        }

        /**
         * 提取列表起始编号
         */
        private int extract_list_number(string line) {
            int i = 0;
            while (i < line.length && line[i] == ' ') {
                i++;
            }
            
            int num = 0;
            while (i < line.length && line[i].isdigit()) {
                num = num * 10 + (line[i] - '0');
                i++;
            }
            
            return num;
        }

        /**
         * 解析列表项
         */
        private ListItem parse_list_item(bool is_bullet) throws MarkdownError {
            var item = new ListItem();
            string line = _lines[_current_line];
            
            int i = 0;
            
            // 跳过前导空格
            while (i < line.length && line[i] == ' ') {
                i++;
            }
            
            // 跳过标记
            if (is_bullet) {
                i++; // 跳过 -, *, +
            } else {
                while (i < line.length && line[i].isdigit()) {
                    i++;
                }
                i++; // 跳过 . 或 )
            }
            
            // 跳过标记后的空格
            while (i < line.length && (line[i] == ' ' || line[i] == '\t')) {
                i++;
            }
            
            // 提取内容
            string content = "";
            if (i < line.length) {
                content = line.substring(i);
            }
            
            _current_line++;
            
            // 检查任务列表项
            if (options.enable_task_lists && content.length >= 3) {
                if (content[0] == '[' && (content[1] == ' ' || content[1] == 'x' || content[1] == 'X') && content[2] == ']') {
                    item.checked = (content[1] == 'x' || content[1] == 'X');
                    content = content.substring(3).strip();
                }
            }
            
            // 创建段落节点
            var para = new Paragraph();
            parse_inline_content(para, content);
            
            try {
                item.append_child(para);
            } catch (MarkdownError e) {
                warning("Failed to add paragraph to list item: %s", e.message);
            }
            
            return item;
        }

        /**
         * 解析段落
         */
        private Paragraph parse_paragraph() throws MarkdownError {
            var para = new Paragraph();
            var lines = new Gee.ArrayList<string>();
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                // 空行结束段落
                if (is_blank_line(line)) {
                    break;
                }
                
                // 检查是否开始新的块级元素
                if (is_thematic_break(line) || 
                    is_atx_heading_start(line) ||
                    is_bullet_list_start(line) ||
                    is_ordered_list_start(line) ||
                    is_fenced_code_start(line)) {
                    break;
                }
                
                lines.add(line);
                _current_line++;
            }
            
            // 合并行
            string content = string.joinv(" ", lines.to_array());
            parse_inline_content(para, content);
            
            return para;
        }

        /**
         * 判断是否为 ATX 标题开始
         */
        private bool is_atx_heading_start(string line) {
            int count = 0;
            foreach (uchar c in line.data) {
                if (c == '#') {
                    count++;
                } else {
                    break;
                }
            }
            return count >= 1 && count <= 6;
        }

        /**
         * 判断是否为围栏代码块开始
         */
        private bool is_fenced_code_start(string line) {
            int i = 0;
            while (i < line.length && i < 3 && line[i] == ' ') {
                i++;
            }
            
            if (i >= line.length) {
                return false;
            }
            
            char c = line[i];
            if (c != '`' && c != '~') {
                return false;
            }
            
            int count = 0;
            while (i < line.length && line[i] == c) {
                count++;
                i++;
            }
            
            return count >= 3;
        }

        // ============================================================
        // 行内元素解析
        // ============================================================

        /**
         * 解析所有节点的行内元素
         */
        private void parse_inlines(Node node) {
            node.traverse((n, depth) => {
                if (n is Paragraph || n is Heading) {
                    // 已经在 parse_inline_content 中处理
                }
                return true;
            });
        }

        /**
         * 解析行内内容
         * 
         * 将文本内容解析为行内节点。
         */
        private void parse_inline_content(Node parent, string content) throws MarkdownError {
            int i = 0;
            
            while (i < content.length) {
                char c = content[i];
                
                // 检查转义字符
                if (c == '\\' && i + 1 < content.length) {
                    char next = content[i + 1];
                    if (is_escapable(next)) {
                        try {
                            parent.append_child(new Text(next.to_string()));
                        } catch (MarkdownError e) {
                            warning("Failed to add escaped text: %s", e.message);
                        }
                        i += 2;
                        continue;
                    }
                }
                
                // 检查行内代码
                if (c == '`') {
                    var code_node = try_parse_inline_code(content, ref i);
                    if (code_node != null) {
                        parent.append_child(code_node);
                        continue;
                    }
                }
                
                // 检查强调和加粗
                if (c == '*' || c == '_') {
                    var emphasis_node = try_parse_emphasis_or_strong(content, ref i);
                    if (emphasis_node != null) {
                        parent.append_child(emphasis_node);
                        continue;
                    }
                }
                
                // 检查链接
                if (c == '[') {
                    var link_node = try_parse_link(content, ref i);
                    if (link_node != null) {
                        parent.append_child(link_node);
                        continue;
                    }
                }
                
                // 检查图片
                if (c == '!' && i + 1 < content.length && content[i + 1] == '[') {
                    var image_node = try_parse_image(content, ref i);
                    if (image_node != null) {
                        parent.append_child(image_node);
                        continue;
                    }
                }
                
                // 检查删除线
                if (options.enable_strikethrough && c == '~' && i + 1 < content.length && content[i + 1] == '~') {
                    var strike_node = try_parse_strikethrough(content, ref i);
                    if (strike_node != null) {
                        parent.append_child(strike_node);
                        continue;
                    }
                }
                
                // 检查硬换行
                if (c == ' ' && i + 1 < content.length && content[i + 1] == ' ' && 
                    (i + 2 >= content.length || content[i + 2] == '\n')) {
                    try {
                        parent.append_child(new Hardbreak());
                    } catch (MarkdownError e) {
                        warning("Failed to add hardbreak: %s", e.message);
                    }
                    i += 2;
                    continue;
                }
                
                // 累积普通文本
                var text_builder = new StringBuilder();
                while (i < content.length) {
                    c = content[i];
                    
                    // 检查特殊字符
                    if (c == '\\' || c == '`' || c == '*' || c == '_' || 
                        c == '[' || c == ']' || c == '!' || 
                        (options.enable_strikethrough && c == '~')) {
                        break;
                    }
                    
                    text_builder.append_c(c);
                    i++;
                }
                
                if (text_builder.len > 0) {
                    try {
                        parent.append_child(new Text(text_builder.str));
                    } catch (MarkdownError e) {
                        warning("Failed to add text: %s", e.message);
                    }
                }
                
                // 如果没有处理任何字符，前进一位
                if (text_builder.len == 0 && i < content.length) {
                    try {
                        parent.append_child(new Text(content[i].to_string()));
                    } catch (MarkdownError e) {
                        warning("Failed to add text: %s", e.message);
                    }
                    i++;
                }
            }
        }

        /**
         * 判断字符是否可转义
         */
        private bool is_escapable(char c) {
            return c == '\\' || c == '`' || c == '*' || c == '_' ||
                   c == '{' || c == '}' || c == '[' || c == ']' ||
                   c == '(' || c == ')' || c == '#' || c == '+' ||
                   c == '-' || c == '.' || c == '!' || c == '|' ||
                   c == '~' || c == '>';
        }

        /**
         * 尝试解析行内代码
         */
        private InlineCode? try_parse_inline_code(string content, ref int i) {
            int start = i;
            int backtick_count = 0;
            
            // 计算反引号数量
            while (i < content.length && content[i] == '`') {
                backtick_count++;
                i++;
            }
            
            // 查找匹配的结束反引号
            int code_start = i;
            while (i < content.length) {
                if (content[i] == '`') {
                    int end_count = 0;
                    while (i < content.length && content[i] == '`') {
                        end_count++;
                        i++;
                    }
                    
                    if (end_count == backtick_count) {
                        string code = content.substring(code_start, i - backtick_count - code_start);
                        var node = new InlineCode(code);
                        node.backtick_count = backtick_count;
                        return node;
                    }
                } else {
                    i++;
                }
            }
            
            // 没有找到匹配，回退
            i = start;
            return null;
        }

        /**
         * 尝试解析强调或加粗
         */
        private Node? try_parse_emphasis_or_strong(string content, ref int i) {
            int start = i;
            char delimiter = content[i];
            int delimiter_count = 0;
            
            // 计算分隔符数量
            while (i < content.length && content[i] == delimiter) {
                delimiter_count++;
                i++;
            }
            
            // 最少需要 1 个，最多支持 2 个
            if (delimiter_count < 1 || delimiter_count > 2) {
                i = start;
                return null;
            }
            
            // 查找结束分隔符
            int text_start = i;
            int end_pos = -1;
            
            while (i < content.length) {
                if (content[i] == delimiter) {
                    int end_count = 0;
                    while (i < content.length && content[i] == delimiter) {
                        end_count++;
                        i++;
                    }
                    
                    if (end_count == delimiter_count) {
                        end_pos = i - delimiter_count;
                        break;
                    }
                } else {
                    i++;
                }
            }
            
            if (end_pos < 0) {
                i = start;
                return null;
            }
            
            string text = content.substring(text_start, end_pos - text_start);
            
            if (delimiter_count == 2) {
                var strong = new Strong();
                strong.use_asterisk = (delimiter == '*');
                try {
                    strong.append_child(new Text(text));
                } catch (MarkdownError e) {
                    warning("Failed to add text to strong: %s", e.message);
                }
                return strong;
            } else {
                var emphasis = new Emphasis();
                emphasis.use_asterisk = (delimiter == '*');
                try {
                    emphasis.append_child(new Text(text));
                } catch (MarkdownError e) {
                    warning("Failed to add text to emphasis: %s", e.message);
                }
                return emphasis;
            }
        }

        /**
         * 尝试解析链接
         */
        private Link? try_parse_link(string content, ref int i) {
            int start = i;
            
            // 查找 ]
            int bracket_end = content.index_of_char(']', i);
            if (bracket_end < 0) {
                return null;
            }
            
            string link_text = content.substring(i + 1, bracket_end - i - 1);
            i = bracket_end + 1;
            
            // 检查链接类型
            if (i >= content.length) {
                i = start;
                return null;
            }
            
            var link = new Link();
            
            if (content[i] == '(') {
                // 行内链接
                i++;
                int paren_end = find_matching_paren(content, i);
                if (paren_end < 0) {
                    i = start;
                    return null;
                }
                
                string link_content = content.substring(i, paren_end - i).strip();
                i = paren_end + 1;
                
                // 解析 URL 和标题
                parse_link_destination_and_title(link_content, link);
            } else if (content[i] == '[') {
                // 引用链接
                i++;
                int ref_end = content.index_of_char(']', i);
                if (ref_end < 0) {
                    i = start;
                    return null;
                }
                
                string ref_label = content.substring(i, ref_end - i);
                i = ref_end + 1;
                
                if (ref_label.length == 0) {
                    ref_label = link_text;
                }
                
                link.reference_label = ref_label;
            } else {
                i = start;
                return null;
            }
            
            // 添加链接文本
            try {
                parse_inline_content(link, link_text);
            } catch (MarkdownError e) {
                warning("Failed to parse link text: %s", e.message);
            }
            
            return link;
        }

        /**
         * 查找匹配的右括号
         */
        private int find_matching_paren(string content, int start) {
            int depth = 1;
            int i = start;
            
            while (i < content.length && depth > 0) {
                if (content[i] == '(') {
                    depth++;
                } else if (content[i] == ')') {
                    depth--;
                    if (depth == 0) {
                        return i;
                    }
                }
                i++;
            }
            
            return -1;
        }

        /**
         * 解析链接目标和标题
         */
        private void parse_link_destination_and_title(string content, Link link) {
            // 简化实现：分割 URL 和标题
            int title_start = -1;
            
            // 查找标题开始
            for (int i = 0; i < content.length; i++) {
                if (content[i] == '"' || content[i] == '\'') {
                    title_start = i;
                    break;
                }
            }
            
            if (title_start > 0) {
                link.destination = content.substring(0, title_start).strip();
                
                // 提取标题
                char quote = content[title_start];
                int title_end = content.index_of_char(quote, title_start + 1);
                if (title_end > title_start) {
                    link.title = content.substring(title_start + 1, title_end - title_start - 1);
                }
            } else {
                link.destination = content.strip();
            }
        }

        /**
         * 尝试解析图片
         */
        private Link? try_parse_image(string content, ref int i) {
            int start = i;
            
            // 跳过 ![
            i += 2;
            
            // 查找 ]
            int bracket_end = content.index_of_char(']', i);
            if (bracket_end < 0) {
                i = start;
                return null;
            }
            
            string alt_text = content.substring(i, bracket_end - i);
            i = bracket_end + 1;
            
            if (i >= content.length || content[i] != '(') {
                i = start;
                return null;
            }
            
            i++;
            int paren_end = find_matching_paren(content, i);
            if (paren_end < 0) {
                i = start;
                return null;
            }
            
            string link_content = content.substring(i, paren_end - i).strip();
            i = paren_end + 1;
            
            var image = new Link();
            parse_link_destination_and_title(link_content, image);
            
            try {
                image.append_child(new Text(alt_text));
            } catch (MarkdownError e) {
                warning("Failed to add alt text to image: %s", e.message);
            }
            
            return image;
        }

        /**
         * 尝试解析删除线
         */
        private Strikethrough? try_parse_strikethrough(string content, ref int i) {
            int start = i;
            
            // 跳过 ~~
            i += 2;
            
            // 查找结束 ~~
            int end_pos = -1;
            while (i < content.length - 1) {
                if (content[i] == '~' && content[i + 1] == '~') {
                    end_pos = i;
                    break;
                }
                i++;
            }
            
            if (end_pos < 0) {
                i = start;
                return null;
            }
            
            string text = content.substring(start + 2, end_pos - start - 2);
            i += 2;
            
            var strike = new Strikethrough();
            try {
                strike.append_child(new Text(text));
            } catch (MarkdownError e) {
                warning("Failed to add text to strikethrough: %s", e.message);
            }
            
            return strike;
        }
    }

    /**
     * 解析器状态
     * 
     * 跟踪解析过程中的状态信息。
     */
    internal class ParserState : Object {
        /** 当前解析深度 */
        public int depth { get; set; default = 0; }
        
        /** 是否在链接文本中 */
        public bool in_link_text { get; set; default = false; }
        
        /** 当前块引用深度 */
        public int block_quote_depth { get; set; default = 0; }
    }
}
