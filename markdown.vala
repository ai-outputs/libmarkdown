/**
 * Markdown Module - 模块入口
 * 
 * 这是 Markdown 读写模块的主入口文件。
 * 提供了统一的命名空间和便捷的访问方式。
 * 
 * ## 功能概述
 * 
 * 本模块为 Vala 语言提供了完整的 Markdown 处理能力：
 * 
 * - **解析 (Reading)**: 将 Markdown 文本转换为内存中的节点树
 * - **生成 (Writing)**: 将节点树序列化为 Markdown 文本
 * - **操作 (Manipulation)**: 提供完整的节点树操作 API
 * 
 * ## 使用示例
 * 
 * ```vala
 * using Markdown;
 * 
 * // 解析 Markdown 文本
 * var reader = new MarkdownReader();
 * var doc = reader.parse("# Hello\n\nWorld!");
 * 
 * // 遍历节点
 * doc.traverse((node, depth) => {
 *     print("%s\n", node.to_description());
 *     return true;
 * });
 * 
 * // 生成 Markdown 文本
 * var writer = new MarkdownWriter();
 * var output = writer.render(doc);
 * ```
 * 
 * ## 架构设计
 * 
 * 模块采用分层架构：
 * 
 * 1. **类型层 (markdown-types.vala)**
 *    - NodeType 枚举：定义所有节点类型
 *    - NodeVisitor 接口：访问者模式支持
 *    - ParseOptions/RenderOptions：配置选项
 *    - SourcePosition：源码位置追踪
 * 
 * 2. **节点层 (markdown-nodes.vala)**
 *    - Node 基类：所有节点的抽象基类
 *    - 块级节点：Document, Heading, Paragraph, List, CodeBlock 等
 *    - 行内节点：Text, Emphasis, Strong, Link, Image 等
 *    - NodeFactory：便捷的节点创建工厂
 * 
 * 3. **解析层 (markdown-reader.vala)**
 *    - MarkdownReader：Markdown 解析器
 *    - 支持块级和行内元素解析
 *    - 支持 GFM 扩展
 * 
 * 4. **生成层 (markdown-writer.vala)**
 *    - MarkdownWriter：Markdown 生成器
 *    - 支持自定义输出格式
 *    - 辅助工具：NodePrinter, NodeCounter
 * 
 * @author Agent Skill Support
 * @version 1.0.0
 * @see NodeType
 * @see Node
 * @see MarkdownReader
 * @see MarkdownWriter
 */

namespace Markdown {

    /**
     * 模块版本信息
     */
    public const string VERSION = "1.0.0";
    
    /**
     * 模块名称
     */
    public const string MODULE_NAME = "markdown";

    /**
     * 快捷解析函数
     * 
     * 使用默认选项解析 Markdown 文本。
     * 
     * @param text Markdown 文本
     * @return 解析后的文档节点
     * @throws MarkdownError 如果解析失败
     */
    public Document parse(string text) throws MarkdownError {
        var reader = new MarkdownReader();
        return reader.parse(text);
    }

    /**
     * 快捷渲染函数
     * 
     * 使用默认选项将文档渲染为 Markdown 文本。
     * 
     * @param document 文档节点
     * @return 生成的 Markdown 文本
     */
    public string render(Document document) {
        var writer = new MarkdownWriter();
        return writer.render(document);
    }

    /**
     * 快捷解析并重新渲染
     * 
     * 解析 Markdown 文本并重新渲染，可用于规范化格式。
     * 
     * @param text 输入的 Markdown 文本
     * @return 规范化后的 Markdown 文本
     * @throws MarkdownError 如果解析失败
     */
    public string normalize(string text) throws MarkdownError {
        var doc = parse(text);
        return render(doc);
    }

    /**
     * 从文件读取并解析
     * 
     * @param path 文件路径
     * @return 解析后的文档节点
     * @throws MarkdownError 如果读取或解析失败
     */
    public Document read_file(string path) throws MarkdownError {
        var reader = new MarkdownReader();
        return reader.parse_path(path);
    }

    /**
     * 将文档写入文件
     * 
     * @param document 文档节点
     * @param path 目标文件路径
     * @throws MarkdownError 如果写入失败
     */
    public void write_file(Document document, string path) throws MarkdownError {
        var writer = new MarkdownWriter();
        writer.render_to_path(document, path);
    }
}

// ============================================================
// 初始化代码
// ============================================================

/**
 * 模块初始化
 * 
 * 当模块被加载时执行。
 */
public void markdown_init() {
    // 初始化日志域
    GLib.Log.set_writer_func(GLib.Log.writer_standard_streams);
    
    // 可在此添加其他初始化逻辑
    GLib.debug("Markdown module v%s initialized", Markdown.VERSION);
}
