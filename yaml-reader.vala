/**
 * YAML Reader - YAML Front Matter 解析器实现
 * 
 * 本模块实现了 YAML Front Matter 的解析功能。
 * 支持 Markdown 文档开头的 YAML 元数据块解析。
 * 
 * @author GLM-5 / Taozuhong
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * YAML 解析错误域
     */
    public errordomain YamlError {
        /** 语法错误 */
        SYNTAX_ERROR,
        
        /** 类型错误 */
        TYPE_ERROR,
        
        /** 缩进错误 */
        INDENT_ERROR,
        
        /** 无效的 Front Matter 格式 */
        INVALID_FRONT_MATTER
    }

    /**
     * YAML 解析器
     * 
     * 将 YAML 文本解析为 YamlValue 对象。
     * 主要用于解析 Markdown 文档中的 Front Matter 元数据。
     * 
     * 使用示例：
     * ```vala
     * var parser = new YamlReader();
     * var metadata = parser.parse_front_matter("---\ntitle: Hello\n---");
     * ```
     */
    public class YamlReader : Object {
        
        /** 解析选项 */
        public bool preserve_raw_yaml { get; set; default = true; }
        
        /** 行数组 */
        private string[] _lines;
        
        /** 当前行索引 */
        private int _current_line;
        
        /** 当前缩进级别 */
        private int _current_indent;

        /**
         * 解析 YAML Front Matter
         * 
         * 解析 Markdown 文档开头的 YAML 元数据块。
         * 格式：
         * ```
         * ---
         * key: value
         * ---
         * ```
         * 
         * @param text 包含 Front Matter 的文本
         * @return 解析后的元数据对象
         * @throws YamlError 如果解析失败
         */
        public Metadata parse_front_matter(string text) throws YamlError {
            // 检查是否以 --- 开始
            string trimmed = text.chomp();
            
            if (!trimmed.has_prefix("---")) {
                // 没有 Front Matter，返回空元数据
                return new Metadata();
            }
            
            // 分割行
            _lines = text.split("\n");
            _current_line = 0;
            
            // 查找开始分隔符
            if (!find_front_matter_start()) {
                return new Metadata();
            }
            
            // 记录 Front Matter 内容的开始和结束位置
            int content_start = _current_line;
            int content_end = -1;
            
            // 查找结束分隔符
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                if (line.strip() == "---") {
                    content_end = _current_line;
                    break;
                }
                _current_line++;
            }
            
            if (content_end < 0) {
                throw new YamlError.INVALID_FRONT_MATTER(
                    "Missing closing '---' for front matter"
                );
            }
            
            // 提取 Front Matter 内容
            var content_lines = new Gee.ArrayList<string>();
            for (int i = content_start; i < content_end; i++) {
                content_lines.add(_lines[i]);
            }
            
            string yaml_content = string.joinv("\n", content_lines.to_array());
            
            // 解析 YAML 内容
            var metadata = new Metadata();
            
            if (preserve_raw_yaml) {
                metadata.raw_yaml = yaml_content;
            }
            
            if (yaml_content.strip().length > 0) {
                _lines = content_lines.to_array();
                _current_line = 0;
                _current_indent = 0;
                
                var map = parse_map(0);
                if (map != null) {
                    metadata = new Metadata.from_map(map);
                    if (preserve_raw_yaml) {
                        metadata.raw_yaml = yaml_content;
                    }
                }
            }
            
            return metadata;
        }

        /**
         * 从文本解析 YAML 映射
         * 
         * @param text YAML 文本
         * @return 解析后的 YamlMap 对象
         * @throws YamlError 如果解析失败
         */
        public YamlMap parse_map_from_string(string text) throws YamlError {
            _lines = text.split("\n");
            _current_line = 0;
            _current_indent = 0;
            
            var result = parse_map(0);
            if (result == null) {
                return new YamlMap();
            }
            return result;
        }

        /**
         * 从文本解析 YAML 值
         * 
         * @param text YAML 文本
         * @return 解析后的 YamlValue 对象
         * @throws YamlError 如果解析失败
         */
        public YamlValue parse_value_from_string(string text) throws YamlError {
            string trimmed = text.chomp();
            
            // 尝试解析各种类型
            if (trimmed.length == 0 || trimmed == "null" || trimmed == "~") {
                return new YamlNull();
            }
            
            // 布尔值
            string lower = trimmed.down();
            if (lower == "true") return new YamlBoolean(true);
            if (lower == "false") return new YamlBoolean(false);
            
            // 数字
            int64 int_val;
            if (int64.try_parse(trimmed, out int_val)) {
                return new YamlInteger(int_val);
            }
            
            double float_val;
            if (double.try_parse(trimmed, out float_val)) {
                return new YamlFloat(float_val);
            }
            
            // 日期
            var date = try_parse_date(trimmed);
            if (date != null) {
                return date;
            }
            
            // 引号包裹的字符串
            if ((trimmed.has_prefix("\"") && trimmed.has_suffix("\"")) ||
                (trimmed.has_prefix("'") && trimmed.has_suffix("'"))) {
                return new YamlString(unescape_string(trimmed[1:-1]));
            }
            
            // 普通字符串
            return new YamlString(trimmed);
        }

        /**
         * 检查文本是否有 Front Matter
         * 
         * @param text 要检查的文本
         * @return 如果有 Front Matter 返回 true
         */
        public static bool has_front_matter(string text) {
            string trimmed = text.chomp();
            if (!trimmed.has_prefix("---\n") && !trimmed.has_prefix("---\r")) {
                return false;
            }
            
            // 查找结束分隔符
            string[] lines = text.split("\n");
            bool found_start = false;
            
            foreach (string line in lines) {
                if (line.strip() == "---") {
                    if (!found_start) {
                        found_start = true;
                    } else {
                        return true; // 找到结束分隔符
                    }
                }
            }
            
            return false;
        }

        /**
         * 从带 Front Matter 的文档中提取内容部分
         * 
         * @param text 完整的文档文本
         * @return Front Matter 之后的 Markdown 内容
         */
        public static string extract_content(string text) {
            string[] lines = text.split("\n");
            bool in_front_matter = false;
            bool front_matter_ended = false;
            
            var content_lines = new Gee.ArrayList<string>();
            
            foreach (string line in lines) {
                if (line.strip() == "---") {
                    if (!in_front_matter) {
                        in_front_matter = true;
                        continue;
                    } else {
                        front_matter_ended = true;
                        continue;
                    }
                }
                
                if (front_matter_ended) {
                    content_lines.add(line);
                }
            }
            
            return string.joinv("\n", content_lines.to_array());
        }

        // ============================================================
        // 内部解析方法
        // ============================================================

        /**
         * 查找 Front Matter 开始分隔符
         */
        private bool find_front_matter_start() {
            while (_current_line < _lines.length) {
                string line = _lines[_current_line].strip();
                if (line == "---") {
                    _current_line++;
                    return true;
                }
                _current_line++;
            }
            return false;
        }

        /**
         * 解析映射
         */
        private YamlMap? parse_map(int min_indent) throws YamlError {
            var map = new YamlMap();
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                // 空行或注释行
                if (is_blank_or_comment(line)) {
                    _current_line++;
                    continue;
                }
                
                // 计算缩进
                int indent = count_leading_spaces(line);
                
                // 缩进减少，表示映射结束
                if (indent < min_indent) {
                    break;
                }
                
                // 检查是否是列表项（不属于映射）
                if (is_list_item(line)) {
                    break;
                }
                
                // 解析键值对
                string stripped = line.strip();
                int colon_pos = stripped.index_of_char(':');
                
                if (colon_pos < 0) {
                    throw new YamlError.SYNTAX_ERROR(
                        "Invalid mapping at line %d: missing colon".printf(_current_line + 1)
                    );
                }
                
                string key = stripped.substring(0, colon_pos).strip();
                string value_str = stripped.substring(colon_pos + 1).strip();
                
                _current_line++;
                
                YamlValue value;
                
                if (value_str.length > 0) {
                    // 行内值
                    value = parse_inline_value(value_str);
                } else {
                    // 值在下一行（嵌套映射或列表）
                    if (_current_line >= _lines.length) {
                        value = new YamlNull();
                    } else {
                        string next_line = _lines[_current_line];
                        int next_indent = count_leading_spaces(next_line);
                        
                        if (next_indent <= indent) {
                            // 没有嵌套内容
                            value = new YamlNull();
                        } else if (is_list_item(next_line)) {
                            // 嵌套列表
                            value = parse_list(next_indent);
                        } else {
                            // 嵌套映射
                            value = parse_map(next_indent);
                        }
                    }
                }
                
                map.set(key, value);
            }
            
            return map;
        }

        /**
         * 解析列表
         */
        private YamlList parse_list(int min_indent) throws YamlError {
            var list = new YamlList();
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                // 空行或注释行
                if (is_blank_or_comment(line)) {
                    _current_line++;
                    continue;
                }
                
                // 计算缩进
                int indent = count_leading_spaces(line);
                
                // 缩进减少，表示列表结束
                if (indent < min_indent) {
                    break;
                }
                
                // 检查是否是列表项
                if (!is_list_item(line)) {
                    break;
                }
                
                // 解析列表项
                string stripped = line.strip();
                string item_content = stripped.substring(2).strip(); // 移除 "- "
                
                _current_line++;
                
                YamlValue value;
                
                if (item_content.length > 0) {
                    // 行内值
                    value = parse_inline_value(item_content);
                    
                    // 如果值是映射的开始（包含冒号）
                    if (item_content.contains(": ") && value is YamlString) {
                        // 可能需要检查下一行是否有嵌套内容
                        if (_current_line < _lines.length) {
                            string next_line = _lines[_current_line];
                            int next_indent = count_leading_spaces(next_line);
                            
                            if (next_indent > indent + 2) {
                                // 有嵌套内容，重新解析
                                _current_line--;
                                value = parse_map_item(item_content, indent + 2);
                                _current_line++;
                            }
                        }
                    }
                } else {
                    // 值在下一行
                    if (_current_line >= _lines.length) {
                        value = new YamlNull();
                    } else {
                        string next_line = _lines[_current_line];
                        int next_indent = count_leading_spaces(next_line);
                        
                        if (next_indent <= indent) {
                            value = new YamlNull();
                        } else if (is_list_item(next_line)) {
                            value = parse_list(next_indent);
                        } else {
                            value = parse_map(next_indent);
                        }
                    }
                }
                
                list.add(value);
            }
            
            return list;
        }

        /**
         * 解析行内值
         */
        private YamlValue parse_inline_value(string text) throws YamlError {
            string trimmed = text.strip();
            
            if (trimmed.length == 0) {
                return new YamlNull();
            }
            
            // 空值
            if (trimmed == "null" || trimmed == "~" || trimmed == "") {
                return new YamlNull();
            }
            
            // 布尔值
            string lower = trimmed.down();
            if (lower == "true") return new YamlBoolean(true);
            if (lower == "false") return new YamlBoolean(false);
            
            // 引号包裹的字符串
            if (trimmed.length >= 2) {
                if ((trimmed[0] == '"' && trimmed[trimmed.length - 1] == '"') ||
                    (trimmed[0] == '\'' && trimmed[trimmed.length - 1] == '\'')) {
                    return new YamlString(unescape_string(trimmed[1:-1]));
                }
            }
            
            // 数字
            int64 int_val;
            if (int64.try_parse(trimmed, out int_val)) {
                return new YamlInteger(int_val);
            }
            
            double float_val;
            if (double.try_parse(trimmed.replace(",", "."), out float_val)) {
                return new YamlFloat(float_val);
            }
            
            // 日期
            var date = try_parse_date(trimmed);
            if (date != null) {
                return date;
            }
            
            // 内联列表 [a, b, c]
            if (trimmed.has_prefix("[") && trimmed.has_suffix("]")) {
                return parse_inline_list(trimmed[1:-1]);
            }
            
            // 内联映射 {a: b, c: d}
            if (trimmed.has_prefix("{") && trimmed.has_suffix("}")) {
                return parse_inline_map(trimmed[1:-1]);
            }
            
            // 普通字符串
            return new YamlString(trimmed);
        }

        /**
         * 解析内联列表
         */
        private YamlValue parse_inline_list(string text) throws YamlError {
            var list = new YamlList();
            
            string[] items = split_inline_items(text);
            
            foreach (string item in items) {
                list.add(parse_inline_value(item));
            }
            
            return list;
        }

        /**
         * 解析内联映射
         */
        private YamlValue parse_inline_map(string text) throws YamlError {
            var map = new YamlMap();
            
            string[] items = split_inline_items(text);
            
            foreach (string item in items) {
                int colon_pos = item.index_of_char(':');
                if (colon_pos < 0) {
                    throw new YamlError.SYNTAX_ERROR(
                        "Invalid inline map item: %s".printf(item)
                    );
                }
                
                string key = item.substring(0, colon_pos).strip();
                string value = item.substring(colon_pos + 1).strip();
                
                map.set(key, parse_inline_value(value));
            }
            
            return map;
        }

        /**
         * 解析映射项（列表中的映射）
         */
        private YamlValue parse_map_item(string text, int child_indent) throws YamlError {
            int colon_pos = text.index_of_char(':');
            if (colon_pos < 0) {
                return parse_inline_value(text);
            }
            
            string key = text.substring(0, colon_pos).strip();
            string value_str = text.substring(colon_pos + 1).strip();
            
            var map = new YamlMap();
            YamlValue value;
            
            if (value_str.length > 0) {
                value = parse_inline_value(value_str);
            } else {
                // 检查嵌套内容
                if (_current_line + 1 < _lines.length) {
                    string next_line = _lines[_current_line + 1];
                    int next_indent = count_leading_spaces(next_line);
                    
                    if (next_indent >= child_indent) {
                        _current_line++;
                        if (is_list_item(next_line)) {
                            value = parse_list(next_indent);
                        } else {
                            value = parse_map(next_indent);
                        }
                    } else {
                        value = new YamlNull();
                    }
                } else {
                    value = new YamlNull();
                }
            }
            
            map.set(key, value);
            
            // 继续解析同一缩进级别的其他键
            int current_indent = count_leading_spaces(_lines[_current_line]);
            
            while (_current_line < _lines.length) {
                string line = _lines[_current_line];
                
                if (is_blank_or_comment(line)) {
                    _current_line++;
                    continue;
                }
                
                int indent = count_leading_spaces(line);
                
                if (indent < current_indent) {
                    _current_line--;
                    break;
                }
                
                if (is_list_item(line)) {
                    _current_line--;
                    break;
                }
                
                string stripped = line.strip();
                colon_pos = stripped.index_of_char(':');
                
                if (colon_pos < 0) {
                    _current_line--;
                    break;
                }
                
                key = stripped.substring(0, colon_pos).strip();
                value_str = stripped.substring(colon_pos + 1).strip();
                
                _current_line++;
                
                if (value_str.length > 0) {
                    value = parse_inline_value(value_str);
                } else {
                    value = new YamlNull();
                }
                
                map.set(key, value);
            }
            
            return map;
        }

        /**
         * 尝试解析日期
         */
        private YamlValue? try_parse_date(string text) {
            // 日期格式：YYYY-MM-DD
            MatchInfo match_info;
            var date_regex = new Regex("^(\\d{4})-(\\d{2})-(\\d{2})$");
            
            if (date_regex.match(text, 0, out match_info)) {
                int year = int.parse(match_info.fetch(1));
                int month = int.parse(match_info.fetch(2));
                int day = int.parse(match_info.fetch(3));
                
                // 验证日期有效性
                if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                    return new YamlDate(year, month, day);
                }
            }
            
            // 日期时间格式：YYYY-MM-DD HH:MM:SS 或 YYYY-MM-DDTHH:MM:SS
            var datetime_regex = new Regex(
                "^(\\d{4})-(\\d{2})-(\\d{2})[T\\s](\\d{2}):(\\d{2})(?::(\\d{2}))?$"
            );
            
            if (datetime_regex.match(text, 0, out match_info)) {
                int year = int.parse(match_info.fetch(1));
                int month = int.parse(match_info.fetch(2));
                int day = int.parse(match_info.fetch(3));
                int hour = int.parse(match_info.fetch(4));
                int minute = int.parse(match_info.fetch(5));
                int second = match_info.fetch(6) != null ? int.parse(match_info.fetch(6)) : 0;
                
                try {
                    var dt = new DateTime.local(year, month, day, hour, minute, (double)second);
                    return new YamlDateTime(dt);
                } catch {
                    return null;
                }
            }
            
            return null;
        }

        // ============================================================
        // 辅助方法
        // ============================================================

        /**
         * 计算行首空格数
         */
        private int count_leading_spaces(string line) {
            int count = 0;
            foreach (uchar c in line.data) {
                if (c == ' ') count++;
                else if (c == '\t') count += 2; // Tab 视为 2 个空格
                else break;
            }
            return count;
        }

        /**
         * 判断是否为空行或注释行
         */
        private bool is_blank_or_comment(string line) {
            string stripped = line.strip();
            return stripped.length == 0 || stripped.has_prefix("#");
        }

        /**
         * 判断是否为列表项
         */
        private bool is_list_item(string line) {
            string stripped = line.strip();
            if (stripped.length < 2) return false;
            return stripped[0] == '-' && stripped[1] == ' ';
        }

        /**
         * 分割内联项
         */
        private string[] split_inline_items(string text) {
            var items = new Gee.ArrayList<string>();
            var current = new StringBuilder();
            int depth = 0;
            bool in_quotes = false;
            char quote_char = '\0';
            
            char c;
            for(int i = 0; i < text.length; i++) {
                c = text[i];
                if (in_quotes) {
                    current.append_c(c);
                    if (c == quote_char) {
                        in_quotes = false;
                    }
                } else if (c == '"' || c == '\'') {
                    in_quotes = true;
                    quote_char = c;
                    current.append_c(c);
                } else if (c == '[' || c == '{') {
                    depth++;
                    current.append_c(c);
                } else if (c == ']' || c == '}') {
                    depth--;
                    current.append_c(c);
                } else if (c == ',' && depth == 0) {
                    items.add(current.str.strip());
                    current = new StringBuilder();
                } else {
                    current.append_c(c);
                }
            }
            
            if (current.len > 0) {
                items.add(current.str.strip());
            }
            
            return items.to_array();
        }

        /**
         * 反转义字符串
         */
        private string unescape_string(string text) {
            return text.replace("\\n", "\n")
                       .replace("\\t", "\t")
                       .replace("\\r", "\r")
                       .replace("\\\"", "\"")
                       .replace("\\'", "'")
                       .replace("\\\\", "\\");
        }
    }
}
