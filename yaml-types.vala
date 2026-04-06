/**
 * YAML Types - YAML 元数据类型定义
 * 
 * 本模块定义了 YAML Front Matter 元数据的类型系统，
 * 包括 YAML 值类型、元数据节点和访问接口。
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * YAML 值类型枚举
     * 
     * 定义 YAML 值的基本类型。
     */
    public enum ValueType {
        /** 空值 (null) */
        NULL,
        
        /** 布尔值 (true/false) */
        BOOLEAN,
        
        /** 整数 */
        INTEGER,
        
        /** 浮点数 */
        FLOAT,
        
        /** 字符串 */
        STRING,
        
        /** 列表/数组 */
        LIST,
        
        /** 映射/字典 */
        MAP,
        
        /** 日期 */
        DATE,
        
        /** 日期时间 */
        DATETIME;

        /**
         * 获取类型的可读名称
         */
        public string to_readable_string() {
            switch (this) {
                case NULL: return "Null";
                case BOOLEAN: return "Boolean";
                case INTEGER: return "Integer";
                case FLOAT: return "Float";
                case STRING: return "String";
                case LIST: return "List";
                case MAP: return "Map";
                case DATE: return "Date";
                case DATETIME: return "DateTime";
                default: return "Unknown";
            }
        }
    }

    /**
     * YAML 值抽象基类
     * 
     * 所有 YAML 值类型的基类，提供统一的值访问接口。
     */
    public abstract class YamlValue : Object {
        
        /** 值类型 */
        public abstract ValueType value_type { get; }
        
        /** 是否为空值 */
        public bool is_null {
            get { return value_type == ValueType.NULL; }
        }

        /**
         * 获取布尔值
         * 
         * @return 布尔值，如果类型不匹配返回默认值
         */
        public virtual bool get_boolean(bool default_value = false) {
            return default_value;
        }

        /**
         * 获取整数值
         * 
         * @return 整数值，如果类型不匹配返回默认值
         */
        public virtual int64 get_integer(int64 default_value = 0) {
            return default_value;
        }

        /**
         * 获取浮点数值
         * 
         * @return 浮点数值，如果类型不匹配返回默认值
         */
        public virtual double get_float(double default_value = 0.0) {
            return default_value;
        }

        /**
         * 获取字符串值
         * 
         * @return 字符串值，如果类型不匹配返回默认值
         */
        public virtual string get_string(string default_value = "") {
            return default_value;
        }

        /**
         * 获取列表值
         * 
         * @return 列表值，如果类型不匹配返回 null
         */
        public virtual Gee.List<YamlValue>? get_list() {
            return null;
        }

        /**
         * 获取映射值
         * 
         * @return 映射值，如果类型不匹配返回 null
         */
        public virtual Gee.Map<string, YamlValue>? get_map() {
            return null;
        }

        /**
         * 获取日期值
         * 
         * @return 日期值，如果类型不匹配返回 null
         */
        public virtual DateTime? get_date() {
            return null;
        }

        /**
         * 克隆值
         * 
         * @return 值的深拷贝
         */
        public abstract YamlValue clone();

        /**
         * 转换为 YAML 字符串
         * 
         * @return YAML 格式的字符串表示
         */
        public abstract string to_yaml_string(int indent = 0);

        /**
         * 转换为可读字符串
         * 
         * @return 可读的字符串表示
         */
        public abstract string to_string();
    }

    /**
     * YAML 空值
     */
    public class YamlNull : YamlValue {
        
        public override ValueType value_type {
            get { return ValueType.NULL; }
        }

        public override YamlValue clone() {
            return new YamlNull();
        }

        public override string to_yaml_string(int indent = 0) {
            return "null";
        }

        public override string to_string() {
            return "null";
        }
    }

    /**
     * YAML 布尔值
     */
    public class YamlBoolean : YamlValue {
        
        public bool value { get; set; }

        public override ValueType value_type {
            get { return ValueType.BOOLEAN; }
        }

        public YamlBoolean(bool value = false) {
            this.value = value;
        }

        public override bool get_boolean(bool default_value = false) {
            return value;
        }

        public override YamlValue clone() {
            return new YamlBoolean(value);
        }

        public override string to_yaml_string(int indent = 0) {
            return value ? "true" : "false";
        }

        public override string to_string() {
            return value ? "true" : "false";
        }
    }

    /**
     * YAML 整数值
     */
    public class YamlInteger : YamlValue {
        
        public int64 value { get; set; }

        public override ValueType value_type {
            get { return ValueType.INTEGER; }
        }

        public YamlInteger(int64 value = 0) {
            this.value = value;
        }

        public override int64 get_integer(int64 default_value = 0) {
            return value;
        }

        public override double get_float(double default_value = 0.0) {
            return (double)value;
        }

        public override YamlValue clone() {
            return new YamlInteger(value);
        }

        public override string to_yaml_string(int indent = 0) {
            return value.to_string();
        }

        public override string to_string() {
            return value.to_string();
        }
    }

    /**
     * YAML 浮点数值
     */
    public class YamlFloat : YamlValue {
        
        public double value { get; set; }

        public override ValueType value_type {
            get { return ValueType.FLOAT; }
        }

        public YamlFloat(double value = 0.0) {
            this.value = value;
        }

        public override double get_float(double default_value = 0.0) {
            return value;
        }

        public override int64 get_integer(int64 default_value = 0) {
            return (int64)value;
        }

        public override YamlValue clone() {
            return new YamlFloat(value);
        }

        public override string to_yaml_string(int indent = 0) {
            return value.to_string();
        }

        public override string to_string() {
            return value.to_string();
        }
    }

    /**
     * YAML 字符串值
     */
    public class YamlString : YamlValue {
        
        public string value { get; set; }

        public override ValueType value_type {
            get { return ValueType.STRING; }
        }

        public YamlString(string value = "") {
            this.value = value;
        }

        public override string get_string(string default_value = "") {
            return value;
        }

        public override YamlValue clone() {
            return new YamlString(value);
        }

        public override string to_yaml_string(int indent = 0) {
            // 检查是否需要引号
            if (needs_quotes(value)) {
                return "\"%s\"".printf(escape_string(value));
            }
            return value;
        }

        public override string to_string() {
            return value;
        }

        /**
         * 判断字符串是否需要引号
         */
        private bool needs_quotes(string s) {
            if (s.length == 0) return true;
            
            // 检查是否以特殊字符开头
            char first = s[0];
            if (first == '&' || first == '*' || first == '?' || 
                first == '|' || first == '-' || first == '<' ||
                first == '=' || first == '!' || first == '%' ||
                first == '@' || first == '`') {
                return true;
            }
            
            // 检查是否是布尔值或空值
            string lower = s.down();
            if (lower == "true" || lower == "false" || 
                lower == "null" || lower == "~") {
                return true;
            }
            
            // 检查是否包含冒号后跟空格
            if (s.contains(": ") || s.contains(" #")) {
                return true;
            }
            
            // 检查是否以空格开头或结尾
            if (s[0].isspace() || s[s.length - 1].isspace()) {
                return true;
            }
            
            // 检查是否包含换行符
            if (s.contains("\n")) {
                return true;
            }
            
            return false;
        }

        /**
         * 转义字符串中的特殊字符
         */
        private string escape_string(string s) {
            return s.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", "\\n")
                    .replace("\t", "\\t")
                    .replace("\r", "\\r");
        }
    }

    /**
     * YAML 列表值
     */
    public class YamlList : YamlValue {
        
        private Gee.ArrayList<YamlValue> _items;

        public override ValueType value_type {
            get { return ValueType.LIST; }
        }

        public int size {
            get { return _items.size; }
        }

        public YamlList() {
            _items = new Gee.ArrayList<YamlValue>();
        }

        /**
         * 添加元素
         */
        public void add(YamlValue value) {
            _items.add(value);
        }

        /**
         * 获取指定索引的元素
         */
        public YamlValue? get_at(int index) {
            if (index < 0 || index >= _items.size) {
                return null;
            }
            return _items[index];
        }

        /**
         * 获取所有元素
         */
        public Gee.List<YamlValue> get_items() {
            return _items.read_only_view;
        }

        public override Gee.List<YamlValue>? get_list() {
            return _items.read_only_view;
        }

        public override YamlValue clone() {
            var list = new YamlList();
            foreach (var item in _items) {
                list.add(item.clone());
            }
            return list;
        }

        public override string to_yaml_string(int indent = 0) {
            var builder = new StringBuilder();
            string indent_str = string.nfill((size_t)indent, ' ');
            
            foreach (var item in _items) {
                builder.append("%s- %s\n".printf(
                    indent_str,
                    item.to_yaml_string(indent + 2)
                ));
            }
            
            return builder.str.chomp();
        }

        public override string to_string() {
            var builder = new StringBuilder();
            builder.append("[");
            
            bool first = true;
            foreach (var item in _items) {
                if (!first) {
                    builder.append(", ");
                }
                first = false;
                builder.append(item.to_string());
            }
            
            builder.append("]");
            return builder.str;
        }
    }

    /**
     * YAML 映射值
     */
    public class YamlMap : YamlValue {
        
        private Gee.HashMap<string, YamlValue> _entries;

        public override ValueType value_type {
            get { return ValueType.MAP; }
        }

        public int size {
            get { return _entries.size; }
        }

        public Gee.Set<string> keys {
            owned get { return _entries.keys; }
        }

        public YamlMap() {
            _entries = new Gee.HashMap<string, YamlValue>();
        }

        /**
         * 设置键值对
         */
        public void set(string key, YamlValue value) {
            _entries[key] = value;
        }

        /**
         * 获取指定键的值
         */
        public YamlValue? get_value(string key) {
            return _entries[key];
        }

        /**
         * 检查是否包含指定键
         */
        public bool has_key(string key) {
            return _entries.has_key(key);
        }

        /**
         * 移除指定键
         */
        public bool remove(string key) {
            return _entries.unset(key);
        }

        /**
         * 获取所有条目
         */
        public Gee.Map<string, YamlValue> get_entries() {
            return _entries.read_only_view;
        }

        public override Gee.Map<string, YamlValue>? get_map() {
            return _entries.read_only_view;
        }

        public override YamlValue clone() {
            var map = new YamlMap();
            foreach (var entry in _entries.entries) {
                map.set(entry.key, entry.value.clone());
            }
            return map;
        }

        public override string to_yaml_string(int indent = 0) {
            var builder = new StringBuilder();
            string indent_str = string.nfill((size_t)indent, ' ');
            
            foreach (var entry in _entries.entries) {
                builder.append("%s%s: %s\n".printf(
                    indent_str,
                    entry.key,
                    entry.value.to_yaml_string(indent + 2)
                ));
            }
            
            return builder.str.chomp();
        }

        public override string to_string() {
            var builder = new StringBuilder();
            builder.append("{");
            
            bool first = true;
            foreach (var entry in _entries.entries) {
                if (!first) {
                    builder.append(", ");
                }
                first = false;
                builder.append("%s: %s".printf(entry.key, entry.value.to_string()));
            }
            
            builder.append("}");
            return builder.str;
        }
    }

    /**
     * YAML 日期值
     */
    public class YamlDate : YamlValue {
        
        public int year { get; set; }
        public int month { get; set; }
        public int day { get; set; }

        public override ValueType value_type {
            get { return ValueType.DATE; }
        }

        public YamlDate(int year, int month, int day) {
            this.year = year;
            this.month = month;
            this.day = day;
        }

        public override DateTime? get_date() {
            return new DateTime.local(year, month, day, 0, 0, 0.0);
        }

        public override string get_string(string default_value = "") {
            return "%04d-%02d-%02d".printf(year, month, day);
        }

        public override YamlValue clone() {
            return new YamlDate(year, month, day);
        }

        public override string to_yaml_string(int indent = 0) {
            return "%04d-%02d-%02d".printf(year, month, day);
        }

        public override string to_string() {
            return to_yaml_string();
        }
    }

    /**
     * YAML 日期时间值
     */
    public class YamlDateTime : YamlValue {
        
        public DateTime value { get; set; }

        public override ValueType value_type {
            get { return ValueType.DATETIME; }
        }

        public YamlDateTime(DateTime value) {
            this.value = value;
        }

        public override DateTime? get_date() {
            return value;
        }

        public override string get_string(string default_value = "") {
            return value.format("%Y-%m-%d %H:%M:%S");
        }

        public override YamlValue clone() {
            return new YamlDateTime(value.add_seconds(0)); // 创建副本
        }

        public override string to_yaml_string(int indent = 0) {
            return value.format("%Y-%m-%dT%H:%M:%S");
        }

        public override string to_string() {
            return to_yaml_string();
        }
    }

    // ============================================================
    // 元数据定义
    // ============================================================

    /**
     * Markdown 文档元数据
     * 
     * 存储从 YAML Front Matter 解析的元数据。
     */
    public class Metadata : Object {
        
        /** 元数据映射 */
        private YamlMap _data;
        
        /** 原始 YAML 文本（保留原始格式） */
        public string? raw_yaml { get; set; default = null; }
        
        /** 是否有效 */
        public bool is_valid { get; private set; default = true; }

        public Metadata() {
            _data = new YamlMap();
        }

        /**
         * 从 YamlMap 创建元数据
         */
        public Metadata.from_map(YamlMap map) {
            _data = map;
        }


        /**
         * 获取元数据映射
         */
        public YamlMap get_data() {
            return _data;
        }

        /**
         * 设置元数据值
         */
        public void set_value(string key, YamlValue value) {
            _data.set(key, value);
        }

        /**
         * 获取元数据值
         */
        public YamlValue? get_value(string key) {
            return _data.get_value(key);
        }

        /**
         * 检查是否包含指定键
         */
        public bool has_key(string key) {
            return _data.has_key(key);
        }

        /**
         * 获取所有键
         */
        public Gee.Set<string> get_keys() {
            return _data.keys;
        }

        // ========== 便捷访问方法 ==========

        /**
         * 获取字符串类型的元数据
         */
        public string? get_string(string key, string? default_value = null) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return default_value;
            }
            return value.get_string(default_value ?? "");
        }

        /**
         * 获取布尔类型的元数据
         */
        public bool get_boolean(string key, bool default_value = false) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return default_value;
            }
            return value.get_boolean(default_value);
        }

        /**
         * 获取整数类型的元数据
         */
        public int64 get_integer(string key, int64 default_value = 0) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return default_value;
            }
            return value.get_integer(default_value);
        }

        /**
         * 获取浮点类型的元数据
         */
        public double get_float(string key, double default_value = 0.0) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return default_value;
            }
            return value.get_float(default_value);
        }

        /**
         * 获取列表类型的元数据
         */
        public Gee.List<YamlValue>? get_list(string key) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return null;
            }
            return value.get_list();
        }

        /**
         * 获取字符串列表
         */
        public string[] get_string_list(string key) {
            var list = get_list(key);
            if (list == null) {
                return new string[0];
            }
            
            var result = new string[list.size];
            int i = 0;
            foreach (var item in list) {
                result[i++] = item.get_string();
            }
            return result;
        }

        /**
         * 获取日期类型的元数据
         */
        public DateTime? get_date(string key) {
            var value = _data.get_value(key);
            if (value == null || value.is_null) {
                return null;
            }
            return value.get_date();
        }

        /**
         * 设置字符串类型的元数据
         */
        public void set_string(string key, string value) {
            _data.set(key, new YamlString(value));
        }

        /**
         * 设置布尔类型的元数据
         */
        public void set_boolean(string key, bool value) {
            _data.set(key, new YamlBoolean(value));
        }

        /**
         * 设置整数类型的元数据
         */
        public void set_integer(string key, int64 value) {
            _data.set(key, new YamlInteger(value));
        }

        /**
         * 设置字符串列表
         */
        public void set_string_list(string key, string[] values) {
            var list = new YamlList();
            foreach (var s in values) {
                list.add(new YamlString(s));
            }
            _data.set(key, list);
        }

        /**
         * 克隆元数据
         */
        public Metadata clone() {
            var meta = new Metadata();
            meta._data = _data.clone() as YamlMap;
            meta.raw_yaml = raw_yaml;
            return meta;
        }

        /**
         * 转换为 YAML 字符串
         */
        public string to_yaml_string() {
            if (raw_yaml != null) {
                return raw_yaml;
            }
            return _data.to_yaml_string();
        }

        /**
         * 转换为 Front Matter 格式
         */
        public string to_front_matter() {
            var builder = new StringBuilder();
            builder.append("---\n");
            builder.append(to_yaml_string());
            builder.append("\n---\n");
            return builder.str;
        }
    }
}
