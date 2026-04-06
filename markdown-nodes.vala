/**
 * Markdown Nodes - 节点实现
 * 
 * 本模块实现了 Markdown 文档对象模型（DOM）的核心节点类。
 * 提供了完整的节点树结构，支持块级和行内元素。
 * 
 * @author GLM-5 / Taozuhong
 * @version 1.0.0
 */

namespace Markdown {

    /**
     * 抽象节点基类
     * 
     * 所有 Markdown 节点的基类，定义了通用的属性和方法。
     * 支持树形结构、访问者模式和源码位置追踪。
     */
    public abstract class Node : Object {
        
        /** 节点类型 */
        public abstract NodeType node_type { get; }
        
        /** 父节点引用 */
        public weak Node? parent { get; internal set; default = null; }
        
        /** 子节点列表 */
        protected Gee.ArrayList<Node> _children;
        
        /** 源码位置信息 */
        public SourcePosition source_position { get; set; default = SourcePosition.invalid(); }
        
        /** 用户数据（可用于附加自定义信息） */
        public void* user_data { get; set; }

        /**
         * 构造函数
         */
        protected Node() {
            _children = new Gee.ArrayList<Node>();
        }

        /**
         * 获取子节点数量
         * 
         * @return 子节点数量
         */
        public int child_count {
            get { return _children.size; }
        }

        /**
         * 获取子节点列表（只读）
         * 
         * @return 子节点列表的只读视图
         */
        public Gee.List<Node> children {
            owned get { return _children.read_only_view; }
        }

        /**
         * 获取第一个子节点
         * 
         * @return 第一个子节点，如果没有返回 null
         */
        public Node? first_child {
            owned get { return _children.is_empty ? null : _children.first(); }
        }

        /**
         * 获取最后一个子节点
         * 
         * @return 最后一个子节点，如果没有返回 null
         */
        public Node? last_child {
            owned get { return _children.is_empty ? null : _children.last(); }
        }

        /**
         * 获取下一个兄弟节点
         * 
         * @return 下一个兄弟节点，如果没有返回 null
         */
        public Node? next_sibling {
            owned get {
                if (parent == null) return null;
                var siblings = parent._children;
                int index = siblings.index_of(this);
                if (index < 0 || index >= siblings.size - 1) return null;
                return siblings[index + 1];
            }
        }

        /**
         * 获取上一个兄弟节点
         * 
         * @return 上一个兄弟节点，如果没有返回 null
         */
        public Node? previous_sibling {
            owned get {
                if (parent == null) return null;
                var siblings = parent._children;
                int index = siblings.index_of(this);
                if (index <= 0) return null;
                return siblings[index - 1];
            }
        }

        /**
         * 追加子节点
         * 
         * 将节点添加到子节点列表末尾。
         * 如果节点已有父节点，会先从原父节点移除。
         * 
         * @param child 要追加的子节点
         * @throws MarkdownError 如果参数无效
         */
        public virtual void append_child(Node child) throws MarkdownError {
            return_if_fail(child != null);
            
            // 从原父节点移除
            if (child.parent != null) {
                child.parent.remove_child(child);
            }
            
            child.parent = this;
            _children.add(child);
            on_child_added(child);
        }

        /**
         * 插入子节点
         * 
         * 将节点插入到指定位置。
         * 
         * @param index 插入位置
         * @param child 要插入的子节点
         * @throws MarkdownError 如果参数无效
         */
        public virtual void insert_child(int index, Node child) throws MarkdownError {
            return_if_fail(child != null);
            return_if_fail(index >= 0 && index <= _children.size);
            
            // 从原父节点移除
            if (child.parent != null) {
                child.parent.remove_child(child);
            }
            
            child.parent = this;
            _children.insert(index, child);
            on_child_added(child);
        }

        /**
         * 移除子节点
         * 
         * 从子节点列表中移除指定节点。
         * 
         * @param child 要移除的子节点
         * @throws MarkdownError 如果节点不是此节点的子节点
         */
        public virtual void remove_child(Node child) throws MarkdownError {
            return_if_fail(child != null);
            
            if (!_children.remove(child)) {
                throw new MarkdownError.INVALID_NODE_OPERATION(
                    "Node is not a child of this node"
                );
            }
            
            child.parent = null;
            on_child_removed(child);
        }

        /**
         * 替换子节点
         * 
         * 用新节点替换指定的子节点。
         * 
         * @param old_child 要被替换的节点
         * @param new_child 新节点
         * @throws MarkdownError 如果操作无效
         */
        public virtual void replace_child(Node old_child, Node new_child) throws MarkdownError {
            return_if_fail(old_child != null);
            return_if_fail(new_child != null);
            
            int index = _children.index_of(old_child);
            if (index < 0) {
                throw new MarkdownError.INVALID_NODE_OPERATION(
                    "Node is not a child of this node"
                );
            }
            
            remove_child(old_child);
            insert_child(index, new_child);
        }

        /**
         * 清空所有子节点
         */
        public virtual void clear_children() {
            foreach (var child in _children) {
                child.parent = null;
                on_child_removed(child);
            }
            _children.clear();
        }

        /**
         * 子节点添加时的回调
         * 
         * 子类可重写此方法以响应子节点添加事件。
         * 
         * @param child 添加的子节点
         */
        protected virtual void on_child_added(Node child) {
            // 默认无操作，子类可重写
        }

        /**
         * 子节点移除时的回调
         * 
         * 子类可重写此方法以响应子节点移除事件。
         * 
         * @param child 移除的子节点
         */
        protected virtual void on_child_removed(Node child) {
            // 默认无操作，子类可重写
        }

        /**
         * 接受访问者访问
         * 
         * 实现访问者模式的标准方法。
         * 
         * @param visitor 访问者实例
         */
        public virtual void accept(NodeVisitor visitor) {
            if (visitor.enter_node(this)) {
                foreach (var child in _children) {
                    child.accept(visitor);
                }
            }
            visitor.leave_node(this);
        }

        /**
         * 查找指定类型的子节点
         * 
         * @param type 要查找的节点类型
         * @return 匹配的子节点列表
         */
        public Gee.List<Node> find_children_by_type(NodeType type) {
            var result = new Gee.ArrayList<Node>();
            foreach (var child in _children) {
                if (child.node_type == type) {
                    result.add(child);
                }
            }
            return result;
        }

        /**
         * 遍历所有后代节点
         * 
         * 深度优先遍历所有后代节点。
         * 
         * @param callback 对每个节点调用的回调函数
         */
        public void traverse(NodeTraverseFunc callback) {
            _traverse_internal(callback, 0);
        }

        private bool _traverse_internal(NodeTraverseFunc callback, int depth) {
            if (callback(this, depth)) {
                foreach (var child in _children) {
                    if (!child._traverse_internal(callback, depth + 1)) {
                        return false;
                    }
                }
            }
            return true;
        }

        /**
         * 克隆节点
         * 
         * 创建节点的深拷贝。
         * 
         * @return 克隆的节点
         */
        public abstract Node clone();

        /**
         * 获取纯文本内容
         * 
         * 递归获取节点及其所有后代的文本内容。
         * 
         * @return 纯文本字符串
         */
        public virtual string get_text_content() {
            var builder = new StringBuilder();
            foreach (var child in _children) {
                builder.append(child.get_text_content());
            }
            return builder.str;
        }

        /**
         * 获取节点描述字符串
         * 
         * @return 节点的可读描述
         */
        public virtual string to_description() {
            return node_type.to_readable_string();
        }
    }

    /** 节点遍历回调函数类型 */
    public delegate bool NodeTraverseFunc(Node node, int depth);

    // ============================================================
    // 具体节点类实现
    // ============================================================

    /**
     * 文档节点
     * 
     * Markdown 文档的根节点，包含所有顶层块级元素和元数据。
     */
    public class Document : Node {
        
        /** 文档链接定义映射 */
        private Gee.HashMap<string, LinkDefinition> _link_definitions;
        
        /** 文档元数据（YAML Front Matter） */
        private Metadata? _metadata;

        public override NodeType node_type {
            get { return NodeType.DOCUMENT; }
        }

        public Document() {
            base();
            _link_definitions = new Gee.HashMap<string, LinkDefinition>();
        }

        /**
         * 文档元数据
         * 
         * 存储从 YAML Front Matter 解析的元数据。
         */
        public Metadata? metadata {
            get { return _metadata; }
            set { _metadata = value; }
        }

        /**
         * 检查文档是否有元数据
         * 
         * @return 如果文档包含元数据返回 true
         */
        public bool has_metadata {
            get { return _metadata != null; }
        }

        /**
         * 获取或创建元数据对象
         * 
         * 如果元数据不存在，会创建一个新的空元数据对象。
         * 
         * @return 元数据对象
         */
        public Metadata get_or_create_metadata() {
            if (_metadata == null) {
                _metadata = new Metadata();
            }
            return _metadata;
        }

        /**
         * 设置字符串类型的元数据
         * 
         * @param key 元数据键
         * @param value 字符串值
         */
        public void set_metadata_string(string key, string value) {
            get_or_create_metadata().set_string(key, value);
        }

        /**
         * 获取字符串类型的元数据
         * 
         * @param key 元数据键
         * @param default_value 默认值
         * @return 元数据值
         */
        public string? get_metadata_string(string key, string? default_value = null) {
            if (_metadata == null) return default_value;
            return _metadata.get_string(key, default_value);
        }

        /**
         * 获取标题（从元数据或第一个标题节点）
         * 
         * @return 文档标题
         */
        public string? get_title() {
            // 优先从元数据获取
            if (_metadata != null && _metadata.has_key("title")) {
                return _metadata.get_string("title");
            }
            
            // 从第一个标题节点获取
            foreach (var child in _children) {
                if (child is Heading) {
                    return child.get_text_content();
                }
            }
            
            return null;
        }

        /**
         * 注册链接定义
         * 
         * @param definition 链接定义
         */
        public void add_link_definition(LinkDefinition definition) {
            _link_definitions[definition.label.down()] = definition;
        }

        /**
         * 获取链接定义
         * 
         * @param label 链接标签
         * @return 链接定义，如果不存在返回 null
         */
        public LinkDefinition? get_link_definition(string label) {
            return _link_definitions[label.down()];
        }

        /**
         * 获取所有链接定义
         * 
         * @return 链接定义集合
         */
        public Gee.Collection<LinkDefinition> get_all_link_definitions() {
            return _link_definitions.values;
        }

        public override Node clone() {
            var doc = new Document();
            doc.source_position = source_position;
            
            // 克隆元数据
            if (_metadata != null) {
                doc._metadata = _metadata.clone();
            }
            
            foreach (var child in _children) {
                try {
                    doc.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            foreach (var def in _link_definitions.values) {
                doc.add_link_definition(new LinkDefinition(
                    def.label, def.destination, def.title
                ));
            }
            
            return doc;
        }

        public override string to_description() {
            if (_metadata != null) {
                return "Document (with metadata)";
            }
            return "Document";
        }
    }

    /**
     * 标题节点
     * 
     * 表示 Markdown 标题，支持 H1-H6 级别。
     */
    public class Heading : Node {
        
        /** 标题级别 */
        public HeadingLevel level { get; set; }

        public override NodeType node_type {
            get { return NodeType.HEADING; }
        }

        public Heading(HeadingLevel level = HeadingLevel.H1) {
            base();
            this.level = level;
        }

        public override Node clone() {
            var heading = new Heading(level);
            heading.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    heading.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return heading;
        }

        public override string to_description() {
            return "Heading (H%d)".printf((int)level);
        }
    }

    /**
     * 段落节点
     * 
     * 表示文本段落，是最常见的块级元素。
     */
    public class Paragraph : Node {
        
        public override NodeType node_type {
            get { return NodeType.PARAGRAPH; }
        }

        public override Node clone() {
            var para = new Paragraph();
            para.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    para.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return para;
        }
    }

    /**
     * 列表节点基类
     * 
     * 无序列表和有序列表的公共基类。
     */
    public abstract class List : Node {
        
        /** 列表是否紧凑（列表项之间无空行） */
        public bool is_tight { get; set; default = true; }
    }

    /**
     * 无序列表节点
     * 
     * 使用 -, *, + 等符号标记的列表。
     */
    public class BulletList : List {
        
        /** 列表标记字符 */
        public char bullet_char { get; set; default = '-'; }

        public override NodeType node_type {
            get { return NodeType.BULLET_LIST; }
        }

        public override Node clone() {
            var list = new BulletList();
            list.bullet_char = bullet_char;
            list.is_tight = is_tight;
            list.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    list.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return list;
        }

        public override string to_description() {
            return "BulletList ('%c')".printf(bullet_char);
        }
    }

    /**
     * 有序列表节点
     * 
     * 使用数字编号的列表。
     */
    public class OrderedList : List {
        
        /** 起始编号 */
        public int start_number { get; set; default = 1; }
        
        /** 分隔符字符 (. 或 )) */
        public char delimiter { get; set; default = '.'; }

        public override NodeType node_type {
            get { return NodeType.ORDERED_LIST; }
        }

        public override Node clone() {
            var list = new OrderedList();
            list.start_number = start_number;
            list.delimiter = delimiter;
            list.is_tight = is_tight;
            list.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    list.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return list;
        }

        public override string to_description() {
            return "OrderedList (start=%d)".printf(start_number);
        }
    }

    /**
     * 列表项节点
     * 
     * 无序列表和有序列表的子项。
     */
    public class ListItem : Node {
        
        /** 任务列表复选框状态（null 表示非任务列表项） */
        public bool? checked { get; set; default = null; }

        public override NodeType node_type {
            get { return NodeType.LIST_ITEM; }
        }

        /**
         * 判断是否为任务列表项
         * 
         * @return 如果是任务列表项返回 true
         */
        public bool is_task_item {
            get { return checked != null; }
        }

        public override Node clone() {
            var item = new ListItem();
            item.checked = checked;
            item.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    item.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return item;
        }

        public override string to_description() {
            if (checked == null) {
                return "ListItem";
            }
            return "ListItem (task, %s)".printf(checked ? "checked" : "unchecked");
        }
    }

    /**
     * 代码块节点
     * 
     * 围栏代码块或缩进代码块。
     */
    public class CodeBlock : Node {
        
        /** 代码语言标识 */
        public string? language { get; set; default = null; }
        
        /** 代码内容 */
        public string code { get; set; default = ""; }
        
        /** 是否为围栏代码块 */
        public bool is_fenced { get; set; default = true; }
        
        /** 围栏字符（` 或 ~） */
        public char fence_char { get; set; default = '`'; }
        
        /** 围栏长度 */
        public int fence_length { get; set; default = 3; }

        public override NodeType node_type {
            get { return NodeType.CODE_BLOCK; }
        }

        public override Node clone() {
            var block = new CodeBlock();
            block.language = language;
            block.code = code;
            block.is_fenced = is_fenced;
            block.fence_char = fence_char;
            block.fence_length = fence_length;
            block.source_position = source_position;
            return block;
        }

        public override string get_text_content() {
            return code;
        }

        public override string to_description() {
            if (language != null) {
                return "CodeBlock (%s)".printf(language);
            }
            return "CodeBlock";
        }
    }

    /**
     * 引用块节点
     * 
     * 使用 > 标记的引用内容块。
     */
    public class BlockQuote : Node {
        
        public override NodeType node_type {
            get { return NodeType.BLOCK_QUOTE; }
        }

        public override Node clone() {
            var quote = new BlockQuote();
            quote.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    quote.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return quote;
        }
    }

    /**
     * 主题分隔线节点
     * 
     * 使用 ---, ***, ___ 等创建的水平分隔线。
     */
    public class ThematicBreak : Node {
        
        public override NodeType node_type {
            get { return NodeType.THEMATIC_BREAK; }
        }

        public override Node clone() {
            var brk = new ThematicBreak();
            brk.source_position = source_position;
            return brk;
        }
    }

    /**
     * HTML 块节点
     * 
     * 原始 HTML 块级元素。
     */
    public class HtmlBlock : Node {
        
        /** HTML 内容 */
        public string html { get; set; default = ""; }
        
        /** HTML 块类型 (1-7) */
        public int block_type { get; set; default = 1; }

        public override NodeType node_type {
            get { return NodeType.HTML_BLOCK; }
        }

        public override Node clone() {
            var block = new HtmlBlock();
            block.html = html;
            block.block_type = block_type;
            block.source_position = source_position;
            return block;
        }

        public override string get_text_content() {
            return html;
        }
    }

    // ============================================================
    // 行内节点类实现
    // ============================================================

    /**
     * 文本节点
     * 
     * 纯文本内容，是最基础的行内元素。
     */
    public class Text : Node {
        
        /** 文本内容 */
        public string text { get; set; default = ""; }

        public override NodeType node_type {
            get { return NodeType.TEXT; }
        }

        public Text(string text = "") {
            base();
            this.text = text;
        }

        public override Node clone() {
            var node = new Text(text);
            node.source_position = source_position;
            return node;
        }

        public override string get_text_content() {
            return text;
        }

        public override string to_description() {
            if (text.length > 20) {
                return "Text: \"%s...\"".printf(text.substring(0, 20));
            }
            return "Text: \"%s\"".printf(text);
        }
    }

    /**
     * 强调节点
     * 
     * 使用 * 或 _ 包裹的斜体文本。
     */
    public class Emphasis : Node {
        
        /** 是否使用 * 作为分隔符 */
        public bool use_asterisk { get; set; default = true; }

        public override NodeType node_type {
            get { return NodeType.EMPHASIS; }
        }

        public override Node clone() {
            var node = new Emphasis();
            node.use_asterisk = use_asterisk;
            node.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    node.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return node;
        }
    }

    /**
     * 加粗节点
     * 
     * 使用 ** 或 __ 包裹的粗体文本。
     */
    public class Strong : Node {
        
        /** 是否使用 ** 作为分隔符 */
        public bool use_asterisk { get; set; default = true; }

        public override NodeType node_type {
            get { return NodeType.STRONG; }
        }

        public override Node clone() {
            var node = new Strong();
            node.use_asterisk = use_asterisk;
            node.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    node.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return node;
        }
    }

    /**
     * 行内代码节点
     * 
     * 使用 ` 包裹的代码片段。
     */
    public class InlineCode : Node {
        
        /** 代码内容 */
        public string code { get; set; default = ""; }
        
        /** 反引号数量 */
        public int backtick_count { get; set; default = 1; }

        public override NodeType node_type {
            get { return NodeType.INLINE_CODE; }
        }

        public InlineCode(string code = "") {
            base();
            this.code = code;
        }

        public override Node clone() {
            var node = new InlineCode(code);
            node.backtick_count = backtick_count;
            node.source_position = source_position;
            return node;
        }

        public override string get_text_content() {
            return code;
        }

        public override string to_description() {
            return "InlineCode: `%s`".printf(code);
        }
    }

    /**
     * 链接节点
     * 
     * 超链接，支持行内链接和引用链接。
     */
    public class Link : Node {
        
        /** 链接目标 URL */
        public string destination { get; set; default = ""; }
        
        /** 链接标题（可选） */
        public string? title { get; set; default = null; }
        
        /** 引用标签（引用链接时使用） */
        public string? reference_label { get; set; default = null; }
        
        /** 是否为自动链接 */
        public bool is_autolink { get; set; default = false; }

        public override NodeType node_type {
            get { return NodeType.LINK; }
        }

        /**
         * 判断是否为引用链接
         * 
         * @return 如果是引用链接返回 true
         */
        public bool is_reference_link {
            get { return reference_label != null; }
        }

        public override Node clone() {
            var node = new Link();
            node.destination = destination;
            node.title = title;
            node.reference_label = reference_label;
            node.is_autolink = is_autolink;
            node.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    node.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return node;
        }

        public override string to_description() {
            if (is_autolink) {
                return "Link (autolink): %s".printf(destination);
            }
            if (is_reference_link) {
                return "Link (ref): [%s]".printf(reference_label);
            }
            return "Link: %s".printf(destination);
        }
    }

    /**
     * 图片节点
     * 
     * 图片引用，支持行内图片和引用图片。
     */
    public class Image : Node {
        
        /** 图片 URL */
        public string destination { get; set; default = ""; }
        
        /** 图片标题（可选） */
        public string? title { get; set; default = null; }
        
        /** 引用标签 */
        public string? reference_label { get; set; default = null; }

        public override NodeType node_type {
            get { return NodeType.IMAGE; }
        }

        public override Node clone() {
            var node = new Image();
            node.destination = destination;
            node.title = title;
            node.reference_label = reference_label;
            node.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    node.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return node;
        }

        public override string get_text_content() {
            // 图片的 alt 文本
            return base.get_text_content();
        }

        public override string to_description() {
            if (reference_label != null) {
                return "Image (ref): [%s]".printf(reference_label);
            }
            return "Image: %s".printf(destination);
        }
    }

    /**
     * 删除线节点
     * 
     * 使用 ~~ 包裹的删除文本（GFM 扩展）。
     */
    public class Strikethrough : Node {
        
        public override NodeType node_type {
            get { return NodeType.STRIKETHROUGH; }
        }

        public override Node clone() {
            var node = new Strikethrough();
            node.source_position = source_position;
            
            foreach (var child in _children) {
                try {
                    node.append_child(child.clone());
                } catch (MarkdownError e) {
                    warning("Failed to clone child: %s", e.message);
                }
            }
            
            return node;
        }
    }

    /**
     * 行内 HTML 节点
     * 
     * 行内的原始 HTML 片段。
     */
    public class HtmlInline : Node {
        
        /** HTML 内容 */
        public string html { get; set; default = ""; }

        public override NodeType node_type {
            get { return NodeType.HTML_INLINE; }
        }

        public HtmlInline(string html = "") {
            base();
            this.html = html;
        }

        public override Node clone() {
            var node = new HtmlInline(html);
            node.source_position = source_position;
            return node;
        }

        public override string get_text_content() {
            return html;
        }
    }

    /**
     * 软换行节点
     * 
     * 源码中的单个换行符，渲染时通常转换为空格。
     */
    public class Softbreak : Node {
        
        public override NodeType node_type {
            get { return NodeType.SOFTBREAK; }
        }

        public override Node clone() {
            return new Softbreak();
        }

        public override string get_text_content() {
            return " ";
        }
    }

    /**
     * 硬换行节点
     * 
     * 使用两个空格或 \ 显式标记的换行。
     */
    public class Hardbreak : Node {
        
        public override NodeType node_type {
            get { return NodeType.HARDBREAK; }
        }

        public override Node clone() {
            return new Hardbreak();
        }

        public override string get_text_content() {
            return "\n";
        }
    }

    // ============================================================
    // 节点工厂
    // ============================================================

    /**
     * 节点工厂类
     * 
     * 提供便捷的静态方法创建各类节点。
     */
    public class NodeFactory : Object {
        
        /**
         * 创建标题节点
         * 
         * @param level 标题级别
         * @param text 标题文本
         * @return 创建的标题节点
         */
        public static Heading heading(HeadingLevel level, string text) {
            var node = new Heading(level);
            try {
                node.append_child(new Text(text));
            } catch (MarkdownError e) {
                warning("Failed to add text to heading: %s", e.message);
            }
            return node;
        }

        /**
         * 创建段落节点
         * 
         * @param text 段落文本
         * @return 创建的段落节点
         */
        public static Paragraph paragraph(string? text = null) {
            var node = new Paragraph();
            if (text != null) {
                try {
                    node.append_child(new Text(text));
                } catch (MarkdownError e) {
                    warning("Failed to add text to paragraph: %s", e.message);
                }
            }
            return node;
        }

        /**
         * 创建代码块节点
         * 
         * @param code 代码内容
         * @param language 语言标识
         * @return 创建的代码块节点
         */
        public static CodeBlock code_block(string code, string? language = null) {
            var node = new CodeBlock();
            node.code = code;
            node.language = language;
            return node;
        }

        /**
         * 创建链接节点
         * 
         * @param text 链接文本
         * @param destination 目标 URL
         * @param title 可选标题
         * @return 创建的链接节点
         */
        public static Link link(string text, string destination, string? title = null) {
            var node = new Link();
            node.destination = destination;
            node.title = title;
            try {
                node.append_child(new Text(text));
            } catch (MarkdownError e) {
                warning("Failed to add text to link: %s", e.message);
            }
            return node;
        }

        /**
         * 创建图片节点
         * 
         * @param alt_text 替代文本
         * @param destination 图片 URL
         * @param title 可选标题
         * @return 创建的图片节点
         */
        public static Image image(string alt_text, string destination, string? title = null) {
            var node = new Image();
            node.destination = destination;
            node.title = title;
            try {
                node.append_child(new Text(alt_text));
            } catch (MarkdownError e) {
                warning("Failed to add alt text to image: %s", e.message);
            }
            return node;
        }

        /**
         * 创建强调节点
         * 
         * @param text 强调文本
         * @return 创建的强调节点
         */
        public static Emphasis emphasis(string text) {
            var node = new Emphasis();
            try {
                node.append_child(new Text(text));
            } catch (MarkdownError e) {
                warning("Failed to add text to emphasis: %s", e.message);
            }
            return node;
        }

        /**
         * 创建加粗节点
         * 
         * @param text 加粗文本
         * @return 创建的加粗节点
         */
        public static Strong strong(string text) {
            var node = new Strong();
            try {
                node.append_child(new Text(text));
            } catch (MarkdownError e) {
                warning("Failed to add text to strong: %s", e.message);
            }
            return node;
        }

        /**
         * 创建无序列表
         * 
         * @param items 列表项文本数组
         * @return 创建的无序列表节点
         */
        public static BulletList bullet_list(string[] items) {
            var list = new BulletList();
            foreach (var item_text in items) {
                var item = new ListItem();
                try {
                    item.append_child(new Text(item_text));
                    list.append_child(item);
                } catch (MarkdownError e) {
                    warning("Failed to add item to list: %s", e.message);
                }
            }
            return list;
        }

        /**
         * 创建有序列表
         * 
         * @param items 列表项文本数组
         * @param start 起始编号
         * @return 创建的有序列表节点
         */
        public static OrderedList ordered_list(string[] items, int start = 1) {
            var list = new OrderedList();
            list.start_number = start;
            foreach (var item_text in items) {
                var item = new ListItem();
                try {
                    item.append_child(new Text(item_text));
                    list.append_child(item);
                } catch (MarkdownError e) {
                    warning("Failed to add item to list: %s", e.message);
                }
            }
            return list;
        }
    }
}
