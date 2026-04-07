/**
 * Markdown Core Module - Core interfaces and data structures
 *
 * This module provides the in-memory representation of Markdown documents,
 * supporting CommonMark, GFM extensions, and YAML Front Matter.
 */

using Gee;

namespace Markdown {

    /**
     * Enumeration of all supported Markdown node types
     */
    public enum NodeType {
        DOCUMENT,
        HEADING,
        PARAGRAPH,
        TEXT,
        EMPHASIS,
        STRONG,
        CODE,
        CODE_BLOCK,
        LINK,
        IMAGE,
        LIST,
        LIST_ITEM,
        BLOCKQUOTE,
        THEMATIC_BREAK,
        HTML_BLOCK,
        HTML_INLINE,
        SOFT_BREAK,
        LINE_BREAK,
        // GFM Extensions
        TABLE,
        TABLE_ROW,
        TABLE_CELL,
        TASK_LIST_ITEM,
        STRIKETHROUGH,
        // Front Matter
        FRONT_MATTER,
        // Custom
        CUSTOM
    }

    /**
     * List types for ordered and unordered lists
     */
    public enum ListType {
        ORDERED,
        BULLET,
        TASK
    }

    /**
     * Base interface for all Markdown nodes
     */
    public interface Node : Object {
        /**
         * Type of this node
         */
        public abstract NodeType node_type { get; }

        /**
         * Parent node (null for root)
         */
        public abstract Node? parent { get; set; }

        /**
         * Child nodes
         */
        public abstract Gee.List<Node> children { get; }

        /**
         * Source position information
         */
        public abstract SourcePosition? position { get; set; }

        /**
         * Add a child node
         */
        public abstract void append_child(Node child);

        /**
         * Insert a child node at specified position
         */
        public abstract void insert_child(int index, Node child);

        /**
         * Remove a child node
         */
        public abstract void remove_child(Node child);

        /**
         * Get first child
         */
        public abstract Node? first_child();

        /**
         * Get last child
         */
        public abstract Node? last_child();

        /**
         * Get next sibling
         */
        public abstract Node? next_sibling();

        /**
         * Get previous sibling
         */
        public abstract Node? previous_sibling();

        /**
         * Accept a visitor
         */
        public abstract void accept(Visitor visitor);

        /**
         * Deep clone this node
         */
        public abstract Node clone();
    }

    /**
     * Source position for tracking location in original document
     */
    public class SourcePosition : Object {
        public int start_line { get; set; }
        public int start_column { get; set; }
        public int end_line { get; set; }
        public int end_column { get; set; }

        public SourcePosition(int start_line = 0, int start_column = 0,
                             int end_line = 0, int end_column = 0) {
            this.start_line = start_line;
            this.start_column = start_column;
            this.end_line = end_line;
            this.end_column = end_column;
        }

        public string to_string() {
            return "%d:%d-%d:%d".printf(start_line, start_column, end_line, end_column);
        }
    }

    /**
     * Abstract base class implementing common Node functionality
     */
    public abstract class AbstractNode : Object, Node {
        public abstract NodeType node_type { get; }

        public Node? parent { get; set; }

        private Gee.List<Node> _children = new ArrayList<Node>();

        public Gee.List<Node> children {
            get { return _children; }
        }

        public SourcePosition? position { get; set; }

        public virtual void append_child(Node child) {
            child.parent = this;
            _children.add(child);
        }

        public virtual void insert_child(int index, Node child) {
            child.parent = this;
            _children.insert(index, child);
        }

        public virtual void remove_child(Node child) {
            _children.remove(child);
            child.parent = null;
        }

        public Node? first_child() {
            return _children.size > 0 ? _children[0] : null;
        }

        public Node? last_child() {
            return _children.size > 0 ? _children[_children.size - 1] : null;
        }

        public Node? next_sibling() {
            if (parent == null) return null;
            var siblings = parent.children;
            int idx = siblings.index_of(this);
            return idx >= 0 && idx < siblings.size - 1 ? siblings[idx + 1] : null;
        }

        public Node? previous_sibling() {
            if (parent == null) return null;
            var siblings = parent.children;
            int idx = siblings.index_of(this);
            return idx > 0 ? siblings[idx - 1] : null;
        }

        public abstract void accept(Visitor visitor);

        public abstract Node clone();
    }

    /**
     * Document node - root of the Markdown tree
     */
    public class Document : AbstractNode {
        private HashMap<string, string> _front_matter = new HashMap<string, string>();

        public override NodeType node_type { get { return NodeType.DOCUMENT; } }

        public HashMap<string, string> front_matter {
            get { return _front_matter; }
        }

        public Document() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_document(this);
        }

        public override Node clone() {
            var doc = new Document();
            foreach (var entry in _front_matter.entries) {
                doc._front_matter[entry.key] = entry.value;
            }
            foreach (var child in children) {
                doc.append_child(child.clone());
            }
            return doc;
        }
    }

    /**
     * Heading node
     */
    public class Heading : AbstractNode {
        public int level { get; set; }

        public override NodeType node_type { get { return NodeType.HEADING; } }

        public Heading(int level = 1) {
            base();
            this.level = level;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_heading(this);
        }

        public override Node clone() {
            var h = new Heading(level);
            h.position = position;
            foreach (var child in children) {
                h.append_child(child.clone());
            }
            return h;
        }
    }

    /**
     * Paragraph node
     */
    public class Paragraph : AbstractNode {
        public override NodeType node_type { get { return NodeType.PARAGRAPH; } }

        public Paragraph() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_paragraph(this);
        }

        public override Node clone() {
            var p = new Paragraph();
            p.position = position;
            foreach (var child in children) {
                p.append_child(child.clone());
            }
            return p;
        }
    }

    /**
     * Text node - leaf node containing text content
     */
    public class Text : AbstractNode {
        public string content { get; set; }

        public override NodeType node_type { get { return NodeType.TEXT; } }

        public Text(string content = "") {
            base();
            this.content = content;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_text(this);
        }

        public override Node clone() {
            var t = new Text(content);
            t.position = position;
            return t;
        }
    }

    /**
     * Emphasis (italic) node
     */
    public class Emphasis : AbstractNode {
        public override NodeType node_type { get { return NodeType.EMPHASIS; } }

        public Emphasis() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_emphasis(this);
        }

        public override Node clone() {
            var e = new Emphasis();
            e.position = position;
            foreach (var child in children) {
                e.append_child(child.clone());
            }
            return e;
        }
    }

    /**
     * Strong (bold) node
     */
    public class Strong : AbstractNode {
        public override NodeType node_type { get { return NodeType.STRONG; } }

        public Strong() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_strong(this);
        }

        public override Node clone() {
            var s = new Strong();
            s.position = position;
            foreach (var child in children) {
                s.append_child(child.clone());
            }
            return s;
        }
    }

    /**
     * Inline code node
     */
    public class Code : AbstractNode {
        public string content { get; set; }

        public override NodeType node_type { get { return NodeType.CODE; } }

        public Code(string content = "") {
            base();
            this.content = content;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_code(this);
        }

        public override Node clone() {
            var c = new Code(content);
            c.position = position;
            return c;
        }
    }

    /**
     * Code block (fenced or indented)
     */
    public class CodeBlock : AbstractNode {
        public string? language { get; set; }
        public bool is_fenced { get; set; }

        public override NodeType node_type { get { return NodeType.CODE_BLOCK; } }

        public CodeBlock(string? language = null, bool is_fenced = true) {
            base();
            this.language = language;
            this.is_fenced = is_fenced;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_code_block(this);
        }

        public override Node clone() {
            var cb = new CodeBlock(language, is_fenced);
            cb.position = position;
            foreach (var child in children) {
                cb.append_child(child.clone());
            }
            return cb;
        }
    }

    /**
     * Link node
     */
    public class Link : AbstractNode {
        public string url { get; set; }
        public string? title { get; set; }

        public override NodeType node_type { get { return NodeType.LINK; } }

        public Link(string url = "", string? title = null) {
            base();
            this.url = url;
            this.title = title;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_link(this);
        }

        public override Node clone() {
            var l = new Link(url, title);
            l.position = position;
            foreach (var child in children) {
                l.append_child(child.clone());
            }
            return l;
        }
    }

    /**
     * Image node
     */
    public class Image : AbstractNode {
        public string url { get; set; }
        public string? title { get; set; }
        public string? alt_text { get; set; }

        public override NodeType node_type { get { return NodeType.IMAGE; } }

        public Image(string url = "", string? title = null, string? alt_text = null) {
            base();
            this.url = url;
            this.title = title;
            this.alt_text = alt_text;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_image(this);
        }

        public override Node clone() {
            var i = new Image(url, title, alt_text);
            i.position = position;
            foreach (var child in children) {
                i.append_child(child.clone());
            }
            return i;
        }
    }

    /**
     * List node
     */
    public class List : AbstractNode {
        public ListType list_type { get; set; }
        public int start_number { get; set; }  // For ordered lists
        public bool tight { get; set; }  // Tight or loose list

        public override NodeType node_type { get { return NodeType.LIST; } }

        public List(ListType list_type = ListType.BULLET, int start_number = 1, bool tight = true) {
            base();
            this.list_type = list_type;
            this.start_number = start_number;
            this.tight = tight;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_list(this);
        }

        public override Node clone() {
            var lst = new List(list_type, start_number, tight);
            lst.position = position;
            foreach (var child in children) {
                lst.append_child(child.clone());
            }
            return lst;
        }
    }

    /**
     * List item node
     */
    public class ListItem : AbstractNode {
        public int number { get; set; }  // For ordered lists

        public override NodeType node_type { get { return NodeType.LIST_ITEM; } }

        public ListItem(int number = 0) {
            base();
            this.number = number;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_list_item(this);
        }

        public override Node clone() {
            var li = new ListItem(number);
            li.position = position;
            foreach (var child in children) {
                li.append_child(child.clone());
            }
            return li;
        }
    }

    /**
     * Task list item (GFM extension)
     */
    public class TaskListItem : ListItem {
        public bool is_checked { get; set; }

        public override NodeType node_type { get { return NodeType.TASK_LIST_ITEM; } }

        public TaskListItem(bool is_checked = false, int number = 0) {
            base(number);
            this.is_checked = is_checked;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_task_list_item(this);
        }

        public override Node clone() {
            var tli = new TaskListItem(is_checked, number);
            tli.position = position;
            foreach (var child in children) {
                tli.append_child(child.clone());
            }
            return tli;
        }
    }

    /**
     * Blockquote node
     */
    public class Blockquote : AbstractNode {
        public override NodeType node_type { get { return NodeType.BLOCKQUOTE; } }

        public Blockquote() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_blockquote(this);
        }

        public override Node clone() {
            var b = new Blockquote();
            b.position = position;
            foreach (var child in children) {
                b.append_child(child.clone());
            }
            return b;
        }
    }

    /**
     * Thematic break (horizontal rule)
     */
    public class ThematicBreak : AbstractNode {
        public override NodeType node_type { get { return NodeType.THEMATIC_BREAK; } }

        public ThematicBreak() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_thematic_break(this);
        }

        public override Node clone() {
            var tb = new ThematicBreak();
            tb.position = position;
            return tb;
        }
    }

    /**
     * Strikethrough (GFM extension)
     */
    public class Strikethrough : AbstractNode {
        public override NodeType node_type { get { return NodeType.STRIKETHROUGH; } }

        public Strikethrough() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_strikethrough(this);
        }

        public override Node clone() {
            var s = new Strikethrough();
            s.position = position;
            foreach (var child in children) {
                s.append_child(child.clone());
            }
            return s;
        }
    }

    /**
     * Table (GFM extension)
     */
    public class Table : AbstractNode {
        public bool has_header { get; set; }

        public override NodeType node_type { get { return NodeType.TABLE; } }

        public Table(bool has_header = true) {
            base();
            this.has_header = has_header;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_table(this);
        }

        public override Node clone() {
            var t = new Table(has_header);
            t.position = position;
            foreach (var child in children) {
                t.append_child(child.clone());
            }
            return t;
        }
    }

    /**
     * Table row (GFM extension)
     */
    public class TableRow : AbstractNode {
        public bool is_header { get; set; }

        public override NodeType node_type { get { return NodeType.TABLE_ROW; } }

        public TableRow(bool is_header = false) {
            base();
            this.is_header = is_header;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_table_row(this);
        }

        public override Node clone() {
            var tr = new TableRow(is_header);
            tr.position = position;
            foreach (var child in children) {
                tr.append_child(child.clone());
            }
            return tr;
        }
    }

    /**
     * Table cell (GFM extension)
     */
    public class TableCell : AbstractNode {
        public enum Alignment {
            DEFAULT,
            LEFT,
            CENTER,
            RIGHT
        }

        public Alignment alignment { get; set; }

        public override NodeType node_type { get { return NodeType.TABLE_CELL; } }

        public TableCell(Alignment alignment = Alignment.DEFAULT) {
            base();
            this.alignment = alignment;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_table_cell(this);
        }

        public override Node clone() {
            var tc = new TableCell(alignment);
            tc.position = position;
            foreach (var child in children) {
                tc.append_child(child.clone());
            }
            return tc;
        }
    }

    /**
     * Hard line break
     */
    public class LineBreak : AbstractNode {
        public override NodeType node_type { get { return NodeType.LINE_BREAK; } }

        public LineBreak() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_line_break(this);
        }

        public override Node clone() {
            var lb = new LineBreak();
            lb.position = position;
            return lb;
        }
    }

    /**
     * Soft break (between paragraphs)
     */
    public class SoftBreak : AbstractNode {
        public override NodeType node_type { get { return NodeType.SOFT_BREAK; } }

        public SoftBreak() {
            base();
        }

        public override void accept(Visitor visitor) {
            visitor.visit_soft_break(this);
        }

        public override Node clone() {
            var sb = new SoftBreak();
            sb.position = position;
            return sb;
        }
    }

    /**
     * HTML block
     */
    public class HtmlBlock : AbstractNode {
        public string content { get; set; }

        public override NodeType node_type { get { return NodeType.HTML_BLOCK; } }

        public HtmlBlock(string content = "") {
            base();
            this.content = content;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_html_block(this);
        }

        public override Node clone() {
            var hb = new HtmlBlock(content);
            hb.position = position;
            return hb;
        }
    }

    /**
     * Inline HTML
     */
    public class HtmlInline : AbstractNode {
        public string content { get; set; }

        public override NodeType node_type { get { return NodeType.HTML_INLINE; } }

        public HtmlInline(string content = "") {
            base();
            this.content = content;
        }

        public override void accept(Visitor visitor) {
            visitor.visit_html_inline(this);
        }

        public override Node clone() {
            var hi = new HtmlInline(content);
            hi.position = position;
            return hi;
        }
    }

    /**
     * Visitor pattern for traversing the node tree
     */
    public abstract class Visitor : Object {
        public virtual void visit_document(Document node) {
            visit_children(node);
        }

        public virtual void visit_heading(Heading node) {
            visit_children(node);
        }

        public virtual void visit_paragraph(Paragraph node) {
            visit_children(node);
        }

        public virtual void visit_text(Text node) { }

        public virtual void visit_emphasis(Emphasis node) {
            visit_children(node);
        }

        public virtual void visit_strong(Strong node) {
            visit_children(node);
        }

        public virtual void visit_code(Code node) { }

        public virtual void visit_code_block(CodeBlock node) {
            visit_children(node);
        }

        public virtual void visit_link(Link node) {
            visit_children(node);
        }

        public virtual void visit_image(Image node) {
            visit_children(node);
        }

        public virtual void visit_list(List node) {
            visit_children(node);
        }

        public virtual void visit_list_item(ListItem node) {
            visit_children(node);
        }

        public virtual void visit_task_list_item(TaskListItem node) {
            visit_children(node);
        }

        public virtual void visit_blockquote(Blockquote node) {
            visit_children(node);
        }

        public virtual void visit_thematic_break(ThematicBreak node) { }

        public virtual void visit_strikethrough(Strikethrough node) {
            visit_children(node);
        }

        public virtual void visit_table(Table node) {
            visit_children(node);
        }

        public virtual void visit_table_row(TableRow node) {
            visit_children(node);
        }

        public virtual void visit_table_cell(TableCell node) {
            visit_children(node);
        }

        public virtual void visit_line_break(LineBreak node) { }

        public virtual void visit_soft_break(SoftBreak node) { }

        public virtual void visit_html_block(HtmlBlock node) { }

        public virtual void visit_html_inline(HtmlInline node) { }

        protected void visit_children(Node node) {
            foreach (var child in node.children) {
                child.accept(this);
            }
        }
    }
}
