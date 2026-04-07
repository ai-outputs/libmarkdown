# Markdown Vala Module

A comprehensive Markdown processing library written in Vala, supporting CommonMark, GFM extensions, and YAML Front Matter.

## Features

- **CommonMark Spec Support**: Full implementation of CommonMark specification
- **GFM Extensions**: GitHub Flavored Markdown extensions including:
  - Tables
  - Task lists
  - Strikethrough
  - Autolinks
- **YAML Front Matter**: Parse and preserve front matter metadata
- **Multiple Output Formats**:
  - Markdown serialization
  - HTML rendering
  - GTK CSS styling
- **In-Memory Tree Representation**: Full AST representation for manipulation

## Module Structure

```
src/
├── markdown.vala           # Core interfaces and data structures
├── markdown-parser.vala    # Markdown parser
├── markdown-writer.vala    # Markdown writer
├── html-renderer.vala      # HTML renderer
└── gtk-css-renderer.vala   # GTK CSS renderer

examples/
├── markdown-editor.vala    # GTK+ Markdown editor example
└── markdown-cli.vala       # Command-line processor example
```

## Usage Examples

### Basic Parsing and Rendering

```vala
using Markdown;

// Parse Markdown
var parser = new Parser();
var document = parser.parse(markdown_text);

// Render to HTML
var html_renderer = new HtmlRenderer();
var html = html_renderer.render(document);

// Render to GTK format
var gtk_renderer = new PangoRenderer();
var gtk_markup = gtk_renderer.render(document);
var gtk_css = gtk_renderer.generate_css();
```

### Working with Front Matter

```vala
var parser = new Parser();
var doc = parser.parse("""
---
title: My Document
author: John Doe
date: 2026-04-07
---

# Content starts here
""");

// Access front matter
var title = doc.front_matter["title"];
var author = doc.front_matter["author"];
```

### Manually Creating Documents

```vala
var doc = new Document();

// Add front matter
doc.front_matter["title"] = "My Title";

// Create heading
var heading = new Heading(1);
heading.append_child(new Text("Introduction"));
doc.append_child(heading);

// Create paragraph with formatting
var para = new Paragraph();
para.append_child(new Text("This is "));
var strong = new Strong();
strong.append_child(new Text("bold"));
para.append_child(strong);
para.append_child(new Text(" text."));
doc.append_child(para);

// Create list
var list = new List(ListType.BULLET);
var item1 = new ListItem();
item1.append_child(new Text("First item"));
list.append_child(item1);
var item2 = new ListItem();
item2.append_child(new Text("Second item"));
list.append_child(item2);
doc.append_child(list);
```

### Customizing Output

```vala
// HTML with source positions
var html_options = new HtmlOptions();
html_options.emit_html_wrapper = true;
html_options.source_pos = true;
html_options.css_class = "markdown-content";
var html_renderer = new HtmlRenderer(html_options);

// GTK with dark theme
var gtk_options = new PangoOptions();
gtk_options.use_dark_theme = true;
gtk_options.font_family = "Cantarell";
gtk_options.base_font_size = 12;
var gtk_renderer = new PangoRenderer(gtk_options);
```

### Using in GTK Applications

```vala
using Gtk;
using Markdown;

// Create preview widget
var preview = new GtkMarkdownPreview();
var widget = preview.create_preview_widget(document);

// Or create a label
var label = preview.create_label(document);

// Apply to existing TextView
var text_view = new TextView();
preview.apply_to_text_buffer(document, text_view.get_buffer());
```

## Building

### Meson Build

```bash
meson setup build --prefix=/usr
meson compile -C build
meson install -C build
```

### Simple Compilation

```bash
# Build the library
valac --library=markdown \
      --header=markdown.h \
      src/markdown.vala \
      src/markdown-parser.vala \
      src/markdown-writer.vala \
      src/html-renderer.vala \
      src/gtk-css-renderer.vala \
      --pkg=gio-2.0 --pkg=gee-0.8 --pkg=gtk+-3.0

# Build examples
valac examples/markdown-cli.vala src/*.vala --pkg=gio-2.0 --pkg=gee-0.8 -o markdown-cli
valac examples/markdown-editor.vala src/*.vala --pkg=gio-2.0 --pkg=gee-0.8 --pkg=gtk+-3.0 -o markdown-editor
```

## API Reference

### Core Interfaces

#### `Node`
Base interface for all Markdown nodes. Provides tree traversal methods.

#### `Visitor`
Abstract visitor class for tree traversal using visitor pattern.

### Node Types

| Node Type | Description |
|-----------|-------------|
| `Document` | Root document node |
| `Heading` | Heading (h1-h6) |
| `Paragraph` | Paragraph block |
| `Text` | Text content |
| `Emphasis` | Italic text |
| `Strong` | Bold text |
| `Code` | Inline code |
| `CodeBlock` | Fenced/indented code |
| `Link` | Hyperlink |
| `Image` | Image |
| `List` | Ordered/unordered list |
| `ListItem` | List item |
| `TaskListItem` | Task list item (GFM) |
| `Blockquote` | Blockquote |
| `ThematicBreak` | Horizontal rule |
| `Strikethrough` | Strikethrough (GFM) |
| `Table` | Table (GFM) |
| `TableRow` | Table row |
| `TableCell` | Table cell |

### Parser API

```vala
public class Parser {
    public Document parse(string markdown);
    public Gee.List<ParseError> get_errors();
}
```

### Writer API

```vala
public class Writer : Visitor {
    public string write(Document document);
    public string write_node(Node node);
}
```

### HTML Renderer API

```vala
public class HtmlRenderer : Visitor {
    public string render(Document document);
    public string render_node(Node node);
}
```

### GTK CSS Renderer API

```vala
public class PangoRenderer : Visitor {
    public string render(Document document);
    public string generate_css();
}
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
